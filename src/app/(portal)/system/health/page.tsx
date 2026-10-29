// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { BUCKET_LABELS, LIMITS, bytes, meter, type Plan } from "@/lib/health";
import { Card, PageHeader } from "@/components/ui";
import { SectionTabs } from "@/components/section-tabs";
import { SettingForm, type SettingRow } from "../forms";

export const metadata: Metadata = { title: "System health" };

type Health = {
  database_bytes: number;
  files: { bucket: string; files: number; bytes: number }[];
  people_active: number;
  people_total: number;
  tasks_open: number;
  tasks_total: number;
  trips_total: number;
  cars_active: number;
  emails_waiting: number;
  emails_failed: number;
  emails_sent_week: number;
  oldest_waiting: string | null;
  last_error: string | null;
  timer: { ran_at: string; ok: boolean; detail: string } | null;
};

type Check = { label: string; state: "good" | "warn" | "bad"; text: string };

const BAR = { ok: "bg-good", warn: "bg-warn", full: "bg-danger" } as const;
const DOT = { good: "bg-good", warn: "bg-warn", bad: "bg-danger" } as const;
const WORD = { good: "OK", warn: "Check", bad: "Needs fixing" } as const;

// cmeprojects: is everything working, and how full is it? System admin only.
export default async function SystemHealthPage() {
  const { profile, features } = await requireSession();
  if (profile.role !== "system_admin") redirect("/");
  const supabase = await createClient();
  const [{ data, error }, { data: planRow }, timeZone] = await Promise.all([
    supabase.rpc("system_health"),
    supabase.from("app_settings").select("key, label, description, value").eq("key", "system.hosting_plan").maybeSingle(),
    getTimeZone(),
  ]);
  if (error || !data) {
    return (
      <>
        <SectionTabs section="settings" current="/system/health" />
        <PageHeader title="System health" />
        <Card className="p-5 text-sm">System health isn&apos;t available yet. Run the latest database update (update 19), then refresh this page.</Card>
      </>
    );
  }
  const h = data as Health;
  const plan: Plan = planRow?.value === "pro" ? "pro" : "free";
  const fileBytes = h.files.reduce((s, f) => s + Number(f.bytes), 0);
  const fileCount = h.files.reduce((s, f) => s + Number(f.files), 0);
  const meters = [
    meter("database", "Database", Number(h.database_bytes), LIMITS.database[plan], "Tasks, people, trips and everything else (text is small)."),
    meter("files", "File storage", fileBytes, LIMITS.files[plan], `${fileCount.toLocaleString("en-AU")} files: documents, photos and logos.`),
  ];
  const worst = meters.some((m) => m.level === "full") ? "full" : meters.some((m) => m.level === "warn") ? "warn" : "ok";
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });
  const minutesAgo = h.timer ? Math.round((new Date().getTime() - new Date(h.timer.ran_at).getTime()) / 60000) : null;
  const site = process.env.NEXT_PUBLIC_SITE_URL ?? "";

  const checks: Check[] = [
    !h.timer
      ? { label: "Hourly timer", state: "bad", text: "Hasn't run yet. Reminders, overdue alerts and the weekly reports won't go out until it does." }
      : !h.timer.ok
        ? { label: "Hourly timer", state: "bad", text: `Last run on ${when.format(new Date(h.timer.ran_at))} had a problem: ${h.timer.detail || "unknown"}.` }
        : minutesAgo! > 130
          ? { label: "Hourly timer", state: "warn", text: `Last ran ${when.format(new Date(h.timer.ran_at))}. It should run every hour.` }
          : { label: "Hourly timer", state: "good", text: `Ran ${minutesAgo! < 2 ? "just now" : `${minutesAgo} minutes ago`}. Reminders and alerts are going out.` },
    !process.env.RESEND_API_KEY
      ? { label: "Emails", state: "warn", text: `Not set up yet (Resend), so nothing is emailed; the bell still works. ${h.emails_waiting} waiting.` }
      : h.emails_failed > 0
        ? { label: "Emails", state: "bad", text: `${h.emails_failed} couldn't be sent${h.last_error ? ` (${h.last_error})` : ""}. ${h.emails_sent_week} sent in the last 7 days.` }
        : { label: "Emails", state: h.emails_waiting > 20 ? "warn" : "good", text: `${h.emails_sent_week} sent in the last 7 days, ${h.emails_waiting} waiting.` },
    features.two_factor === false
      ? { label: "Two-factor login", state: "bad", text: "Switched off: nobody is asked for a code. Turn it on under System settings → Features." }
      : { label: "Two-factor login", state: "good", text: "On." },
    !site.startsWith("https://")
      ? { label: "Portal address", state: "warn", text: "The portal's address isn't set to an https:// address, so links in emails may not work." }
      : { label: "Portal address", state: "good", text: site },
    !process.env.CRON_SECRET || process.env.CRON_SECRET.length < 32
      ? { label: "Timer password", state: "bad", text: "CRON_SECRET isn't set (or is too short) on Vercel, so the hourly timer is refused." }
      : { label: "Timer password", state: "good", text: "Set." },
  ];

  return (
    <>
      <SectionTabs section="settings" current="/system/health" />
      <PageHeader title="System health" intro="Is everything working, and how full is it? Only system admins see this page." />

      <Card className="overflow-hidden">
        <h2 className="heading-sm border-b border-line px-5 py-3">Checks</h2>
        <ul className="divide-y divide-line">
          {checks.map((c) => (
            <li key={c.label} className="flex items-start gap-3 px-5 py-3">
              <span aria-hidden="true" className={`mt-1.5 size-2.5 shrink-0 rounded-full ${DOT[c.state]}`} />
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-semibold">
                  {c.label} <span className={`ml-1 text-xs font-semibold ${c.state === "good" ? "text-good" : c.state === "warn" ? "text-warn" : "text-danger"}`}>{WORD[c.state]}</span>
                </span>
                <span className="block text-sm break-words text-muted">{c.text}</span>
              </span>
            </li>
          ))}
        </ul>
      </Card>

      <Card className="flex flex-col gap-4 p-5">
        <div>
          <h2 className="heading-sm">Capacity</h2>
          <p className="text-sm text-muted">Yellow from 75% full, red from 90%, long before anything stops working.</p>
        </div>
        {worst !== "ok" ? (
          <p className={`rounded-md px-3 py-2 text-sm ${worst === "full" ? "bg-danger-soft text-danger" : "bg-warn-soft text-warn"}`}>
            Something is {worst === "full" ? "nearly full" : "getting full"}. Move to Supabase Pro (or a bigger plan), then change the plan below.
          </p>
        ) : null}
        <ul className="flex flex-col gap-4">
          {meters.map((m) => (
            <li key={m.key} className="flex flex-col gap-1.5">
              <div className="flex flex-wrap items-baseline justify-between gap-2">
                <span className="font-semibold">{m.label}</span>
                <span className="text-sm text-muted tabular-nums">
                  {bytes(m.used)} of {bytes(m.limit)} · {m.pct < 1 ? "under 1" : Math.round(m.pct)}%
                </span>
              </div>
              <div className="h-2.5 overflow-hidden rounded-full bg-page" role="meter" aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(m.pct)} aria-label={`${m.label}: ${Math.round(m.pct)}% full`}>
                <div className={`h-full rounded-full ${BAR[m.level]}`} style={{ width: `${Math.max(m.pct, 1)}%` }} />
              </div>
              <span className="text-xs text-muted">{m.note}</span>
            </li>
          ))}
        </ul>
        {h.files.length ? (
          <details className="text-sm">
            <summary className="cursor-pointer font-semibold text-brand">What the files are</summary>
            <ul className="mt-2 divide-y divide-line rounded-md border border-line">
              {h.files.map((f) => (
                <li key={f.bucket} className="flex justify-between gap-3 px-3 py-2">
                  <span>{BUCKET_LABELS[f.bucket] ?? f.bucket}</span>
                  <span className="text-muted tabular-nums">
                    {Number(f.files).toLocaleString("en-AU")} files · {bytes(Number(f.bytes))}
                  </span>
                </li>
              ))}
            </ul>
          </details>
        ) : null}
        {planRow ? (
          <div className="border-t border-line pt-1">
            <SettingForm setting={planRow as SettingRow} />
          </div>
        ) : null}
      </Card>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[
          { label: "Active staff", n: h.people_active },
          { label: "Open tasks", n: h.tasks_open },
          { label: "Tasks ever", n: h.tasks_total },
          { label: "Car trips", n: h.trips_total },
        ].map((s) => (
          <Card key={s.label} className="p-4">
            <p className="heading text-brand tabular-nums">{Number(s.n).toLocaleString("en-AU")}</p>
            <p className="text-sm text-muted">{s.label}</p>
          </Card>
        ))}
      </div>
    </>
  );
}
