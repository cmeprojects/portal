// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { startTransition, useActionState, useState, useTransition, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Ban, CheckCircle2, Download, FilePlus2, PenLine, Save, Send, ShieldCheck, Trash2 } from "lucide-react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";
import { SignaturePad } from "@/app/(portal)/onboarding/steps";
import { CONSENT_TEXT } from "@/lib/contracts";
import { cancelContract, checkSignedCopy, deleteDraft, finishContract, openSignedCopy, saveDraft, sendContract, signContract } from "./actions";

type Person = { id: string; name: string };

// cmeprojects: submit without the browser's form reset, so a refused save keeps what was typed.
const keep = (run: (f: FormData) => void) => (e: FormEvent<HTMLFormElement>) => {
  e.preventDefault();
  const data = new FormData(e.currentTarget);
  startTransition(() => run(data));
};

// New contract, new version, or editing a draft.
export function DraftForm({
  people,
  draft,
  supersedes,
  defaults,
}: {
  people: Person[];
  draft?: { id: string; title: string; body: string; sign_by: string | null; letterhead?: boolean };
  supersedes?: { id: string; userId: string };
  defaults?: { title: string; body: string };
}) {
  const router = useRouter();
  const [state, run, pending] = useActionState(saveDraft, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, (message) => {
    markClean();
    if (message.startsWith("saved:")) router.push(`/contracts/${message.slice(6)}`);
    else toast(message);
  });
  return (
    <form ref={ref} onSubmit={keep(run)} className="flex flex-col gap-4">
      {draft ? <input type="hidden" name="id" value={draft.id} /> : null}
      {supersedes ? (
        <>
          <input type="hidden" name="supersedes" value={supersedes.id} />
          <input type="hidden" name="user_id" value={supersedes.userId} />
        </>
      ) : null}
      {!draft && !supersedes ? (
        <Field label="Employee" htmlFor="c-user">
          <select id="c-user" name="user_id" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose a person
            </option>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </Field>
      ) : null}
      <div className="grid gap-4 sm:grid-cols-[1fr_12rem]">
        <Field label="Title" htmlFor="c-title">
          <input id="c-title" name="title" required minLength={2} maxLength={200} defaultValue={draft?.title ?? defaults?.title ?? "Employment contract"} className={inputClass} />
        </Field>
        <Field label="Sign by (optional)" htmlFor="c-signby" hint="Unsigned after this: expired.">
          <input id="c-signby" name="sign_by" type="date" defaultValue={draft?.sign_by ?? ""} className={inputClass} />
        </Field>
      </div>
      <Field label="Contract wording" htmlFor="c-body" hint="Exactly what they'll read and sign. Once sent, it can't be changed: make a new version instead.">
        <textarea id="c-body" name="body" required rows={16} maxLength={100000} defaultValue={draft?.body ?? defaults?.body ?? ""} className={`${inputClass} h-auto py-3 font-mono text-[13px] leading-relaxed`} />
      </Field>
      <label className="flex items-start gap-2 text-sm">
        <input type="checkbox" name="letterhead" defaultChecked={draft?.letterhead ?? true} className="mt-0.5 size-4 shrink-0 accent-[var(--accent)]" />
        <span>
          Include our logo and letterhead
          <span className="block text-xs text-muted">The company logo and name at the top of every page of the signed copy.</span>
        </span>
      </label>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button className="self-start" disabled={pending || (Boolean(draft) && !dirty)}>
        <Save aria-hidden="true" className="size-4" />
        {pending ? "Saving…" : draft ? "Save draft" : "Save as draft"}
      </Button>
    </form>
  );
}

// The buttons on a contract, by status. Each asks first and shows the result.
export function ContractActions({ id, status, canSend, canFinish = canSend, signedCopy }: { id: string; status: string; canSend: boolean; canFinish?: boolean; signedCopy: boolean }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  // Ask first (outside the update, so the pop-up shows straight away), then act.
  const act = async (fn: () => Promise<{ error?: string; message?: string } | null>, ask?: string, okWord?: string) => {
    if (ask && !(await askConfirm(ask, { action: okWord ?? "Yes" }))) return;
    start(async () => {
      const r = await fn();
      toast(r?.error ?? r?.message ?? "Done.", r?.error ? "error" : "success");
      router.refresh();
    });
  };
  return (
    <div className="flex flex-wrap gap-2">
      {status === "draft" && canSend ? (
        <Button type="button" disabled={pending} onClick={() => act(() => sendContract(id), "Send this contract to sign? After sending, the wording can't be changed.", "Send to sign")}>
          <Send aria-hidden="true" className="size-4" /> Send to sign
        </Button>
      ) : null}
      {status === "awaiting_employer" && canFinish ? (
        <Button type="button" variant="outline" disabled={pending} onClick={() => act(() => finishContract(id))}>
          <CheckCircle2 aria-hidden="true" className="size-4" /> Finish (make the signed copy)
        </Button>
      ) : null}
      {signedCopy ? (
        <>
          <Button
            type="button"
            variant="outline"
            disabled={pending}
            onClick={() =>
              start(async () => {
                const r = await openSignedCopy(id);
                if (r.url) window.location.href = r.url;
                else toast(r.error ?? "Couldn't open it.", "error");
              })
            }
          >
            <Download aria-hidden="true" className="size-4" /> Signed copy (PDF)
          </Button>
          <Button
            type="button"
            variant="outline"
            disabled={pending}
            onClick={() =>
              start(async () => {
                const r = await checkSignedCopy(id);
                if (r.error) toast(r.error, "error");
                else toast(r.ok ? "Checked: the signed copy is exactly as it was signed." : "Warning: the signed copy doesn't match what was signed.", r.ok ? "success" : "error");
              })
            }
          >
            <ShieldCheck aria-hidden="true" className="size-4" /> Check this copy
          </Button>
        </>
      ) : null}
      {canSend && (status === "fully_signed" || status === "cancelled" || status === "expired") ? (
        <Button type="button" variant="outline" disabled={pending} onClick={() => router.push(`/contracts/new?from=${id}`)}>
          <FilePlus2 aria-hidden="true" className="size-4" /> New version
        </Button>
      ) : null}
      {canSend && ["awaiting_employee", "awaiting_employer"].includes(status) ? (
        <Button type="button" variant="outline" disabled={pending} onClick={() => act(() => cancelContract(id), "Cancel this contract? It can't be signed after this. It stays in the history.", "Cancel contract")}>
          <Ban aria-hidden="true" className="size-4" /> Cancel
        </Button>
      ) : null}
      {canSend && status === "draft" ? (
        <Button
          type="button"
          variant="outline"
          disabled={pending}
          onClick={async () => {
            if (!(await askConfirm("Delete this draft? It was never sent.", { action: "Delete draft" }))) return;
            start(async () => {
              const r = await deleteDraft(id);
              toast(r?.error ?? r?.message ?? "", r?.error ? "error" : "success");
              if (!r?.error) router.push("/contracts");
            });
          }}
        >
          <Trash2 aria-hidden="true" className="size-4" /> Delete draft
        </Button>
      ) : null}
    </div>
  );
}

// Read, agree, type your name, draw your signature, and confirm it's you.
export function SignForm({ id, contentHash, fullName, party }: { id: string; contentHash: string; fullName: string; party: "employee" | "employer" }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const [error, setError] = useState("");
  const [canvas, setCanvas] = useState<HTMLCanvasElement | null>(null);
  const [consent, setConsent] = useState(false);
  // The result is shown straight away (as a toast on success, since this
  // form goes once the contract moves on).
  const submit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const data = new FormData(e.currentTarget);
    if (canvas) data.set("signature", canvas.toDataURL("image/png"));
    setError("");
    start(async () => {
      const r = await signContract(null, data);
      if (r?.error) {
        setError(r.error);
        toast(r.error, "error");
        return;
      }
      toast(r?.message ?? "Signed.");
      router.refresh();
    });
  };
  return (
    <form onSubmit={submit} className="flex flex-col gap-4">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="content_hash" value={contentHash} />
      <label className="flex items-start gap-2 text-sm">
        <input type="checkbox" name="consent" checked={consent} onChange={(e) => setConsent(e.target.checked)} className="mt-0.5 size-4 shrink-0 accent-[var(--accent)]" />
        <span>{CONSENT_TEXT}</span>
      </label>
      <Field label={party === "employee" ? "Your full name" : "Your full name (signing for the employer)"} htmlFor="sg-name">
        <input id="sg-name" name="signed_name" required minLength={2} maxLength={120} defaultValue={fullName} autoComplete="name" className={inputClass} />
      </Field>
      <div className="flex flex-col gap-1.5">
        <p className="text-sm font-semibold">Your signature</p>
        <SignaturePad onChange={setCanvas} />
      </div>
      <Field label="Confirm it's you" htmlFor="sg-secret" hint="Your password, or a 6-digit code from your authenticator app if you use one.">
        <input id="sg-secret" name="secret" type="password" required autoComplete="current-password" className={inputClass} />
      </Field>
      {error ? <Notice tone="error">{error}</Notice> : null}
      <Button className="self-start" disabled={pending || !consent || !canvas}>
        <PenLine aria-hidden="true" className="size-4" />
        {pending ? "Signing…" : "Sign"}
      </Button>
    </form>
  );
}
