// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
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
import { saveDelegation, saveSetting, setFeature } from "./actions";

export function FeatureSwitch({
  feature,
}: {
  feature: { key: string; label: string; description: string | null; enabled: boolean; premium?: boolean; included?: boolean };
}) {
  const locked = feature.included === false;
  const [state, action, pending] = useActionState(setFeature, null);
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
      <input type="hidden" name="enabled" value={feature.enabled ? "false" : "true"} />
      <div className="min-w-56 flex-1">
        <p className="flex flex-wrap items-center gap-2 font-semibold">
          {feature.label}
          {feature.premium ? (
            <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span>
          ) : null}
        </p>
        {feature.description ? <p className="text-sm text-muted">{feature.description}</p> : null}
        {locked ? <p className="text-sm font-semibold text-warn">Not included in your plan. Contact cmeproject to add it.</p> : null}
        {state?.error ? <p className="text-sm font-semibold text-danger">{state.error}</p> : null}
      </div>
      {locked ? (
        <span className="flex h-10 min-w-24 items-center justify-center gap-2 rounded-md border border-field bg-page px-4 text-sm font-semibold text-muted">
          Locked
        </span>
      ) : (
      <button
        role="switch"
        aria-checked={feature.enabled}
        aria-label={`${feature.label}: ${feature.enabled ? "on" : "off"}`}
        disabled={pending}
        className={`flex h-10 min-w-24 items-center justify-center gap-2 rounded-md px-4 text-sm font-semibold ${
          feature.enabled ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
        }`}
      >
        <span aria-hidden="true" className={`h-3 w-3 rounded-full ${feature.enabled ? "bg-brand-fg" : "bg-muted"}`} />
        {feature.enabled ? "On" : "Off"}
      </button>
      )}
    </form>
  );
}

export type SettingRow = { key: string; label: string; description: string | null; value: unknown };

// Text that can be left blank (to hide it).
const OPTIONAL_TEXT = ["brand.support_contact", "brand.announcement", "people.invite_message"];

export function kindOf(key: string): "color" | "number" | "roles" | "text" | "sla" | "yesno" | "choice" | "logo" | "note" {
  if (key === "tasks.sla_days") return "sla";
  if (key === "brand.logo_url" || key === "brand.logo_mark_url") return "logo";
  if (OPTIONAL_TEXT.includes(key)) return "note";
  if (key in CHOICES) return "choice";
  if (["security.mfa_required_roles", "people.invite_roles", "compliance.manager_roles", "people.scoreboard_roles", "reports.roles", "reports.compliance_roles", "tasks.registers_roles", "vehicles.manager_roles", "vehicles.report_roles"].includes(key)) return "roles";
  if (key.endsWith("_days") || key.endsWith("_years") || key.endsWith("_minutes") || key.endsWith("_hour")) return "number";
  if (key === "tasks.sla_weekdays_only" || key === "tasks.sla_manager_summary" || key.startsWith("people.")) return "yesno";
  if (key === "security.mfa_app_enabled" || key === "security.mfa_sms_enabled") return "yesno";
  if (key.startsWith("brand.color_")) return "color";
  return "text";
}

export function SettingForm({ setting }: { setting: SettingRow }) {
  const [state, action, pending] = useActionState(saveSetting, null);
  const kind = kindOf(setting.key);
  const id = `s-${setting.key}`;

  return (
    <form action={action} className="flex flex-col gap-2 border-t border-line py-4 first:border-t-0">
      <input type="hidden" name="key" value={setting.key} />
      <input type="hidden" name="kind" value={kind} />
      <label htmlFor={kind === "roles" ? undefined : id} className="font-semibold">
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
              {/* eslint-disable-next-line @next/next/no-img-element -- the company's own uploaded logo */}
              <img src={String(setting.value)} alt="Current logo" className="max-h-full max-w-full object-contain" />
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
  areas: { key: string; label: string }[];
  current: string[];
}) {
  const [state, action, pending] = useActionState(saveDelegation, null);
  return (
    <form action={action} className="flex flex-col gap-2 border-t border-line pt-4 first:border-t-0 first:pt-0">
      <input type="hidden" name="user_id" value={manager.id} />
      <fieldset className="flex flex-col gap-1">
        <legend className="mb-1 font-semibold">{manager.name}</legend>
        <div className="grid gap-x-5 sm:grid-cols-2">
          {areas.map((a) => (
            <label key={a.key} className="flex min-h-11 items-center gap-2 text-sm">
              <input type="checkbox" name="areas" value={a.key} defaultChecked={current.includes(a.key)} className="h-5 w-5 accent-[var(--brand-primary)]" />
              {a.label}
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
