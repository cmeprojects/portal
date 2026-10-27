// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, ROLES } from "@/lib/roles";
import { saveSetting, setFeature } from "./actions";

export function FeatureSwitch({ feature }: { feature: { key: string; label: string; description: string | null; enabled: boolean } }) {
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
        <p className="font-semibold">{feature.label}</p>
        {feature.description ? <p className="text-sm text-muted">{feature.description}</p> : null}
        {state?.error ? <p className="text-sm font-semibold text-danger">{state.error}</p> : null}
      </div>
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
    </form>
  );
}

export type SettingRow = { key: string; label: string; description: string | null; value: unknown };

export function kindOf(key: string): "color" | "number" | "roles" | "text" {
  if (key.startsWith("brand.color_")) return "color";
  if (key === "security.mfa_required_roles") return "roles";
  if (key.endsWith("_days") || key.endsWith("_years")) return "number";
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
        {kind === "roles" ? (
          <fieldset className="flex flex-wrap gap-x-5">
            <legend className="sr-only">{setting.label}</legend>
            {ROLES.filter((r) => r !== "system_admin").map((r) => (
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
