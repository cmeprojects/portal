// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import { finishSetup } from "./actions";

type Template = { key: string; name: string; description: string; added: boolean };
type Start = { company: string; portal: string; clientWord: string; timezone: string; primary: string; dark: string; accent: string };

const STEPS = ["Organisation", "Look", "Registers", "Package", "Finish"];
const ZONES: [string, string][] = [
  ["Australia/Melbourne", "Victoria (Melbourne)"],
  ["Australia/Sydney", "New South Wales or ACT (Sydney)"],
  ["Australia/Brisbane", "Queensland (Brisbane)"],
  ["Australia/Adelaide", "South Australia (Adelaide)"],
  ["Australia/Perth", "Western Australia (Perth)"],
  ["Australia/Hobart", "Tasmania (Hobart)"],
  ["Australia/Darwin", "Northern Territory (Darwin)"],
];
const PACKAGES: [string, string, string][] = [
  ["essentials", "Essentials", "Tasks, registers, people, dashboard, two-factor login"],
  ["recommended", "Recommended", "Essentials plus Forms, Reports and the Staff app"],
  ["everything", "Everything", "Every module switched on"],
];

// cmeprojects: the first-time setup wizard for a new copy. One form, shown a
// step at a time, so nothing is lost moving between steps.
export function SetupWizard({ start, templates }: { start: Start; templates: Template[] }) {
  const [state, action, pending] = useActionState(finishSetup, null);
  const [step, setStep] = useState(0);
  const [company, setCompany] = useState(start.company);
  const [primary, setPrimary] = useState(start.primary);
  const [dark, setDark] = useState(start.dark);
  const [picked, setPicked] = useState<string[]>(templates.filter((t) => !t.added).map((t) => t.key));
  const [pkg, setPkg] = useState("recommended");
  const show = (i: number) => (step === i ? "flex" : "hidden");

  return (
    <form action={action} className="flex flex-col gap-5">
      <ol className="flex flex-wrap gap-2" aria-label="Setup steps">
        {STEPS.map((s, i) => (
          <li key={s}>
            <button
              type="button"
              onClick={() => setStep(i)}
              aria-current={step === i ? "step" : undefined}
              className={`flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm ${step === i ? "border-brand bg-brand text-brand-fg" : i < step ? "border-line bg-brand-soft" : "border-line text-muted"}`}
            >
              <span className="font-semibold tabular-nums">{i + 1}</span> {s}
            </button>
          </li>
        ))}
      </ol>

      <section className={`${show(0)} flex-col gap-4`} aria-label="Organisation">
        <Field label="Organisation name" htmlFor="company_name" hint="Shown in the menu, on the sign-in page and in emails.">
          <input id="company_name" name="company_name" required value={company} onChange={(e) => setCompany(e.target.value)} className={inputClass} />
        </Field>
        <Field label="Portal name" htmlFor="portal_name">
          <input id="portal_name" name="portal_name" defaultValue={start.portal} className={inputClass} />
        </Field>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="What do you call the people you support?" htmlFor="client_word" hint="For example Client, Participant or Resident.">
            <input id="client_word" name="client_word" defaultValue={start.clientWord} className={inputClass} />
          </Field>
          <Field label="State (time zone)" htmlFor="timezone">
            <select id="timezone" name="timezone" defaultValue={start.timezone} className={inputClass}>
              {ZONES.map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </Field>
        </div>
      </section>

      <section className={`${show(1)} flex-col gap-4`} aria-label="Look">
        <Field label="Logo (optional)" htmlFor="logo" hint="PNG or SVG with a see-through background works best. You can change it later.">
          <FileUpload id="logo" bucket="branding" folder="logo" name="logo" accept="image/png,image/jpeg,image/svg+xml,image/webp" maxMb={2} shrink={false} />
        </Field>
        <div className="flex flex-wrap gap-4">
          {(
            [
              ["color_primary", "Main colour", primary, setPrimary],
              ["color_dark", "Menu colour", dark, setDark],
            ] as const
          ).map(([name, label, value, set]) => (
            <label key={name} className="flex flex-col gap-1 text-sm font-medium">
              {label}
              <input type="color" name={name} value={value} onChange={(e) => set(e.target.value)} className="h-12 w-20 cursor-pointer rounded-md border border-field bg-surface p-1" />
            </label>
          ))}
          <label className="flex flex-col gap-1 text-sm font-medium">
            Accent colour
            <input type="color" name="color_accent" defaultValue={start.accent} className="h-12 w-20 cursor-pointer rounded-md border border-field bg-surface p-1" />
          </label>
        </div>
        <div className="flex max-w-sm overflow-hidden rounded-lg border border-line" aria-label="Preview">
          <div className="w-24 p-3 text-xs font-semibold text-white" style={{ background: dark }}>
            Menu
          </div>
          <div className="flex flex-1 flex-col gap-2 p-3">
            <p className="text-sm font-semibold">{company || "Your organisation"}</p>
            <span className="self-start rounded-md px-3 py-1.5 text-xs font-semibold text-white" style={{ background: primary }}>
              A button
            </span>
          </div>
        </div>
      </section>

      <section className={`${show(2)} flex-col gap-3`} aria-label="Registers">
        <p className="text-sm text-muted">Tick the registers to start with. General tasks is always there. You can add the others any time from Registers → From a template.</p>
        <div className="flex gap-3 text-sm">
          <button type="button" className="font-semibold text-brand underline" onClick={() => setPicked(templates.filter((t) => !t.added).map((t) => t.key))}>
            Tick all
          </button>
          <button type="button" className="font-semibold text-brand underline" onClick={() => setPicked([])}>
            Untick all
          </button>
        </div>
        <ul className="grid gap-2 sm:grid-cols-2">
          {templates.map((t) => (
            <li key={t.key}>
              <label className={`flex items-start gap-3 rounded-md border border-line p-3 ${t.added ? "opacity-60" : ""}`}>
                <input
                  type="checkbox"
                  name="templates"
                  value={t.key}
                  disabled={t.added}
                  checked={t.added || picked.includes(t.key)}
                  onChange={(e) => setPicked(e.target.checked ? [...picked, t.key] : picked.filter((k) => k !== t.key))}
                  className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]"
                />
                <span>
                  <span className="block text-sm font-semibold">
                    {t.name}
                    {t.added ? " (already added)" : ""}
                  </span>
                  <span className="block text-xs text-muted">{t.description}</span>
                </span>
              </label>
            </li>
          ))}
        </ul>
      </section>

      <section className={`${show(3)} flex-col gap-3`} aria-label="Package">
        <p className="text-sm text-muted">Which modules this organisation has. You can change any switch later in Settings → Features.</p>
        {PACKAGES.map(([value, label, hint]) => (
          <label key={value} className={`flex items-start gap-3 rounded-md border p-3 ${pkg === value ? "border-brand bg-brand-soft" : "border-line"}`}>
            <input type="radio" name="package" value={value} checked={pkg === value} onChange={() => setPkg(value)} className="mt-0.5 h-5 w-5 accent-[var(--brand-primary)]" />
            <span>
              <span className="block font-semibold">{label}</span>
              <span className="block text-sm text-muted">{hint}</span>
            </span>
          </label>
        ))}
      </section>

      <section className={`${show(4)} flex-col gap-2 text-sm`} aria-label="Finish">
        <p className="font-semibold">Ready to set up {company || "your organisation"}:</p>
        <ul className="list-disc pl-5 text-muted">
          <li>Name, look and time zone as chosen</li>
          <li>{picked.length} register{picked.length === 1 ? "" : "s"} from the templates, plus General tasks</li>
          <li>The {PACKAGES.find(([v]) => v === pkg)?.[1]} package</li>
        </ul>
        <p className="text-muted">These apply straight away. Next: invite people from People → Staff.</p>
      </section>

      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex flex-wrap gap-2">
        {step > 0 ? (
          <Button type="button" variant="outline" onClick={() => setStep(step - 1)}>
            Back
          </Button>
        ) : null}
        {step < STEPS.length - 1 ? (
          <Button type="button" onClick={() => setStep(step + 1)} disabled={step === 0 && !company.trim()}>
            Next
          </Button>
        ) : (
          <Button disabled={pending || !company.trim()}>{pending ? "Setting up…" : "Finish setup"}</Button>
        )}
      </div>
    </form>
  );
}
