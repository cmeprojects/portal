// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { askConfirm, askDetails, confirmSubmit } from "@/components/confirm";
import { useActionState, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Notice, inputClass } from "@/components/ui";
import { ROLE_LABELS, ROLES } from "@/lib/roles";
import { CHOICES } from "@/lib/setting-choices";
import { FileUpload } from "@/components/file-upload";
import { PRIORITIES, PRIORITY_LABELS } from "@/lib/tasks";
import { useDirty } from "@/components/use-dirty";
import { useAfterSuccess } from "@/components/use-after-success";

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
import { addAppIcon, applyPreset, chooseAppIcon, deleteAppIcon, saveDelegationRule, saveNotifications, saveSetting, saveShares, setFeature, type WhichApp, runDemoAction, signOutEveryone } from "./actions";
import { FormPending } from "@/components/form-pending";

// cmeprojects: one feature switch. Pressing it saves a draft; it goes live on Deploy.
export function FeatureSwitch({
  feature,
  part = false,
  depth = 1,
}: {
  feature: { key: string; label: string; description: string | null; on: boolean; pending?: boolean; premium?: boolean };
  // A part of a feature (indented, smaller); depth 2 is a part of a part (cmeprojects).
  part?: boolean;
  depth?: number;
}) {
  const [state, action, pending] = useActionState(setFeature, null);
  const [, start] = useTransition();
  return (
    <form
      onSubmit={async (e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        if (
          feature.key === "two_factor" &&
          feature.on &&
          !(await askConfirm("Turn off two-factor login for everyone, including system admins? Accounts will only be protected by passwords.", { action: "Turn it off" }))
        ) {
          return;
        }
        start(() => action(data));
      }}
      className={`flex flex-wrap items-center justify-between gap-3 py-3 ${part ? (depth > 1 ? "pl-8 sm:pl-14" : "pl-4 sm:pl-8") : ""}`}
    >
      <input type="hidden" name="key" value={feature.key} />
      <input type="hidden" name="enabled" value={feature.on ? "false" : "true"} />
      <div className="min-w-48 flex-1">
        <p className={`flex flex-wrap items-center gap-2 ${part ? "text-sm font-semibold" : "font-semibold"}`}>
          {feature.label}
          {feature.premium ? <span className="rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Premium</span> : null}
          {feature.pending ? <NotLiveBadge /> : null}
        </p>
        {feature.description ? <p className="text-sm text-muted">{feature.description}</p> : null}
        {state?.error ? <p className="text-sm font-semibold text-danger">{state.error}</p> : null}
        {state?.message && !pending ? <p role="status" className="text-sm font-semibold text-good">✓ {state.message}</p> : null}
      </div>
      <button
        role="switch"
        aria-checked={feature.on}
        aria-label={`${feature.label}: ${feature.on ? "on" : "off"}`}
        disabled={pending}
        className={`flex h-10 min-w-24 items-center justify-center gap-2 rounded-md px-4 text-sm font-semibold ${
          feature.on ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
        }`}
      >
        <span aria-hidden="true" className={`h-3 w-3 rounded-full ${feature.on ? "bg-brand-fg" : "bg-muted"}`} />
        {feature.on ? "On" : "Off"}
      <FormPending /></button>
    </form>
  );
}

// ---------------------------------------------------------------------------
// Delegation: who looks after an area
// ---------------------------------------------------------------------------

export type DelegationMode = "admin" | "managers" | "selected";
export type DelegationValue = { mode: DelegationMode; people: string[] };
export type PersonChoice = { id: string; name: string; role: string };

// For "Setting up registers", the first choice means each register's own
// managers (the system admin always has full access) (cmeprojects).
const ADMIN_WORDS: Record<string, { option: string; who: string }> = {
  register_setup: { option: "Each register's own managers only", who: "each register's own managers" },
};

export function whoText(v: DelegationValue, choices: PersonChoice[], area?: string): string {
  if (v.mode === "managers") return area === "register_setup" ? "all managers (every register)" : "all managers";
  if (v.mode === "selected") {
    const names = v.people.map((id) => choices.find((c) => c.id === id)?.name).filter(Boolean) as string[];
    return names.length ? names.join(", ") : "chosen people";
  }
  return (area && ADMIN_WORDS[area]?.who) || "only you";
}

export function DelegationPicker({
  area,
  label,
  hint,
  value,
  pending: isDraft,
  choices,
  onSaved,
}: {
  area: string;
  label: string;
  hint?: string;
  value: DelegationValue;
  pending?: boolean;
  choices: PersonChoice[];
  onSaved?: () => void;
}) {
  const [state, action, pending] = useActionState(saveDelegationRule, null);
  const [, start] = useTransition();
  const [mode, setMode] = useState<DelegationMode>(value.mode);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, () => {
    markClean();
    onSaved?.();
  });
  const radio = (m: DelegationMode, text: string) => (
    <label className="flex min-h-10 items-center gap-2 text-sm">
      <input type="radio" name="mode" value={m} checked={mode === m} onChange={() => setMode(m)} className="h-5 w-5 accent-[var(--brand-primary)]" />
      {text}
    </label>
  );
  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        start(() => action(data));
      }}
      className="flex flex-col gap-2"
    >
      <input type="hidden" name="area" value={area} />
      <div>
        <p className="flex flex-wrap items-center gap-2 font-semibold">
          {label}
          {isDraft ? <NotLiveBadge /> : null}
        </p>
        {hint ? <p className="text-sm text-muted">{hint}</p> : null}
      </div>
      <fieldset className="flex flex-wrap gap-x-5">
        <legend className="sr-only">Who looks after it</legend>
        {radio("admin", ADMIN_WORDS[area]?.option ?? "Only me (system admin)")}
        {radio("managers", "All managers")}
        {radio("selected", "Selected people")}
      </fieldset>
      {mode === "selected" ? (
        <fieldset className="flex flex-col rounded-md border border-line px-3 py-1">
          <legend className="sr-only">Choose managers and staff admins</legend>
          {choices.length === 0 ? <p className="py-2 text-sm text-muted">There are no active managers or staff admins yet.</p> : null}
          {choices.map((c) => (
            <label key={c.id} className="flex min-h-10 items-center gap-2 text-sm">
              <input type="checkbox" name="people" value={c.id} defaultChecked={value.people.includes(c.id)} className="h-5 w-5 accent-[var(--brand-primary)]" />
              {c.name} <span className="text-muted">· {c.role}</span>
            </label>
          ))}
        </fieldset>
      ) : null}
      <div className="flex flex-wrap items-center gap-3">
        <Button size="sm" variant="outline" disabled={pending || !dirty}>{pending ? "Saving…" : "Save"}</Button>
      </div>
      <SaveResult state={state} pending={pending} dirty={dirty} />
    </form>
  );
}

// "Looked after by: … · Change" with a pop-up to change it, on a feature row.
export function LookedAfterBy(props: { area: string; label: string; hint?: string; value: DelegationValue; pending?: boolean; choices: PersonChoice[] }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="flex flex-wrap items-center gap-2 text-sm">
      <span className="text-muted">
        {props.label.split(" (")[0]}: looked after by <strong className="text-ink">{whoText(props.value, props.choices, props.area)}</strong>
      </span>
      {props.pending ? <NotLiveBadge /> : null}
      <button type="button" onClick={() => setOpen(true)} className="font-semibold text-brand underline">
        Change
      </button>
      {open ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center" onClick={() => setOpen(false)}>
          <div role="dialog" aria-modal="true" aria-label={`Who looks after ${props.label}`} className="flex w-full max-w-lg flex-col gap-3 rounded-xl border border-line bg-surface p-5 text-ink shadow-xl" onClick={(e) => e.stopPropagation()}>
            <DelegationPicker {...props} />
            <Button type="button" variant="outline" className="self-start" onClick={() => setOpen(false)}>
              Close
            </Button>
          </div>
        </div>
      ) : null}
    </div>
  );
}

// Package presets: one press sets the main switches (as drafts).
export function PresetButtons({ presets }: { presets: { key: string; label: string; hint: string }[] }) {
  const [state, action, pending] = useActionState(applyPreset, null);
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap gap-2">
        {presets.map((p) => (
          <form key={p.key} action={action}>
            <input type="hidden" name="preset" value={p.key} />
            <button
              disabled={pending}
              title={p.hint}
              className="flex min-h-11 flex-col items-start rounded-md border border-field bg-surface px-4 py-2 text-left text-sm hover:border-brand"
            >
              <span className="font-semibold">{p.label}</span>
              <span className="text-xs text-muted">{p.hint}</span>
            <FormPending /></button>
          </form>
        ))}
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message && !pending ? <p role="status" className="text-sm font-semibold text-good">✓ {state.message}</p> : null}
    </div>
  );
}

// One group on the Notifications tab: bell and email for each notification.
export function NotificationGroupForm({
  group,
  items,
}: {
  group: string;
  items: { code: string; label: string; channels: ("bell" | "email")[]; bell: boolean; email: boolean }[];
}) {
  const [state, action, pending] = useActionState(saveNotifications, null);
  const [, start] = useTransition();
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        start(() => action(data));
      }}
      className="flex flex-col gap-2"
    >
      <input type="hidden" name="group" value={group} />
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-xs text-muted uppercase">
            <th className="py-2 font-semibold">Notification</th>
            <th className="w-20 py-2 text-center font-semibold">Bell</th>
            <th className="w-20 py-2 text-center font-semibold">Email</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {items.map((i) => (
            <tr key={i.code}>
              <td className="py-2 pr-2">{i.label}</td>
              {(["bell", "email"] as const).map((c) => (
                <td key={c} className="py-2 text-center">
                  {i.channels.includes(c) ? (
                    <input
                      type="checkbox"
                      name={`${i.code}.${c}`}
                      defaultChecked={i[c]}
                      aria-label={`${i.label}: ${c}`}
                      className="h-5 w-5 accent-[var(--brand-primary)]"
                    />
                  ) : (
                    <span className="text-muted" aria-label="Not sent this way">–</span>
                  )}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      <div>
        <Button size="sm" variant="outline" disabled={pending || !dirty}>{pending ? "Saving…" : "Save"}</Button>
      </div>
      <SaveResult state={state} pending={pending} dirty={dirty} />
    </form>
  );
}

export type SettingRow = { key: string; label: string; description: string | null; value: unknown; pending?: boolean };

// Text that can be left blank (to hide it).
const OPTIONAL_TEXT = ["brand.support_contact", "brand.announcement", "people.invite_message", "website.closed_text"];

export type SettingKind = "color" | "number" | "roles" | "people" | "text" | "sla" | "yesno" | "choice" | "logo" | "note" | "longnote" | "dates" | "lines";

const LONG_TEXT = ["website.about_intro", "website.mission", "website.vision", "website.seo_description"];

export function kindOf(key: string): SettingKind {
  if (key === "tasks.public_holidays") return "dates";
  if (key === "website.services") return "lines";
  if (LONG_TEXT.includes(key)) return "longnote";
  if (key === "tasks.sla_days") return "sla";
  if (key === "vehicles.weekly_recipients") return "people";
  if (key === "brand.logo_url" || key === "brand.logo_mark_url" || key === "website.logo_url") return "logo";
  if (OPTIONAL_TEXT.includes(key)) return "note";
  if (key in CHOICES) return "choice";
  if (["security.mfa_required_roles", "people.invite_roles", "compliance.manager_roles", "compliance.clearance_roles", "people.scoreboard_roles", "reports.roles", "reports.compliance_roles", "tasks.registers_roles", "people.access_reset_roles", "vehicles.manager_roles", "vehicles.report_roles", "forms.maker_roles", "assistant.enquiry_roles", "assistant.intake_roles", "tasks.limited_roles"].includes(key)) return "roles";
  if (key.endsWith("_days") || key.endsWith("_years") || key.endsWith("_minutes") || key.endsWith("_hour")) return "number";
  if (key === "tasks.sla_weekdays_only" || key === "tasks.sla_manager_summary" || key.startsWith("people.")) return "yesno";
  if (key === "staff_app.cars" || key === "vehicles.separate_app" || key === "website.front_page" || key === "cars.cleared_only") return "yesno";
  if (key === "security.mfa_app_enabled" || key === "security.mfa_sms_enabled") return "yesno";
  if (key.startsWith("brand.color_")) return "color";
  return "text";
}

export function SettingForm({ setting, people = [] }: { setting: SettingRow; people?: { id: string; name: string }[] }) {
  const [state, action, pending] = useActionState(saveSetting, null);
  const [, start] = useTransition();
  const { ref, dirty, markClean, markDirty } = useDirty();
  const kind = kindOf(setting.key);
  const id = `s-${setting.key}`;
  useAfterSuccess(state, markClean);

  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        // Keep what's on screen (no automatic form reset after saving).
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        start(() => action(data));
      }}
      className="flex flex-col gap-2 border-t border-line py-4 first:border-t-0"
    >
      <input type="hidden" name="key" value={setting.key} />
      <input type="hidden" name="kind" value={kind} />
      <label htmlFor={kind === "roles" || kind === "people" ? undefined : id} className="flex flex-wrap items-center gap-2 font-semibold">
        {setting.label}
        {setting.pending ? <NotLiveBadge /> : null}
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
              <FileUpload id={id} bucket="branding" folder="logo" name="logo" accept="image/png,image/jpeg,image/svg+xml,image/webp" maxMb={2} shrink={false} onUploaded={markDirty} />
              <p className="mt-1 text-xs text-muted">
                {setting.key === "brand.logo_mark_url"
                  ? "A square version for the menu and phone icon. PNG or SVG with a see-through background works best."

                  : "PNG or SVG with a see-through background works best."}
              </p>
            </div>
          </div>
        ) : kind === "longnote" ? (
          <textarea id={id} name="value" rows={4} maxLength={2000} defaultValue={String(setting.value ?? "")} className={`${inputClass} max-w-xl min-h-28 py-3`} />
        ) : kind === "lines" ? (
          <textarea
            id={id}
            name="value"
            rows={5}
            defaultValue={Array.isArray(setting.value) ? (setting.value as string[]).join("\n") : ""}
            placeholder="One per line"
            className={`${inputClass} max-w-xl min-h-32 py-3`}
          />
        ) : kind === "dates" ? (
          <textarea
            id={id}
            name="value"
            rows={8}
            defaultValue={Array.isArray(setting.value) ? (setting.value as string[]).join("\n") : ""}
            placeholder="2026-12-25 Christmas Day"
            className={`${inputClass} max-w-xl min-h-40 py-3 font-mono text-sm`}
          />
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
        <Button variant="outline" disabled={pending || !dirty}>{pending ? "Saving…" : "Save"}</Button>
      </div>
      <SaveResult state={state} pending={pending} dirty={dirty} />
    </form>
  );
}

// cmeprojects: shown next to anything saved but not deployed yet.
export function NotLiveBadge() {
  return <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold text-ink">Not live yet</span>;
}

// The result of a Save: green when saved (until something changes again).
export function SaveResult({ state, pending, dirty }: { state: { error?: string; message?: string } | null; pending: boolean; dirty: boolean }) {
  if (pending) return null;
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message && !dirty) {
    return (
      <p role="status" className="text-sm font-semibold text-good">
        ✓ {state.message}
      </p>
    );
  }
  return null;
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
                  onClick={() => void askConfirm(`Delete ${t.label}?`, { action: "Delete" }).then((ok) => ok && run(() => deleteAppIcon(t.value, which)))}
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

// Demo data: load sample records for a demo, delete only those, or clear every task.
export function DemoDataPanel() {
  const [state, action, pending] = useActionState(runDemoAction, null);
  return (
    <div className="flex flex-col gap-4">
      <form action={action} className="flex flex-wrap items-center justify-between gap-3 border-b border-line pb-4">
        <input type="hidden" name="what" value="load" />
        <div className="min-w-56 flex-1">
          <p className="font-semibold">Load sample records</p>
          <p className="text-sm text-muted">12 tasks across the registers in different states, given to active staff in turn, and 3 website enquiries. No emails go out.</p>
        </div>
        <Button disabled={pending}>Load sample records</Button>
      </form>
      <form
        action={action}
        onSubmit={confirmSubmit("Delete the sample records? Real work isn't touched.", { action: "Delete sample records" })}
        className="flex flex-wrap items-center justify-between gap-3 border-b border-line pb-4"
      >
        <input type="hidden" name="what" value="clear" />
        <div className="min-w-56 flex-1">
          <p className="font-semibold">Delete sample records</p>
          <p className="text-sm text-muted">Only the records loaded here. Real work isn&apos;t touched.</p>
        </div>
        <Button variant="outline" disabled={pending}>
          Delete sample records
        </Button>
      </form>
      <form
        action={action}
        onSubmit={confirmSubmit("Delete every task, real and sample, with its history? This can't be undone.", { action: "Delete every task", typeWord: "DELETE" })}
        className="flex flex-wrap items-center justify-between gap-3"
      >
        <input type="hidden" name="what" value="clear-all" />
        <input type="hidden" name="confirm" value="DELETE" />
        <div className="min-w-56 flex-1">
          <p className="font-semibold text-danger">Delete every task</p>
          <p className="text-sm text-muted">All tasks, real and sample, with their history. This can&apos;t be undone.</p>
        </div>
        <Button variant="danger" disabled={pending}>
          Delete every task
        </Button>
      </form>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

// cmeprojects: the Security tab's "Sign everyone out", with a typed confirmation.
export function SignOutEveryone() {
  const [state, action, pending] = useActionState(signOutEveryone, null);
  const form = useRef<HTMLFormElement>(null);
  const secret = useRef<HTMLInputElement>(null);
  return (
    <form ref={form} action={action} className="flex flex-col gap-3">
      <input type="hidden" name="confirm" value="SIGN OUT" />
      <input ref={secret} type="hidden" name="secret" defaultValue="" />
      <Button
        type="button"
        variant="danger"
        className="self-start"
        disabled={pending}
        onClick={() =>
          void askDetails("Sign everyone out of every phone and computer, except you?", {
            action: "Sign everyone out",
            typeWord: "SIGN OUT",
            secretLabel: "Your password, or a 6-digit code from your authenticator app",
          }).then((r) => {
            if (!r || !secret.current) return;
            secret.current.value = r.secret;
            form.current?.requestSubmit();
            secret.current.value = "";
          })
        }
      >
        {pending ? "Signing out…" : "Sign everyone out"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}

// cmeprojects: a manager shares one of their areas with staff admins.
export function ShareAreaForm({ area, label, staff, current }: { area: string; label: string; staff: { id: string; name: string }[]; current: string[] }) {
  const [state, action, pending] = useActionState(saveShares, null);
  const [, start] = useTransition();
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        start(() => action(data));
      }}
      className="flex flex-col gap-2 border-t border-line py-3 first:border-t-0"
    >
      <input type="hidden" name="area" value={area} />
      <p className="font-semibold">{label}</p>
      <fieldset className="flex flex-wrap gap-x-5">
        <legend className="sr-only">Staff admins who also look after {label}</legend>
        {staff.map((p) => (
          <label key={p.id} className="flex min-h-10 items-center gap-2 text-sm">
            <input type="checkbox" name="people" value={p.id} defaultChecked={current.includes(p.id)} className="h-5 w-5 accent-[var(--brand-primary)]" />
            {p.name}
          </label>
        ))}
      </fieldset>
      <div>
        <Button size="sm" variant="outline" disabled={pending || !dirty}>{pending ? "Saving…" : "Save"}</Button>
      </div>
      <SaveResult state={state} pending={pending} dirty={dirty} />
    </form>
  );
}
