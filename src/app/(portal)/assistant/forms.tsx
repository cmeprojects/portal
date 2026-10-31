// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { AUDIENCE_LABELS, AUDIENCES, SCOPE_LABELS, type AssistantSettings, type Scope } from "@/lib/assistant-shared";
import { addDocument, saveAssistantSettings } from "./actions";

export function SettingsForm({ s, frontPage }: { s: AssistantSettings; frontPage: boolean }) {
  const [state, action, pending] = useActionState(saveAssistantSettings, null);
  const box = "h-5 w-5 shrink-0 accent-[var(--brand-primary)]";
  const tick = (name: string, on: boolean, label: string) => (
    <label className="flex min-h-10 items-center gap-3 text-sm">
      <input type="checkbox" name={name} defaultChecked={on} className={box} />
      {label}
    </label>
  );
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
    <form action={action} className="flex flex-col gap-6">
      <fieldset className="flex flex-col gap-4">
        <legend className="mb-2 font-semibold">Landing page</legend>
        <Field label="Heading under the logo" htmlFor="heading">
          <input id="heading" name="heading" defaultValue={s.heading} maxLength={120} className={inputClass} />
        </Field>
        <Field label="Line under the heading" htmlFor="intro">
          <textarea id="intro" name="intro" defaultValue={s.intro} rows={2} maxLength={400} className={`${inputClass} min-h-20 py-3`} />
        </Field>
        <Field label="Suggested questions (one per line, up to 8)" htmlFor="suggestions">
          <textarea id="suggestions" name="suggestions" defaultValue={s.suggestions.join("\n")} rows={4} className={`${inputClass} min-h-28 py-3`} />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Phone number shown on the website" htmlFor="phone">
            <input id="phone" name="phone" defaultValue={s.phone} maxLength={40} className={inputClass} />
          </Field>
          <Field label="Note at the bottom of the page" htmlFor="disclaimer">
            <input id="disclaimer" name="disclaimer" defaultValue={s.disclaimer} maxLength={300} className={inputClass} />
          </Field>
        </div>
        {tick("front_page", frontPage, "Make the website the front page (visitors land here; staff sign in from the top corner)")}
        {tick("show_credits", s.show_credits, "Show the credits at the bottom")}
        {tick("offer_call", s.offer_call, "After an answer, ask \"Would you like to talk to our team?\"")}
        <p className="text-xs text-muted">Colours, fonts and the logo come from System settings → General, so the website always matches the portal.</p>
      </fieldset>

      <fieldset className="flex flex-col gap-4 border-t border-line pt-5">
        <legend className="mb-2 font-semibold">Where it looks for answers</legend>
        <div className="grid gap-4 sm:grid-cols-3">
          {scope("scope_public", "Public visitors")}
          {scope("scope_staff", "Staff (signed in)")}
          {scope("scope_managers", "Managers (signed in)")}
        </div>
        <Field label="Listed websites it may search (one per line)" htmlFor="trusted_sites" hint="Only these sites are searched, for example ndis.gov.au. Searching the web costs about 1 cent each time.">
          <textarea id="trusted_sites" name="trusted_sites" defaultValue={s.trusted_sites.join("\n")} rows={4} className={`${inputClass} min-h-28 py-3`} />
        </Field>
        <Field label="What it says when it can't answer" htmlFor="fallback">
          <textarea id="fallback" name="fallback" defaultValue={s.fallback} rows={2} maxLength={400} className={`${inputClass} min-h-20 py-3`} />
        </Field>
      </fieldset>

      <fieldset className="flex flex-col gap-4 border-t border-line pt-5">
        <legend className="mb-2 font-semibold">Model and limits</legend>
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
        </div>
        {tick("log_questions", s.log_questions, "Keep a log of the questions asked (no names), to see what's missing")}
      </fieldset>

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
