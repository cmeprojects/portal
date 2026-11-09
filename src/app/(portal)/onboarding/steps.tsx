// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useRef, useState, useTransition } from "react";
import { Eraser, ExternalLink, FileText, PenLine } from "lucide-react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { FILES_BUCKET } from "@/lib/compliance";
import { createClient } from "@/lib/supabase/client";
import type { FormState } from "@/lib/form";
import { toast } from "@/components/toast";
import { acknowledgePolicy, completeTraining, openItem, signAgreement, submitDocument } from "./actions";

// cmeprojects: the steps on My onboarding. Each one saves on its own, so
// people can do a bit, leave, and carry on later.

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

// A finished step folds away, so its "done" message is a toast that stays visible.
function useStep(fn: (prev: FormState, form: FormData) => Promise<FormState>) {
  return useActionState(async (prev: FormState, form: FormData) => {
    const r = await fn(prev, form);
    if (r?.message && !r.error) toast(r.message);
    return r?.error ? r : null;
  }, null);
}

const today = () => new Intl.DateTimeFormat("en-CA", { timeZone: "Australia/Sydney" }).format(new Date());

type Doc = { id: string; title: string; description: string; body: string; link: string | null; fileLink: string | null; fileName: string | null };

// The policy or agreement text, with links to open the file or page.
function DocumentView({ doc, onOpen }: { doc: Doc; onOpen?: () => void }) {
  return (
    <div className="flex flex-col gap-3">
      {doc.body ? (
        <div className="max-h-[26rem] overflow-y-auto rounded-lg border border-line bg-surface p-4 text-sm leading-relaxed whitespace-pre-line">{doc.body}</div>
      ) : null}
      {doc.fileLink || doc.link ? (
        <p className="flex flex-wrap gap-3 text-sm">
          {doc.fileLink ? (
            <a href={doc.fileLink} target="_blank" rel="noopener noreferrer" onClick={onOpen} className="inline-flex items-center gap-1.5 font-semibold text-brand underline">
              <FileText aria-hidden="true" className="size-4" /> Open {doc.fileName ?? "the document"}
            </a>
          ) : null}
          {doc.link ? (
            <a href={doc.link} target="_blank" rel="noopener noreferrer" onClick={onOpen} className="inline-flex items-center gap-1.5 font-semibold text-brand underline">
              <ExternalLink aria-hidden="true" className="size-4" /> Open the page
            </a>
          ) : null}
        </p>
      ) : null}
    </div>
  );
}

// Read first (recorded), then acknowledge with a tick and full name.
export function PolicyStep({ doc, opened: openedAtStart, fullName }: { doc: Doc; opened: boolean; fullName: string }) {
  const [opened, setOpened] = useState(openedAtStart);
  const [showing, setShowing] = useState(openedAtStart);
  const [state, action, pending] = useStep(acknowledgePolicy);
  const [, start] = useTransition();
  const record = () => {
    setShowing(true);
    if (!opened) start(async () => {
      const r = await openItem(doc.id);
      if (!r.error) setOpened(true);
    });
  };
  return (
    <div className="flex flex-col gap-4">
      {doc.description ? <p className="text-sm text-muted">{doc.description}</p> : null}
      {showing ? (
        <DocumentView doc={doc} onOpen={record} />
      ) : (
        <Button variant="outline" className="self-start" onClick={record} type="button">
          <FileText aria-hidden="true" className="size-4" /> Read the policy
        </Button>
      )}
      {opened ? (
        <form action={action} className="flex flex-col gap-3 rounded-lg border border-line bg-page p-4">
          <Result state={state} />
          <input type="hidden" name="item_id" value={doc.id} />
          <label className="flex items-start gap-3 text-sm">
            <input type="checkbox" name="agree" required className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]" />
            <span>I have read and understood this policy, and I agree to follow it.</span>
          </label>
          <Field label="Type your full name" htmlFor={`ack-${doc.id}`} hint={`As it is on your account: ${fullName}`}>
            <input id={`ack-${doc.id}`} name="name" required autoComplete="name" className={inputClass} />
          </Field>
          <Button className="self-start" disabled={pending}>
            {pending ? "Saving…" : "Acknowledge"}
          </Button>
        </form>
      ) : (
        <p className="text-xs text-muted">Read the policy first. Then you can acknowledge it.</p>
      )}
    </div>
  );
}

export function TrainingStep({
  itemId,
  userId,
  description,
  link,
  certificate,
  needsExpiry,
  mandatory,
}: {
  itemId: string;
  userId: string;
  description: string;
  link: string | null;
  certificate: "none" | "optional" | "required";
  needsExpiry: boolean;
  mandatory: boolean;
}) {
  const [state, action, pending] = useStep(completeTraining);
  const [file, setFile] = useState(false);
  const [ready, setReady] = useState(true);
  const needsCert = certificate === "required" || mandatory;
  const offersCert = needsCert || certificate === "optional";
  return (
    <div className="flex flex-col gap-4">
      {description ? <p className="text-sm text-muted">{description}</p> : null}
      {link ? (
        <a href={link} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1.5 self-start text-sm font-semibold text-brand underline">
          <ExternalLink aria-hidden="true" className="size-4" /> Open the training
        </a>
      ) : null}
      <form action={action} className="flex flex-col gap-3 rounded-lg border border-line bg-page p-4">
        <Result state={state} />
        <input type="hidden" name="item_id" value={itemId} />
        <p className="text-sm font-medium">When you&apos;ve finished it, record it here.</p>
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Date completed" htmlFor={`done-${itemId}`}>
            <input id={`done-${itemId}`} name="completed_on" type="date" max={today()} required className={inputClass} />
          </Field>
          <Field label="Provider (optional)" htmlFor={`prov-${itemId}`}>
            <input id={`prov-${itemId}`} name="provider" maxLength={120} placeholder="e.g. NDIS Commission" className={inputClass} />
          </Field>
        </div>
        {offersCert ? (
          <div className="grid gap-3 md:grid-cols-[2fr_1fr] md:items-start">
            <Field label={needsCert ? "Certificate" : "Certificate (optional)"} htmlFor={`cert-${itemId}`} hint={needsCert ? "Needed to complete this training. It will be checked." : undefined}>
              <FileUpload
                id={`cert-${itemId}`}
                bucket={FILES_BUCKET}
                folder={userId}
                name="file"
                required={needsCert}
                onReady={(r) => {
                  setReady(r);
                  setFile(r);
                }}
              />
            </Field>
            {needsExpiry && file ? (
              <Field label="Certificate expiry" htmlFor={`cexp-${itemId}`}>
                <input id={`cexp-${itemId}`} name="expires_on" type="date" min={today()} required className={inputClass} />
              </Field>
            ) : null}
          </div>
        ) : null}
        <Button className="self-start" disabled={pending || (needsCert && !file) || !ready}>
          {pending ? "Saving…" : "Record completion"}
        </Button>
      </form>
    </div>
  );
}

export type HistoryRow = { id: number; when: string; file: string; status: string; reviewer: string; reviewedOn: string; note: string; expires: string; number: string };

export function DocumentStep({
  itemId,
  userId,
  description,
  needsExpiry,
  needsIssue,
  needsNumber,
  askIssue = true,
  again,
  history,
}: {
  itemId: string;
  userId: string;
  description: string;
  needsExpiry: boolean;
  needsIssue: boolean;
  needsNumber: boolean;
  askIssue?: boolean;
  again: boolean;
  history: HistoryRow[];
}) {
  const [state, action, pending] = useStep(submitDocument);
  const [ready, setReady] = useState(false);
  return (
    <div className="flex flex-col gap-4">
      {description ? <p className="text-sm text-muted">{description}</p> : null}
      <form action={action} className="flex flex-col gap-3 rounded-lg border border-line bg-page p-4">
        <Result state={state} />
        <input type="hidden" name="item_id" value={itemId} />
        <Field label={again ? "Upload a new copy" : "Choose the file"} htmlFor={`doc-${itemId}`} hint="A clear photo or scan (PDF or picture). It's checked before it counts as verified.">
          <FileUpload id={`doc-${itemId}`} bucket={FILES_BUCKET} folder={userId} name="file" required onReady={setReady} />
        </Field>
        <div className="grid gap-3 sm:grid-cols-3">
          {needsNumber ? (
            <Field label="Document or card number" htmlFor={`num-${itemId}`}>
              <input id={`num-${itemId}`} name="doc_number" required maxLength={60} className={inputClass} />
            </Field>
          ) : null}
          {needsIssue || askIssue ? (
            <Field label={needsIssue ? "Issue date" : "Issue date (optional)"} htmlFor={`iss-${itemId}`}>
              <input id={`iss-${itemId}`} name="issued_on" type="date" max={today()} required={needsIssue} className={inputClass} />
            </Field>
          ) : null}
          {needsExpiry ? (
            <Field label="Expiry date" htmlFor={`exp-${itemId}`}>
              <input id={`exp-${itemId}`} name="expires_on" type="date" min={today()} required className={inputClass} />
            </Field>
          ) : null}
        </div>
        <Button className="self-start" disabled={pending || !ready}>
          {pending ? "Saving…" : again ? "Send the new copy" : "Send for checking"}
        </Button>
      </form>
      {history.length ? (
        <details className="text-sm">
          <summary className="cursor-pointer font-semibold text-brand">History · {history.length}</summary>
          <ul className="mt-2 flex flex-col divide-y divide-line rounded-lg border border-line">
            {history.map((h) => (
              <li key={h.id} className="flex flex-col gap-0.5 px-3 py-2">
                <span className="font-medium">
                  {h.file || "File"} · <span className="text-muted">sent {h.when}</span>
                </span>
                <span className="text-xs text-muted">
                  {h.status}
                  {h.reviewer ? ` by ${h.reviewer}` : ""}
                  {h.reviewedOn ? ` on ${h.reviewedOn}` : ""}
                  {h.number ? ` · No. ${h.number}` : ""}
                  {h.expires ? ` · expires ${h.expires}` : ""}
                </span>
                {h.note ? <span className="text-xs text-warn">Note: {h.note}</span> : null}
              </li>
            ))}
          </ul>
        </details>
      ) : null}
    </div>
  );
}

// A drawn signature (finger, mouse or pen). Gives back a PNG when there's ink.
function SignaturePad({ onChange }: { onChange: (canvas: HTMLCanvasElement | null) => void }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);
  const inked = useRef(false);
  useEffect(() => {
    const c = ref.current;
    if (!c) return;
    const ratio = window.devicePixelRatio || 1;
    c.width = c.offsetWidth * ratio;
    c.height = c.offsetHeight * ratio;
    const ctx = c.getContext("2d")!;
    ctx.scale(ratio, ratio);
    ctx.lineWidth = 2.2;
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.strokeStyle = "#0b1f3a";
  }, []);
  const at = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const r = e.currentTarget.getBoundingClientRect();
    return [e.clientX - r.left, e.clientY - r.top] as const;
  };
  return (
    <div className="flex flex-col gap-2">
      <canvas
        ref={ref}
        aria-label="Draw your signature here"
        className="h-40 w-full touch-none rounded-lg border-2 border-dashed border-field bg-white"
        onPointerDown={(e) => {
          e.currentTarget.setPointerCapture(e.pointerId);
          drawing.current = true;
          const ctx = e.currentTarget.getContext("2d")!;
          const [x, y] = at(e);
          ctx.beginPath();
          ctx.moveTo(x, y);
        }}
        onPointerMove={(e) => {
          if (!drawing.current) return;
          const ctx = e.currentTarget.getContext("2d")!;
          const [x, y] = at(e);
          ctx.lineTo(x, y);
          ctx.stroke();
          if (!inked.current) {
            inked.current = true;
            onChange(e.currentTarget);
          }
        }}
        onPointerUp={() => (drawing.current = false)}
        onPointerLeave={() => (drawing.current = false)}
      />
      <button
        type="button"
        onClick={() => {
          const c = ref.current;
          if (!c) return;
          c.getContext("2d")!.clearRect(0, 0, c.width, c.height);
          inked.current = false;
          onChange(null);
        }}
        className="inline-flex items-center gap-1.5 self-start text-sm font-semibold text-brand"
      >
        <Eraser aria-hidden="true" className="size-4" /> Clear and draw again
      </button>
    </div>
  );
}

// Read the agreement (recorded), then sign: drawn signature, full name and a tick.
export function AgreementStep({ doc, opened: openedAtStart, fullName, userId }: { doc: Doc; opened: boolean; fullName: string; userId: string }) {
  const [opened, setOpened] = useState(openedAtStart);
  const [showing, setShowing] = useState(openedAtStart);
  const [canvas, setCanvas] = useState<HTMLCanvasElement | null>(null);
  const [state, action, pending] = useStep(signAgreement);
  const [uploadError, setUploadError] = useState("");
  const [sending, start] = useTransition();
  const record = () => {
    setShowing(true);
    if (!opened) start(async () => {
      const r = await openItem(doc.id);
      if (!r.error) setOpened(true);
    });
  };
  return (
    <div className="flex flex-col gap-4">
      {doc.description ? <p className="text-sm text-muted">{doc.description}</p> : null}
      {showing ? (
        <DocumentView doc={doc} onOpen={record} />
      ) : (
        <Button variant="outline" className="self-start" onClick={record} type="button">
          <FileText aria-hidden="true" className="size-4" /> Read the agreement
        </Button>
      )}
      {opened ? (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            setUploadError("");
            const form = new FormData(e.currentTarget);
            if (!canvas) return setUploadError("Draw your signature in the box.");
            start(async () => {
              const blob: Blob | null = await new Promise((res) => canvas.toBlob(res, "image/png"));
              if (!blob) return setUploadError("Your signature couldn't be saved. Draw it again.");
              const path = `${userId}/signature-${Date.now()}.png`;
              const { error } = await createClient().storage.from(FILES_BUCKET).upload(path, blob, { contentType: "image/png" });
              if (error) return setUploadError("Your signature couldn't be uploaded. Check your connection and try again.");
              form.set("signature_path", path);
              form.set("device", navigator.userAgent);
              action(form);
            });
          }}
          className="flex flex-col gap-3 rounded-lg border border-line bg-page p-4"
        >
          <Result state={state} />
          {uploadError ? <Notice tone="error">{uploadError}</Notice> : null}
          <input type="hidden" name="item_id" value={doc.id} />
          <p className="inline-flex items-center gap-2 text-sm font-semibold">
            <PenLine aria-hidden="true" className="size-4" /> Sign here
          </p>
          <SignaturePad onChange={setCanvas} />
          <Field label="Type your full name" htmlFor={`sig-${doc.id}`} hint={`As it is on your account: ${fullName}`}>
            <input id={`sig-${doc.id}`} name="name" required autoComplete="name" className={inputClass} />
          </Field>
          <label className="flex items-start gap-3 text-sm">
            <input type="checkbox" name="agree" required className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]" />
            <span>I have read this agreement and agree to its terms. I understand my drawn signature and typed name sign it electronically.</span>
          </label>
          <Button className="self-start" disabled={pending || sending || !canvas}>
            {pending || sending ? "Signing…" : "Sign the agreement"}
          </Button>
        </form>
      ) : (
        <p className="text-xs text-muted">Read the agreement first. Then you can sign it.</p>
      )}
    </div>
  );
}
