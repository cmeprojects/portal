// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { AUDIENCE_LABELS, AUDIENCES, type AssistantSettings } from "@/lib/assistant-shared";
import { addDocument, saveAssistantSettings } from "./actions";

export function SettingsForm({ s }: { s: AssistantSettings }) {
  const [state, action, pending] = useActionState(saveAssistantSettings, null);
  const box = "h-5 w-5 accent-[var(--brand-primary)]";
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Which AI model answers?" htmlFor="model" hint="Haiku is the cheapest. Switch to Sonnet any time if answers need more depth.">
          <select id="model" name="model" defaultValue={s.model} className={inputClass}>
            <option value="haiku">Haiku (fast, cheapest)</option>
            <option value="sonnet">Sonnet (smarter, costs more)</option>
          </select>
        </Field>
        <Field label="Phone number shown on the website" htmlFor="phone">
          <input id="phone" name="phone" defaultValue={s.phone} maxLength={40} className={inputClass} />
        </Field>
        <Field label="Monthly spending limit (A$)" htmlFor="monthly_limit_aud" hint="At the limit, the website shows what the documents say instead of an AI answer.">
          <input id="monthly_limit_aud" name="monthly_limit_aud" type="number" min={0} step="1" defaultValue={s.monthly_limit_aud} className={inputClass} />
        </Field>
        <Field label="Most questions per hour (whole website)" htmlFor="hourly_limit">
          <input id="hourly_limit" name="hourly_limit" type="number" min={1} max={500} defaultValue={s.hourly_limit} className={inputClass} />
        </Field>
      </div>
      <Field label="Heading on the website" htmlFor="heading">
        <input id="heading" name="heading" defaultValue={s.heading} maxLength={120} className={inputClass} />
      </Field>
      <Field label="Short line under the heading" htmlFor="intro">
        <textarea id="intro" name="intro" defaultValue={s.intro} rows={2} maxLength={400} className={`${inputClass} min-h-20 py-3`} />
      </Field>
      <Field label="Note at the bottom of the page" htmlFor="disclaimer">
        <input id="disclaimer" name="disclaimer" defaultValue={s.disclaimer} maxLength={300} className={inputClass} />
      </Field>
      <Field label="What it says when it can't answer" htmlFor="fallback">
        <textarea id="fallback" name="fallback" defaultValue={s.fallback} rows={2} maxLength={400} className={`${inputClass} min-h-20 py-3`} />
      </Field>
      <label className="flex min-h-10 items-center gap-3 text-sm">
        <input type="checkbox" name="offer_call" defaultChecked={s.offer_call} className={box} />
        After an answer, ask &quot;Would you like to talk to our team?&quot;
      </label>
      <label className="flex min-h-10 items-center gap-3 text-sm">
        <input type="checkbox" name="log_questions" defaultChecked={s.log_questions} className={box} />
        Keep a log of the questions asked (no names), so you can see what&apos;s missing
      </label>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button disabled={pending} className="self-start">
        {pending ? "Saving…" : "Save"}
      </Button>
    </form>
  );
}

export function AddDocumentForm() {
  const [state, action, pending] = useActionState(addDocument, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Name" htmlFor="title" hint="Leave blank to use the file name.">
          <input id="title" name="title" maxLength={200} className={inputClass} />
        </Field>
        <Field label="Who can get answers from it?" htmlFor="audience">
          <select id="audience" name="audience" defaultValue="public" className={inputClass}>
            {AUDIENCES.map((a) => (
              <option key={a} value={a}>
                {AUDIENCE_LABELS[a]}
              </option>
            ))}
          </select>
        </Field>
      </div>
      <Field label="File" htmlFor="file" hint="PDF, Word (.docx) or text, up to 10 MB.">
        <input id="file" name="file" type="file" accept=".pdf,.docx,.txt,.md" className={`${inputClass} h-auto py-2`} />
      </Field>
      <Field label="Or paste the words" htmlFor="body">
        <textarea id="body" name="body" rows={4} className={`${inputClass} min-h-28 py-3`} />
      </Field>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button disabled={pending} className="self-start">
        {pending ? "Reading it…" : "Add document"}
      </Button>
    </form>
  );
}
