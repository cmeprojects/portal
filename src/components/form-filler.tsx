// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import type { FormAnswers, FormInfo, FormQuestion } from "@/lib/form-types";
import { submitReply } from "@/app/(portal)/forms/actions";

type Props = {
  form: Pick<FormInfo, "id" | "title" | "intro" | "repeatable" | "anonymous" | "show_header" | "show_contact" | "due_date">;
  questions: FormQuestion[];
  brand: { companyName: string; logoUrl: string };
  contact: { name: string; email: string } | null;
  userId: string;
  // "preview": Try it in the editor; nothing is saved.
  mode: "live" | "preview";
  draft?: FormAnswers;
};

const nice = (iso: string) =>
  new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "long", year: "numeric", timeZone: "UTC" }).format(new Date(`${iso}T00:00:00Z`));

// cmeprojects: a form as staff see it, with the company header at the top
// and who to ask at the bottom (both can be switched off per form).
export function FormFiller({ form, questions, brand, contact, userId, mode, draft }: Props) {
  const router = useRouter();
  const live = questions.filter((q) => !q.archived).sort((a, b) => a.sort_order - b.sort_order);
  const [answers, setAnswers] = useState<FormAnswers>(draft ?? {});
  const [error, setError] = useState("");
  const [done, setDone] = useState<string | null>(null);
  const [pending, start] = useTransition();
  const set = (id: string, v: string | string[]) => setAnswers((a) => ({ ...a, [id]: v }));

  const send = (finish: boolean) => {
    setError("");
    if (finish) {
      const missing = live.find((q) => q.required && (Array.isArray(answers[q.id]) ? !(answers[q.id] as string[]).length : !String(answers[q.id] ?? "").trim()));
      if (missing) {
        setError(`${missing.label}: this is needed.`);
        document.getElementById(`fq-${missing.id}`)?.focus();
        return;
      }
    }
    if (mode === "preview") {
      setDone(finish ? "Sent (this is a try-out: nothing was saved)." : "Saved for later (this is a try-out: nothing was saved).");
      return;
    }
    start(async () => {
      const r = await submitReply(form.id, answers, finish);
      if (r.error) setError(r.error);
      else {
        setDone(r.message ?? "Sent. Thank you.");
        router.refresh();
      }
    });
  };

  return (
    <div className="flex flex-col gap-5">
      {form.show_header ? (
        <div className="flex items-center gap-3 border-b border-line pb-4">
          {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
          <img src={brand.logoUrl} alt="" className="h-12 w-auto max-w-[45%] object-contain" />
          <p className="font-display text-lg font-semibold tracking-wide uppercase">{brand.companyName}</p>
        </div>
      ) : null}
      <div>
        <h1 className="heading">{form.title || "Untitled form"}</h1>
        {form.intro ? <p className="mt-2 text-sm whitespace-pre-line text-muted">{form.intro}</p> : null}
        <p className="mt-2 text-xs text-muted">
          {[form.due_date ? `Please fill this in by ${nice(form.due_date)}.` : "", form.anonymous ? "Your answers are anonymous: your name isn't shown with them." : ""]
            .filter(Boolean)
            .join(" ")}
        </p>
      </div>

      {done ? (
        <div className="flex flex-col gap-3 rounded-lg border border-good/40 bg-good-soft p-4">
          <p className="font-semibold">{done}</p>
          {form.repeatable || mode === "preview" ? (
            <Button
              type="button"
              variant="outline"
              className="self-start"
              onClick={() => {
                setAnswers({});
                setDone(null);
              }}
            >
              {mode === "preview" ? "Try it again" : "Fill in another"}
            </Button>
          ) : null}
        </div>
      ) : (
        <form
          className="flex flex-col gap-5"
          onSubmit={(e) => {
            e.preventDefault();
            send(true);
          }}
        >
          {live.map((q, i) => (
            <fieldset key={q.id} className="flex flex-col gap-2">
              <legend className="mb-1 font-semibold">
                {i + 1}. {q.label || "(no question yet)"}
                {q.required ? <span className="text-danger"> *</span> : null}
              </legend>
              {q.help ? <p className="-mt-1 text-sm text-muted">{q.help}</p> : null}
              <Answer q={q} value={answers[q.id]} set={(v) => set(q.id, v)} userId={userId} preview={mode === "preview"} />
            </fieldset>
          ))}
          {live.length === 0 ? <p className="text-sm text-muted">No questions yet.</p> : null}
          {error ? <Notice tone="error">{error}</Notice> : null}
          <div className="flex flex-wrap gap-2">
            <Button disabled={pending || live.length === 0}>{pending ? "Sending…" : "Send"}</Button>
            {!form.anonymous ? (
              <Button type="button" variant="outline" disabled={pending} onClick={() => send(false)}>
                Save and finish later
              </Button>
            ) : null}
          </div>
        </form>
      )}

      {form.show_contact && contact ? (
        <div className="border-t border-line pt-3 text-sm text-muted">
          <p>
            Questions? Contact <strong className="text-ink">{contact.name}</strong>
          </p>
          <p>{contact.email}</p>
        </div>
      ) : null}
    </div>
  );
}

function Answer({ q, value, set, userId, preview }: { q: FormQuestion; value: string | string[] | undefined; set: (v: string | string[]) => void; userId: string; preview: boolean }) {
  const id = `fq-${q.id}`;
  const v = typeof value === "string" ? value : "";
  const chip = (on: boolean) =>
    `min-h-11 rounded-full border px-4 text-sm font-medium ${on ? "border-brand bg-brand text-brand-fg" : "border-line bg-surface text-ink hover:border-muted"}`;
  switch (q.type) {
    case "long":
      return <textarea id={id} rows={4} maxLength={5000} value={v} onChange={(e) => set(e.target.value)} className={`${inputClass} min-h-28 py-3`} />;
    case "choice":
      return (
        <div className="flex flex-wrap gap-2" role="radiogroup" aria-labelledby={id}>
          {q.options.map((o, n) => (
            <button key={o} id={n === 0 ? id : undefined} type="button" role="radio" aria-checked={v === o} onClick={() => set(v === o ? "" : o)} className={chip(v === o)}>
              {o}
            </button>
          ))}
        </div>
      );
    case "multi": {
      const list = Array.isArray(value) ? value : [];
      return (
        <div className="flex flex-col gap-1">
          {q.options.map((o, n) => (
            <label key={o} className="flex min-h-10 items-center gap-2 text-sm">
              <input
                id={n === 0 ? id : undefined}
                type="checkbox"
                checked={list.includes(o)}
                onChange={(e) => set(e.target.checked ? [...list, o] : list.filter((x) => x !== o))}
                className="h-5 w-5 accent-[var(--brand-primary)]"
              />
              {o}
            </label>
          ))}
        </div>
      );
    }
    case "yesno":
      return (
        <div className="flex gap-2">
          {["Yes", "No"].map((o, n) => (
            <button key={o} id={n === 0 ? id : undefined} type="button" aria-pressed={v === o} onClick={() => set(v === o ? "" : o)} className={chip(v === o)}>
              {o}
            </button>
          ))}
        </div>
      );
    case "date":
      return <input id={id} type="date" value={v} onChange={(e) => set(e.target.value)} className={`${inputClass} max-w-56`} />;
    case "number":
      return <input id={id} inputMode="decimal" value={v} onChange={(e) => set(e.target.value.replace(/[^\d.-]/g, ""))} className={`${inputClass} max-w-56`} />;
    case "file":
      return preview ? (
        <p className="text-sm text-muted">Staff can add a photo or file here.</p>
      ) : (
        <FileUpload id={id} bucket="form-files" folder={userId} name={`f-${q.id}`} accept="image/*,application/pdf,.doc,.docx" onUploaded={(path) => set(path)} />
      );
    case "signature":
      return (
        <div className="flex flex-col gap-1">
          <input id={id} value={v} maxLength={120} placeholder="Type your full name" onChange={(e) => set(e.target.value)} className={`${inputClass} max-w-md font-[cursive] text-lg`} />
          <p className="text-xs text-muted">Typing your name here counts as your signature. The date and time are recorded when you send it.</p>
        </div>
      );
    default:
      return <input id={id} value={v} maxLength={300} onChange={(e) => set(e.target.value)} className={inputClass} />;
  }
}
