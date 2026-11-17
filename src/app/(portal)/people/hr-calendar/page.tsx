// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { requireSession } from "@/lib/session";
import { managesStaffFor, seesAllRequestsFor, seesComplianceFor } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { LEAVE_LABEL } from "@/lib/requests-shared";

export const metadata: Metadata = { title: "HR calendar" };

type Ev = { day: string; kind: "leave" | "expiry" | "leaving" | "anniversary" | "review"; who: string; text: string; href?: string };
const KIND: Record<Ev["kind"], [string, string]> = {
  leave: ["Leave", "bg-brand-soft text-ink"],
  expiry: ["Check expires", "bg-danger-soft text-danger"],
  leaving: ["Last day", "bg-warn-soft text-ink"],
  anniversary: ["Work anniversary", "bg-good-soft text-ink"],
  review: ["Review", "bg-yellow-soft text-ink"],
};

// cmeprojects (HR block step 4): one month of HR dates: leave, check
// expiries, last days, work anniversaries and reviews. Each kind shows only
// what this person may already see (the database decides).
export default async function HrCalendarPage({ searchParams }: PageProps<"/people/hr-calendar">) {
  const { profile } = await requireSession();
  const [staff, requests, compliance] = await Promise.all([managesStaffFor("view"), seesAllRequestsFor(), seesComplianceFor()]);
  if (!staff && !requests && !compliance && profile.role !== "team_leader") notFound();
  const sp = await searchParams;
  const now = new Date();
  const m = typeof sp.m === "string" && /^\d{4}-\d{2}$/.test(sp.m) ? sp.m : `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
  const [y, mo] = m.split("-").map(Number);
  const days = new Date(y, mo, 0).getDate();
  const first = `${m}-01`;
  const last = `${m}-${String(days).padStart(2, "0")}`;
  const shift = (n: number) => {
    const d = new Date(y, mo - 1 + n, 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  };
  const show = typeof sp.show === "string" && sp.show in KIND ? (sp.show as Ev["kind"]) : null;
  const supabase = await createClient();
  const [leave, expiries, leaving, starts, reviews] = await Promise.all([
    supabase.from("leave_periods").select("user_id, leave_type, start_date, end_date").lte("start_date", last).gte("end_date", first),
    compliance
      ? supabase.from("compliance_records").select("user_id, expires_on, status, compliance_items(title)").in("status", ["accepted", "done"]).gte("expires_on", first).lte("expires_on", last)
      : Promise.resolve({ data: [] }),
    supabase.from("offboardings").select("user_id, last_day").eq("status", "open").gte("last_day", first).lte("last_day", last),
    staff ? supabase.from("staff_private").select("user_id, start_date").not("start_date", "is", null) : Promise.resolve({ data: [] }),
    supabase.from("staff_reviews").select("user_id, kind, due_on").eq("status", "planned").gte("due_on", first).lte("due_on", last),
  ]);
  const evs: Ev[] = [];
  for (const l of (leave.data ?? []) as { user_id: string; leave_type: string; start_date: string; end_date: string }[]) {
    const from = l.start_date < first ? first : l.start_date;
    evs.push({ day: from, kind: "leave", who: l.user_id, text: `${LEAVE_LABEL[l.leave_type] ?? "Leave"} until ${l.end_date.slice(8)}/${l.end_date.slice(5, 7)}` });
  }
  for (const e of (expiries.data ?? []) as { user_id: string; expires_on: string; compliance_items: { title?: string } | { title?: string }[] | null }[]) {
    const item = Array.isArray(e.compliance_items) ? e.compliance_items[0] : e.compliance_items;
    evs.push({ day: e.expires_on, kind: "expiry", who: e.user_id, text: item?.title ?? "A check", href: `/compliance/people/${e.user_id}` });
  }
  for (const o of (leaving.data ?? []) as { user_id: string; last_day: string }[]) evs.push({ day: o.last_day, kind: "leaving", who: o.user_id, text: "Last day", href: `/settings/staff/${o.user_id}?tab=offboarding` });
  for (const s of (starts.data ?? []) as { user_id: string; start_date: string }[]) {
    const years = y - Number(s.start_date.slice(0, 4));
    if (years >= 1 && Number(s.start_date.slice(5, 7)) === mo) evs.push({ day: `${m}-${s.start_date.slice(8, 10)}`, kind: "anniversary", who: s.user_id, text: `${years} year${years === 1 ? "" : "s"}` });
  }
  for (const r of ((reviews.error ? [] : reviews.data) ?? []) as { user_id: string; kind: string; due_on: string }[])
    evs.push({ day: r.due_on, kind: "review", who: r.user_id, text: r.kind === "probation" ? "Probation review" : r.kind === "annual" ? "Annual review" : "Check-in", href: `/settings/staff/${r.user_id}?tab=performance` });
  const ids = [...new Set(evs.map((e) => e.who))];
  const { data: people } = ids.length ? await supabase.from("profiles").select("id, full_name, email, active").in("id", ids) : { data: [] };
  const name = new Map(((people ?? []) as { id: string; full_name: string | null; email: string; active: boolean }[]).filter((p) => p.active).map((p) => [p.id, p.full_name || p.email]));
  const list = evs.filter((e) => name.has(e.who) && (!show || e.kind === show)).sort((a, b) => a.day.localeCompare(b.day) || a.kind.localeCompare(b.kind));
  const byDay = new Map<string, Ev[]>();
  for (const e of list) byDay.set(e.day, [...(byDay.get(e.day) ?? []), e]);
  const monthName = new Date(y, mo - 1, 1).toLocaleDateString("en-AU", { month: "long", year: "numeric" });
  const q = (extra: Record<string, string>) => `?${new URLSearchParams({ m, ...(show ? { show } : {}), ...extra }).toString()}`;
  const today = new Date().toISOString().slice(0, 10);
  // Monday-first month grid.
  const lead = (new Date(y, mo - 1, 1).getDay() + 6) % 7;
  const cells = [...Array.from({ length: lead }, () => null), ...Array.from({ length: days }, (_, i) => `${m}-${String(i + 1).padStart(2, "0")}`)];

  return (
    <>
      <PageHeader title="HR calendar" intro="Leave, check expiries, last days, work anniversaries and reviews in one place." />
      <div className="flex flex-wrap items-center gap-2">
        <Link href={q({ m: shift(-1) })} aria-label="Previous month" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronLeft aria-hidden="true" className="size-4" />
        </Link>
        <span className="min-w-36 text-center font-semibold">{monthName}</span>
        <Link href={q({ m: shift(1) })} aria-label="Next month" className="rounded-lg border border-line p-2 hover:bg-page">
          <ChevronRight aria-hidden="true" className="size-4" />
        </Link>
        <span className="ml-auto flex flex-wrap gap-1">
          <Link href={`?m=${m}`} className={`rounded-full px-2.5 py-1 text-xs font-semibold ${!show ? "bg-brand text-brand-fg" : "bg-page ring-1 ring-line"}`}>
            Everything
          </Link>
          {(Object.keys(KIND) as Ev["kind"][]).map((k) => (
            <Link key={k} href={`?${new URLSearchParams({ m, show: k })}`} className={`rounded-full px-2.5 py-1 text-xs font-semibold ${show === k ? "bg-brand text-brand-fg" : "bg-page ring-1 ring-line"}`}>
              {KIND[k][0]}
            </Link>
          ))}
        </span>
      </div>
      <Card className="hidden p-2 md:block">
        <div className="grid grid-cols-7 gap-1 text-xs">
          {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
            <div key={d} className="px-1 py-1 font-semibold text-muted">
              {d}
            </div>
          ))}
          {cells.map((d, i) =>
            d ? (
              <div key={d} className={`min-h-24 rounded-md border p-1 ${d === today ? "border-brand" : "border-line"}`}>
                <div className="mb-1 font-semibold">{Number(d.slice(8))}</div>
                <ul className="flex flex-col gap-0.5">
                  {(byDay.get(d) ?? []).slice(0, 4).map((e, j) => (
                    <li key={j} title={`${KIND[e.kind][0]}: ${name.get(e.who)} · ${e.text}`} className={`truncate rounded px-1 ${KIND[e.kind][1]}`}>
                      {name.get(e.who)}
                    </li>
                  ))}
                  {(byDay.get(d)?.length ?? 0) > 4 ? <li className="text-muted">+{(byDay.get(d)?.length ?? 0) - 4} more</li> : null}
                </ul>
              </div>
            ) : (
              <div key={`b${i}`} />
            ),
          )}
        </div>
      </Card>
      <Card className="p-0">
        {list.length ? (
          <ul className="divide-y divide-line text-sm">
            {list.map((e, i) => (
              <li key={i} className="flex flex-wrap items-center gap-2 px-4 py-2">
                <span className="w-24 shrink-0 font-semibold">{new Date(`${e.day}T00:00:00`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short" })}</span>
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${KIND[e.kind][1]}`}>{KIND[e.kind][0]}</span>
                {e.href ? (
                  <Link href={e.href} className="font-medium hover:text-brand">
                    {name.get(e.who)}
                  </Link>
                ) : (
                  <span className="font-medium">{name.get(e.who)}</span>
                )}
                <span className="text-muted">{e.text}</span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="p-6 text-center text-sm text-muted">Nothing in {monthName}.</p>
        )}
      </Card>
    </>
  );
}
