// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, ROLES } from "@/lib/roles";
import { CHOICES } from "@/lib/setting-choices";
import { FileUpload } from "@/components/file-upload";
import { PRIORITIES, PRIORITY_LABELS } from "@/lib/tasks";

// Days per priority (blank = no default due date for that priority).
export function SlaInputs({ value, prefix = "sla_", placeholder }: { value?: Record<string, number> | null; prefix?: string; placeholder?: Record<string, number> }) {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {PRIORITIES.map((p) => (
        <label key={p} className="flex flex-col gap-1 text-xs font-medium">
          {PRIORITY_LABELS[p]} (days)
          <input
            type="number"
            name={`${prefix}${p}`}
            min={0}
            max={365}
            defaultValue={value?.[p] ?? ""}
            placeholder={placeholder?.[p] !== undefined ? String(placeholder[p]) : "None"}
            className={`${inputClass} w-28`}
          />
        </label>
      ))}
    </div>
  );
}
import { addAppIcon, chooseAppIcon, deleteAppIcon, saveDelegation, saveSetting, setFeature, type WhichApp } from "./actions";

export function FeatureSwitch({
  feature,
}: {
  feature: { key: string; label: string; description: string | null; enabled: boolean; premium?: boolean; included?: boolean };
}) {
  const [state, action, pending] = useActionState(setFeature, null);
  // A premium add-on that isn't in the plan counts as off.
  const on = feature.enabled && feature.included !== false;
  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (
          feature.key === "two_factor" &&
          feature.enabled &&
          !confirm("Turn off two-factor login for everyone, including system admins? Accounts will only be protected by passwords.")
        ) {
          e.preventDefault();
        }
      }}
      className="flex flex-wrap items-center justify-between gap-3 border-t border-line py-4 first:border-t-0"
    >
      <input type="hidden" name="key" value={feature.key} />
      <input type="hidden" name="enabled" value={on ? "false" : "true"} />
      <div className="min-w-56 flex-1">
        <p className="flex flex-wrap items-center gap-2 font-semibold">
          {feature.label}
          {feature.premium ? (
            <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span>
          ) : null}
        </p>
        {feature.description ? <p className="text-sm text-muted">{feature.description}</p> : null}
        {feature.premium ? (
          <p className="text-sm text-muted">Paid add-on: switch it on only for companies that have it in their plan. Off hides it everywhere; records are kept.</p>
        ) : null}
        {state?.error ? <p className="text-sm font-semibold text-danger">{state.error}</p> : null}
      </div>
      <button
        role="switch"
        aria-checked={on}
        aria-label={`${feature.label}: ${on ? "on" : "off"}`}
        disabled={pending}
        className={`flex h-10 min-w-24 items-center justify-center gap-2 rounded-md px-4 text-sm font-semibold ${
          on ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
        }`}
      >
        <span aria-hidden="true" className={`h-3 w-3 rounded-full ${on ? "bg-brand-fg" : "bg-muted"}`} />
        {on ? "On" : "Off"}
      </button>
    </form>
  );
}

export type SettingRow = { key: string; label: string; description: string | null; value: unknown };

// Text that can be left blank (to hide it).
const OPTIONAL_TEXT = ["brand.support_contact", "brand.announcement", "people.invite_message"];

export function kindOf(key: string): "color" | "number" | "roles" | "people" | "text" | "sla" | "yesno" | "choice" | "logo" | "note" {
  if (key === "tasks.sla_days") return "sla";
  if (key === "vehicles.weekly_recipients") return "people";
  if (key === "brand.logo_url" || key === "brand.logo_mark_url") return "logo";
  if (OPTIONAL_TEXT.includes(key)) return "note";
  if (key in CHOICES) return "choice";
  if (["security.mfa_required_roles", "people.invite_roles", "compliance.manager_roles", "people.scoreboard_roles", "reports.roles", "reports.compliance_roles", "tasks.registers_roles", "people.access_reset_roles", "vehicles.manager_roles", "vehicles.report_roles"].includes(key)) return "roles";
  if (key.endsWith("_days") || key.endsWith("_years") || key.endsWith("_minutes") || key.endsWith("_hour")) return "number";
  if (key === "tasks.sla_weekdays_only" || key === "tasks.sla_manager_summary" || key.startsWith("people.")) return "yesno";
  if (key === "staff_app.cars" || key === "vehicles.separate_app") return "yesno";
  if (key === "security.mfa_app_enabled" || key === "security.mfa_sms_enabled") return "yesno";
  if (key.startsWith("brand.color_")) return "color";
  return "text";
}

export function SettingForm({ setting, people = [] }: { setting: SettingRow; people?: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(saveSetting, null);
  const kind = kindOf(setting.key);
  const id = `s-${setting.key}`;

  return (
    <form action={action} className="flex flex-col gap-2 border-t border-line py-4 first:border-t-0">
      <input type="hidden" name="key" value={setting.key} />
      <input type="hidden" name="kind" value={kind} />
      <label htmlFor={kind === "roles" || kind === "people" ? undefined : id} className="font-semibold">
        {setting.label}
      </label>
      {setting.description ? <p className="-mt-1 text-sm text-muted">{setting.description}</p> : null}
      <div className="flex flex-wrap items-center gap-3">
        {kind === "sla" ? (
          <SlaInputs value={setting.value as Record<string, number>} />
        ) : kind === "yesno" ? (
          <label className="flex min-h-11 items-center gap-2 text-sm">
            <input type="checkbox" name="value" value="true" defaultChecked={setting.value === true} className="h-5 w-5 accent-[var(--brand-primary)]" />
            Yes
          </label>
        ) : kind === "people" ? (
          <fieldset className="flex flex-col">
            <legend className="sr-only">{setting.label}</legend>
            {people.length === 0 ? <p className="text-sm text-muted">There are no active managers yet.</p> : null}
            {people.map((p) => (
              <label key={p.id} className="flex min-h-11 items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  name="value"
                  value={p.id}
                  defaultChecked={Array.isArray(setting.value) && setting.value.includes(p.id)}
                  className="h-5 w-5 accent-[var(--brand-primary)]"
                />
                {p.name}
              </label>
            ))}
          </fieldset>
        ) : kind === "roles" ? (
          <fieldset className="flex flex-wrap gap-x-5">
            <legend className="sr-only">{setting.label}</legend>
            {ROLES.filter((r) => r !== "system_admin" && (r !== "new_starter" || setting.key.startsWith("security."))).map((r) => (
              <label key={r} className="flex min-h-11 items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  name="value"
                  value={r}
                  defaultChecked={Array.isArray(setting.value) && setting.value.includes(r)}
                  className="h-5 w-5 accent-[var(--brand-primary)]"
                />
                {ROLE_LABELS[r]}
              </label>
            ))}
          </fieldset>
        ) : kind === "choice" ? (
          <select id={id} name="value" defaultValue={String(setting.value)} className={`${inputClass} max-w-md`}>
            {CHOICES[setting.key].map((c) => (
              <option key={c.value} value={c.value}>
                {c.label}
              </option>
            ))}
          </select>
        ) : kind === "logo" ? (
          <div className="flex w-full flex-col gap-3 sm:flex-row sm:items-start">
            <span className="flex h-20 w-40 shrink-0 items-center justify-center rounded-md border border-line bg-white p-2">
              {setting.value ? (
                // eslint-disable-next-line @next/next/no-img-element -- the company's own uploaded logo
                <img src={String(setting.value)} alt="Current picture" className="max-h-full max-w-full object-contain" />
              ) : (
                <span className="text-xs text-muted">None yet</span>
              )}
            </span>
            <div className="min-w-0 flex-1">
              <FileUpload id={id} bucket="branding" folder="logo" name="logo" accept="image/png,image/jpeg,image/svg+xml,image/webp" maxMb={2} shrink={false} />
              <p className="mt-1 text-xs text-muted">
                {setting.key === "brand.logo_mark_url"
                  ? "A square version for the menu and phone icon. PNG or SVG with a see-through background works best."

                  : "PNG or SVG with a see-through background works best."}
              </p>
            </div>
          </div>
        ) : kind === "note" ? (
          <textarea id={id} name="value" rows={2} defaultValue={String(setting.value ?? "")} className={`${inputClass} max-w-xl min-h-20 py-3`} />
        ) : kind === "color" ? (
          <input id={id} name="value" type="color" defaultValue={String(setting.value)} className="h-12 w-20 cursor-pointer rounded-md border border-field bg-surface p-1" />
        ) : (
          <input
            id={id}
            name="value"
            type={kind === "number" ? "number" : "text"}
            defaultValue={String(setting.value)}
            className={`${inputClass} ${kind === "number" ? "max-w-32" : "max-w-md"}`}
          />
        )}
        <Button variant="outline" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <p className="text-sm font-semibold text-good">{state.message}</p> : null}
    </form>
  );
}

// One manager's delegated areas of System settings.
export function DelegationForm({
  manager,
  areas,
  current,
}: {
  manager: { id: string; name: string };
  areas: { key: string; label: string; hint?: string }[];
  current: string[];
}) {
  const [state, action, pending] = useActionState(saveDelegation, null);
  return (
    <form action={action} className="flex flex-col gap-2 border-t border-line pt-4 first:border-t-0 first:pt-0">
      <input type="hidden" name="user_id" value={manager.id} />
      <fieldset className="flex flex-col gap-1">
        <legend className="mb-1 font-semibold">{manager.name}</legend>
        <div className="grid gap-x-6 gap-y-3 sm:grid-cols-2">
          {areas.map((a) => (
            <label key={a.key} className="flex items-start gap-3 py-1 text-sm">
              <input type="checkbox" name="areas" value={a.key} defaultChecked={current.includes(a.key)} className="mt-0.5 h-5 w-5 shrink-0 accent-[var(--brand-primary)]" />
              <span>
                <span className="block font-medium">{a.label}</span>
                {a.hint ? <span className="block text-muted">{a.hint}</span> : null}
              </span>
            </label>
          ))}
        </div>
      </fieldset>
      <div className="flex flex-wrap items-center gap-3">
        <Button variant="outline" disabled={pending}>{pending ? "Saving…" : "Save"}</Button>
        {state?.error ? <span className="text-sm text-danger">{state.error}</span> : null}
        {state?.message ? <span className="text-sm text-good">{state.message}</span> : null}
      </div>
    </form>
  );
}

// cmeprojects: the Cars app icon. Tap one to use it; uploaded pictures stay as
// choices until deleted.
export function AppIconPicker({ setting, uploads, which = "cars" }: { setting: SettingRow; uploads: string[]; which?: WhichApp }) {
  const base = which === "staff" ? "/app" : "/cars-app";
  const router = useRouter();
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const [uploadKey, setUploadKey] = useState(0);
  const current = String(setting.value);
  const run = (task: () => Promise<{ error?: string; message?: string }>) =>
    start(async () => {
      const r = await task();
      setResult(r);
      if (!r.error) router.refresh();
    });
  const tiles = [
    { value: "car", label: which === "staff" ? "Checklist and initials" : "Car and initials" },
    { value: "mark", label: "Small logo" },
    { value: "logo", label: "Main logo" },
    ...uploads.map((u, i) => ({ value: u, label: `Your picture ${i + 1}` })),
  ];

  return (
    <div className="flex flex-col gap-3 border-t border-line py-4 first:border-t-0">
      <p className="font-semibold">{setting.label}</p>
      {setting.description ? <p className="-mt-2 text-sm text-muted">{setting.description}</p> : null}
      <ul className="grid grid-cols-3 gap-3 sm:grid-cols-4 lg:grid-cols-6">
        {tiles.map((t) => {
          const chosen = t.value === current;
          const uploaded = uploads.includes(t.value);
          return (
            <li key={t.value} className="relative">
              <button
                type="button"
                disabled={pending}
                aria-pressed={chosen}
                onClick={() => !chosen && run(() => chooseAppIcon(t.value, which))}
                className={`flex w-full flex-col items-center gap-2 rounded-lg border-2 p-3 text-xs font-semibold ${chosen ? "border-brand bg-brand-soft text-ink" : "border-line bg-surface text-muted hover:border-muted"}`}
              >
                {/* eslint-disable-next-line @next/next/no-img-element -- the icon as phones will show it */}
                <img src={`${base}/icon/192?as=${encodeURIComponent(t.value)}`} alt="" className="size-16 rounded-2xl shadow-sm" />
                <span className="text-center leading-tight">{chosen ? `${t.label} (in use)` : t.label}</span>
              </button>
              {uploaded ? (
                <button
                  type="button"
                  disabled={pending}
                  aria-label={`Delete ${t.label}`}
                  onClick={() => confirm(`Delete ${t.label}?`) && run(() => deleteAppIcon(t.value, which))}
                  className="absolute -top-2 -right-2 flex size-8 items-center justify-center rounded-full border border-line bg-surface text-danger shadow-sm hover:bg-danger-soft"
                >
                  ×
                </button>
              ) : null}
            </li>
          );
        })}
      </ul>
      <div className="max-w-md">
        <p className="mb-1 text-sm font-semibold">Upload a new icon</p>
        <FileUpload
          key={uploadKey}
          id={`app-icon-upload-${which}`}
          bucket="branding"
          folder="logo"
          name="icon"
          accept="image/png,image/jpeg,image/webp"
          maxMb={2}
          shrink={false}
          onUploaded={(path) =>
            run(async () => {
              const r = await addAppIcon(path, which);
              if (!r.error) setUploadKey((k) => k + 1);
              return r;
            })
          }
        />
        <p className="mt-1 text-xs text-muted">A square PNG, at least 512 × 512. It fills the icon, so leave a little space around the edges.</p>
      </div>
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message ? <p className="text-sm font-semibold text-good">{result.message}</p> : null}
    </div>
  );
}
