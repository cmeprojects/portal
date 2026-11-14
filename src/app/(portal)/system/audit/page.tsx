// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { ExternalLink, History } from "lucide-react";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas, getTimeZone } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { KIND_LABEL, describeAudit, type AuditRow, type Kind } from "@/lib/audit-describe";

export const metadata: Metadata = { title: "Change log" };

const PAGE = 100;
const one = (v: string | string[] | undefined) => (typeof v === "string" ? v : "");

// cmeprojects: the change log, in plain sentences that say exactly what
// happened, to whom and to what, with a link to open it. Filter by person
// (who did it or who it was about), kind of change, dates and words. The log
// itself can't be edited or deleted.
export default async function AuditPage({ searchParams }: PageProps<"/system/audit">) {
  return <ChangeLog searchParams={searchParams} />;
}

// cmeprojects: also shown inside Portal settings (base = that page's address).
export async function ChangeLog({ searchParams, base = "/system/audit" }: { searchParams: PageProps<"/system/audit">["searchParams"]; base?: string }) {
  const link = (qs: string) => (qs ? `${base}${base.includes("?") ? "&" : "?"}${qs}` : base);
  const [basePath, baseQuery] = base.split("?");
  const { profile } = await requireSession();
  if (!(await getMyAdminAreas(profile.role)).includes("audit")) redirect("/");
  const params = await searchParams;
  const person = one(params.person);
  const kind = one(params.kind) as Kind | "";
  const from = one(params.from);
  const to = one(params.to);
  const q = one(params.q).trim().toLowerCase();
  const before = Number(one(params.before)) || 0;

  const supabase = await createClient();
  let query = supabase.from("audit_log").select("id, actor_id, action, entity, entity_id, details, created_at").order("id", { ascending: false }).limit(q || kind ? 600 : PAGE);
  if (before) query = query.lt("id", before);
  if (/^\d{4}-\d{2}-\d{2}$/.test(from)) query = query.gte("created_at", `${from}T00:00:00+10:00`);
  if (/^\d{4}-\d{2}-\d{2}$/.test(to)) query = query.lte("created_at", `${to}T23:59:59+11:00`);
  if (/^[0-9a-f-]{36}$/.test(person)) query = query.or(`actor_id.eq.${person},entity_id.eq.${person}`);
  const [{ data }, { data: people }, timeZone] = await Promise.all([
    query,
    supabase.from("profiles").select("id, full_name, email").order("full_name"),
    getTimeZone(),
  ]);
  const rows = (data ?? []) as AuditRow[];
  let items = await describeAudit(rows);
  if (kind) items = items.filter((i) => i.kind === kind);
  if (q) items = items.filter((i) => `${i.actor} ${i.text} ${i.note ?? ""}`.toLowerCase().includes(q));
  items = items.slice(0, PAGE);
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });
  const older = rows.length && !q && !kind ? rows[rows.length - 1].id : 0;
  const keep = new URLSearchParams(Object.entries({ person, kind, from, to, q: one(params.q) }).filter(([, v]) => v));

  return (
    <>
      <PageHeader title="Change log" intro="Every change to people, onboarding, access and settings: who did what, to whom and to what. It can't be edited or deleted." />
      <form method="get" action={basePath} className="grid gap-2 sm:grid-cols-2 lg:grid-cols-[1.4fr_1fr_1fr_9rem_9rem_auto]" role="search">
        {[...new URLSearchParams(baseQuery ?? "").entries()].map(([k, v]) => (
          <input key={k} type="hidden" name={k} value={v} />
        ))}
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Search
          <input name="q" defaultValue={one(params.q)} placeholder="For example: First Aid, Sam, role" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Person
          <select name="person" defaultValue={person} className={inputClass}>
            <option value="">Anyone</option>
            {(people ?? []).map((p) => (
              <option key={p.id} value={p.id}>
                {p.full_name || p.email}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Kind of change
          <select name="kind" defaultValue={kind} className={inputClass}>
            <option value="">All</option>
            {(Object.keys(KIND_LABEL) as Kind[]).map((k) => (
              <option key={k} value={k}>
                {KIND_LABEL[k]}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          From
          <input type="date" name="from" defaultValue={from} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          To
          <input type="date" name="to" defaultValue={to} className={inputClass} />
        </label>
        <div className="flex items-end gap-2">
          <button className={buttonClass("primary", "h-11")}>Filter</button>
          {keep.toString() ? (
            <Link href={link("")} className={buttonClass("outline", "h-11")}>
              Clear
            </Link>
          ) : null}
        </div>
      </form>
      <Card className="overflow-hidden">
        {items.length === 0 ? (
          <EmptyState icon={History} title="Nothing found" text={keep.toString() ? "Try a different filter." : "Nothing has changed yet."} />
        ) : (
          <ol className="divide-y divide-line">
            {items.map((i) => (
              <li key={i.id} className="flex flex-wrap items-start gap-x-6 gap-y-1 px-5 py-3">
                <div className="min-w-0 flex-1 basis-80 text-sm">
                  <p>
                    {i.actorId ? (
                      <Link href={link(`person=${i.actorId}`)} className="font-semibold hover:underline">
                        {i.actor}
                      </Link>
                    ) : (
                      <span className="font-semibold">{i.actor}</span>
                    )}{" "}
                    {i.text}
                  </p>
                  {i.note ? <p className="mt-0.5 text-muted">“{i.note}”</p> : null}
                  <p className="mt-1 flex flex-wrap gap-3 text-xs text-muted">
                    <span className="rounded-full bg-page px-2 py-0.5 ring-1 ring-line">{KIND_LABEL[i.kind]}</span>
                    {i.href ? (
                      <Link href={i.href} className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
                        Open <ExternalLink aria-hidden="true" className="size-3" />
                      </Link>
                    ) : null}
                    {i.subjectId ? (
                      <Link href={link(`person=${i.subjectId}`)} className="font-semibold text-brand hover:underline">
                        Everything about this person
                      </Link>
                    ) : null}
                  </p>
                </div>
                <time dateTime={i.at} className="text-sm whitespace-nowrap text-muted">
                  {when.format(new Date(i.at))}
                </time>
              </li>
            ))}
          </ol>
        )}
      </Card>
      {older ? (
        <Link href={link(new URLSearchParams([...keep.entries(), ["before", String(older)]]).toString())} className={buttonClass("outline", "self-start")}>
          Older changes
        </Link>
      ) : null}
    </>
  );
}
