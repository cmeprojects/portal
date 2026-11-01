// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, type ReactNode } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { AUDIENCE_LABELS, AUDIENCES, SCOPE_LABELS, type AssistantSettings, type Scope } from "@/lib/assistant-shared";
import { addDocument, saveAssistantSettings } from "./actions";

const box = "h-5 w-5 shrink-0 accent-[var(--brand-primary)]";
const tick = (name: string, on: boolean, label: string) => (
  <label className="flex min-h-10 items-center gap-3 text-sm">
    <input type="checkbox" name={name} defaultChecked={on} className={box} />
    {label}
  </label>
);
const area = (name: string, value: string, rows = 2, max?: number) => (
  <textarea id={name} name={name} defaultValue={value} rows={rows} maxLength={max} className={`${inputClass} min-h-20 py-3`} />
);

// One part of Website settings; each saves only its own fields.
function PartForm({ part, children }: { part: "landing" | "answers" | "limits"; children: ReactNode }) {
  const [state, action, pending] = useActionState(saveAssistantSettings, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="part" value={part} />
      {children}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button disabled={pending} className="self-start">
        {pending ? "Saving…" : "Save"}
      </Button>
    </form>
  );
}

export function LandingForm({ s }: { s: AssistantSettings }) {
  return (
    <PartForm part="landing">
      <Field label="Heading under the logo" htmlFor="heading">
        <input id="heading" name="heading" defaultValue={s.heading} maxLength={120} className={inputClass} />
      </Field>
      <Field label="Line under the heading" htmlFor="intro">
        {area("intro", s.intro, 2, 400)}
      </Field>
      <Field label="Suggested questions (one per line, up to 8)" htmlFor="suggestions">
        {area("suggestions", s.suggestions.join("\n"), 4)}
      </Field>
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Phone number for Contact us" htmlFor="phone">
          <input id="phone" name="phone" defaultValue={s.phone} maxLength={40} className={inputClass} />
        </Field>
        <Field label="Note at the bottom of the page" htmlFor="disclaimer">
          <input id="disclaimer" name="disclaimer" defaultValue={s.disclaimer} maxLength={300} className={inputClass} />
        </Field>
      </div>
      {tick("show_credits", s.show_credits, "Show the credits at the bottom")}
      {tick("offer_call", s.offer_call, "After an answer, ask \"Would you like to talk to our team?\"")}
    </PartForm>
  );
}

export function AnswersForm({ s, aiReady }: { s: AssistantSettings; aiReady: boolean }) {
  const scope = (name: "scope_public" | "scope_staff" | "scope_managers", label: string) => (
    <Field label={label} htmlFor={name}>
      <select id={name} name={name} defaultValue={s[name]} className={inputClass}>
        {(Object.keys(SCOPE_LABELS) as Scope[]).map((k) => (
          <option key={k} value={k}>
            {SCOPE_LABELS[k]}
          </option>
        ))}
      </select>
    </Field>
  );
  return (
    <PartForm part="answers">
      {!aiReady ? <Notice>Listed websites need the AI key. Until it&apos;s added, the Assistant answers from your documents only, whatever you choose here.</Notice> : null}
      <div className="grid gap-4 sm:grid-cols-3">
        {scope("scope_public", "Public visitors")}
        {scope("scope_staff", "Staff (signed in)")}
        {scope("scope_managers", "Managers (signed in)")}
      </div>
      <Field label="Listed websites it may search (one per line)" htmlFor="trusted_sites" hint="Only these sites are searched, for example ndis.gov.au. Each web search costs about 1 cent.">
        {area("trusted_sites", s.trusted_sites.join("\n"), 4)}
      </Field>
      <Field label="What it says when it can't answer" htmlFor="fallback">
        {area("fallback", s.fallback, 2, 400)}
      </Field>
    </PartForm>
  );
}

export function LimitsForm({ s }: { s: AssistantSettings & { credit_aud?: number; credit_since?: string | null } }) {
  return (
    <PartForm part="limits">
      <div className="grid gap-4 sm:grid-cols-3">
        <Field label="Which AI model answers?" htmlFor="model" hint="Haiku is the cheapest. Switch to Sonnet any time.">
          <select id="model" name="model" defaultValue={s.model} className={inputClass}>
            <option value="haiku">Haiku (fast, cheapest)</option>
            <option value="sonnet">Sonnet (smarter, costs more)</option>
          </select>
        </Field>
        <Field label="Monthly spending limit (A$)" htmlFor="monthly_limit_aud" hint="At the limit, it shows what the documents say instead.">
          <input id="monthly_limit_aud" name="monthly_limit_aud" type="number" min={0} step="1" defaultValue={s.monthly_limit_aud} className={inputClass} />
        </Field>
        <Field label="Most questions per hour (whole website)" htmlFor="hourly_limit">
          <input id="hourly_limit" name="hourly_limit" type="number" min={1} max={500} defaultValue={s.hourly_limit} className={inputClass} />
        </Field>
        <Field label="Credit you bought (A$)" htmlFor="credit_aud" hint="From console.anthropic.com → Billing. Used to show what's left.">
          <input id="credit_aud" name="credit_aud" type="number" min={0} step="0.01" defaultValue={s.credit_aud ?? 0} className={inputClass} />
        </Field>
        <Field label="Bought on" htmlFor="credit_since">
          <input id="credit_since" name="credit_since" type="date" defaultValue={s.credit_since ?? ""} className={inputClass} />
        </Field>
      </div>
      {tick("log_questions", s.log_questions, "Keep a log of the questions asked (no names), to see what's missing")}
    </PartForm>
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
      <Field label="File" htmlFor="file" hint="PDF, Word (.docx), text or a photo of a page, up to 10 MB. Scanned pages are read by the AI.">
        <input id="file" name="file" type="file" accept=".pdf,.docx,.txt,.md,.jpg,.jpeg,.png,.webp" className={`${inputClass} h-auto py-2`} />
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
