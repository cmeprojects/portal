// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getPeopleRules, getTimeZone, seesCompliance } from "@/lib/settings";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { todayIn } from "@/lib/tasks";

export const metadata: Metadata = { title: "Expiry list" };

type Row = { key: string; person: string; personId: string; what: string; expires: string; days: number; status: string; href: string };

// cmeprojects Phase 3: everything with an expiry date, soonest first: expired,
// due today, and coming up in the chosen window. Documents for the people who
// manage onboarding; visas only for people with Identity and work rights
// access (the database decides what each person sees).
export default async function ExpiryPage({ searchParams }: PageProps<"/compliance/expiry">) {
  const { profile } = await requireSession();
  const rules = await getPeopleRules();
  if (!seesCompliance(profile.role, rules)) redirect("/");
  const window = [30, 60, 90].includes(Number((await searchParams).days)) ? Number((await searchParams).days) : 60;
  const supabase = await createClient();
  const today = todayIn(await getTimeZone());
  const until = new Date(Date.parse(`${today}T00:00:00Z`) + window * 86_400_000).toISOString().slice(0, 10);

  const [{ data: recs }, { data: visas }, { data: people }] = await Promise.all([
    supabase
      .from("compliance_records")
      .select("id, user_id, item_id, status, expires_on, created_at, compliance_items(title, active)")
      .not("expires_on", "is", null)
      .lte("expires_on", until)
      .in("status", ["submitted", "accepted"])
      .order("created_at", { ascending: false })
      .limit(2000),
    supabase.from("staff_work_rights").select("user_id, visa_expiry, verified_at").eq("status", "visa").not("visa_expiry", "is", null).lte("visa_expiry", until),
    supabase.from("profiles").select("id, full_name, email, active"),
  ]);
  const who = new Map((people ?? []).filter((p) => p.active).map((p) => [p.id, p.full_name || p.email]));
  const daysTo = (d: string) => Math.round((Date.parse(`${d}T00:00:00Z`) - Date.parse(`${today}T00:00:00Z`)) / 86_400_000);
  const label = (days: number) => (days < 0 ? `Expired ${-days} day${days === -1 ? "" : "s"} ago` : days === 0 ? "Expires today" : `In ${days} day${days === 1 ? "" : "s"}`);

  // The latest record of each item per person (newer uploads replace older ones).
  const seen = new Set<string>();
  const rows: Row[] = [];
  for (const r of recs ?? []) {
    const k = `${r.user_id}:${r.item_id}`;
    if (seen.has(k) || !who.has(r.user_id)) continue;
    seen.add(k);
    const item = (Array.isArray(r.compliance_items) ? r.compliance_items[0] : r.compliance_items) as { title: string; active: boolean } | null;
    if (!item?.active) continue;
    const days = daysTo(r.expires_on as string);
    rows.push({
      key: `r${r.id}`,
      person: who.get(r.user_id) ?? "Someone",
      personId: r.user_id,
      what: item.title,
      expires: r.expires_on as string,
      days,
      status: r.status === "submitted" ? "Waiting to be checked" : days < 0 ? "Needs renewal" : "Renewal coming up",
      href: `/compliance/people/${r.user_id}`,
    });
  }
  for (const v of visas ?? []) {
    if (!who.has(v.user_id)) continue;
    const days = daysTo(v.visa_expiry as string);
    rows.push({
      key: `v${v.user_id}`,
      person: who.get(v.user_id) ?? "Someone",
      personId: v.user_id,
      what: "Visa (work rights)",
      expires: v.visa_expiry as string,
      days,
      status: v.verified_at ? (days < 0 ? "Needs renewal" : "Renewal coming up") : "Waiting to be checked",
      href: `/people?p=${v.user_id}`,
    });
  }
  rows.sort((a, b) => a.days - b.days || a.person.localeCompare(b.person));
  const expired = rows.filter((r) => r.days < 0).length;
  const fmt = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });

  return (
    <>
      <PageHeader title="Expiry list" intro="Certificates, checks, licences and visas that have expired or expire soon. Reminders go out 60, 30 and 7 days before, and on the day." />
      <div className="flex flex-wrap items-center gap-2">
        <Link href="/compliance" className="text-sm font-semibold text-brand underline">
          Back to Onboarding
        </Link>
        <span className="flex-1" />
        {[30, 60, 90].map((d) => (
          <Link key={d} href={`/compliance/expiry?days=${d}`} className={buttonClass(d === window ? "primary" : "outline", "", "sm")} aria-current={d === window ? "page" : undefined}>
            Next {d} days
          </Link>
        ))}
      </div>
      <p className="text-sm text-muted" role="status">
        {rows.length} item{rows.length === 1 ? "" : "s"}
        {expired ? `, ${expired} expired` : ""}.
      </p>
      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <p className="px-5 py-6 text-sm text-muted">Nothing has expired or expires in the next {window} days.</p>
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((r) => (
              <li key={r.key}>
                <Link href={r.href} className="grid gap-1 px-5 py-3 hover:bg-page sm:grid-cols-[1fr_1fr_9rem_10rem] sm:items-center">
                  <span className="font-semibold">{r.person}</span>
                  <span>{r.what}</span>
                  <span className="text-sm text-muted">{fmt(r.expires)}</span>
                  <span className="flex flex-col text-sm">
                    <span className={`font-semibold ${r.days < 0 ? "text-danger" : r.days <= 7 ? "text-warn" : ""}`}>{label(r.days)}</span>
                    <span className="text-xs text-muted">{r.status}</span>
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </>
  );
}
