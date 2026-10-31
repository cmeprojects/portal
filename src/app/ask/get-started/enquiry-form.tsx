// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useActionState } from "react";
import { Button, Card, Field, Notice, inputClass } from "@/components/ui";
import { NEEDS, submitEnquiry } from "../actions";

const Choice = ({ name, options, first }: { name: string; options: string[]; first?: string }) => (
  <div className="flex flex-wrap gap-2" role="radiogroup">
    {options.map((o) => (
      <label key={o} className="cursor-pointer">
        <input type="radio" name={name} value={o} defaultChecked={o === first} className="peer sr-only" />
        <span className="inline-flex min-h-11 items-center rounded-full border border-line bg-surface px-4 text-sm peer-checked:border-brand peer-checked:bg-brand peer-checked:text-brand-fg peer-focus-visible:outline-2">
          {o}
        </span>
      </label>
    ))}
  </div>
);

export function EnquiryForm({ asked, phone }: { asked: string; phone: string }) {
  const [state, action, pending] = useActionState(submitEnquiry, null);
  if (state?.done) {
    return (
      <Card className="flex flex-col gap-3 p-6">
        <h2 className="font-display text-2xl font-semibold">Thank you. We&apos;ll call you soon.</h2>
        <p className="text-muted">Someone from our team will call you within one business day.{phone ? ` If it's urgent, call us on ${phone}.` : ""}</p>
        <Link href="/ask" className="self-start text-brand underline">
          Back to questions
        </Link>
      </Card>
    );
  }
  return (
    <Card className="p-5 sm:p-6">
      <form action={action} className="flex flex-col gap-5">
        <input type="hidden" name="asked" value={asked} />
        {/* Real people never see this box; if it's filled in, it's a robot. */}
        <input type="text" name="website" tabIndex={-1} autoComplete="off" aria-hidden="true" className="absolute -left-[9999px]" />
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Your name" htmlFor="full_name">
            <input id="full_name" name="full_name" autoComplete="name" required maxLength={120} className={inputClass} />
          </Field>
          <Field label="Phone" htmlFor="phone">
            <input id="phone" name="phone" type="tel" autoComplete="tel" required maxLength={40} className={inputClass} />
          </Field>
          <Field label="Email (optional)" htmlFor="email">
            <input id="email" name="email" type="email" autoComplete="email" maxLength={200} className={inputClass} />
          </Field>
          <Field label="Suburb" htmlFor="suburb">
            <input id="suburb" name="suburb" maxLength={100} className={inputClass} />
          </Field>
        </div>
        <fieldset className="flex flex-col gap-2">
          <legend className="mb-1 text-sm font-medium">Who is the support for?</legend>
          <Choice name="support_for" options={["Me", "A family member", "Someone I support (coordinator)", "Other"]} first="Me" />
        </fieldset>
        <fieldset className="flex flex-col gap-2">
          <legend className="mb-1 text-sm font-medium">Do you have an NDIS plan?</legend>
          <Choice name="has_plan" options={["Yes", "Not yet", "Not sure"]} />
        </fieldset>
        <fieldset className="flex flex-col gap-2">
          <legend className="mb-1 text-sm font-medium">How is the plan managed?</legend>
          <Choice name="managed_by" options={["Self-managed", "Plan-managed", "NDIA-managed", "Don't know"]} />
        </fieldset>
        <fieldset className="flex flex-col gap-1">
          <legend className="mb-1 text-sm font-medium">What support are you looking for?</legend>
          {NEEDS.map((n) => (
            <label key={n} className="flex min-h-10 items-center gap-3 text-sm">
              <input type="checkbox" name="needs" value={n} className="h-5 w-5 accent-[var(--brand-primary)]" />
              {n}
            </label>
          ))}
        </fieldset>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Best time to call" htmlFor="best_time">
            <select id="best_time" name="best_time" className={inputClass} defaultValue="Any time">
              {["Any time", "Morning", "Afternoon", "After 5 pm"].map((o) => (
                <option key={o}>{o}</option>
              ))}
            </select>
          </Field>
          <Field label="How did you hear about us?" htmlFor="heard_from">
            <select id="heard_from" name="heard_from" className={inputClass} defaultValue="">
              <option value="">Choose one</option>
              {["Support coordinator", "Google", "Friend or family", "Other"].map((o) => (
                <option key={o}>{o}</option>
              ))}
            </select>
          </Field>
        </div>
        <Field label="Anything else? (optional)" htmlFor="message" hint="Please don't include health details.">
          <textarea id="message" name="message" rows={3} maxLength={1000} className={`${inputClass} min-h-24 py-3`} />
        </Field>
        <label className="flex items-start gap-3 text-sm leading-relaxed">
          <input type="checkbox" name="consent" required className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]" />
          <span>I agree to be contacted about support. We keep your details private and only use them to get in touch.</span>
        </label>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        <Button disabled={pending} className="self-start">
          {pending ? "Sending…" : "Send my details"}
        </Button>
      </form>
    </Card>
  );
}
