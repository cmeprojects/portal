// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Download } from "lucide-react";
import { getTimeZone } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { seesDownloads } from "@/lib/programs-access";
import { Card, EmptyState, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { FormPending } from "@/components/form-pending";
import { DateInput } from "@/components/date-input";

export const metadata: Metadata = { title: "Downloads" };

const PAGE = 100;
const one = (v: string | string[] | undefined) => (typeof v === "string" ? v : "");
const KIND: Record<string, string> = { export: "Export", document: "Document", record: "Staff record" };

// cmeprojects (update 154): the download trail. Who downloaded what, when, and
// the client or staff member it was about. Filter by person, kind and dates.
// Entries can't be changed or deleted.
export default async function DownloadsPage({ searchParams }: PageProps<"/system/downloads">) {
  return <DownloadTrail searchParams={searchParams} />;
}

// Also shown inside Portal settings (base = that page's address).
export async function DownloadTrail({ searchParams, base = "/system/downloads" }: { searchParams: PageProps<"/system/downloads">["searchParams"]; base?: string }) {
  if (!(await seesDownloads())) notFound();
  const link = (qs: string) => (qs ? `${base}${base.includes("?") ? "&" : "?"}${qs}` : base);
  const [basePath, baseQuery] = base.split("?");
  const params = await searchParams;
  const person = one(params.person);
  const kind = one(params.kind);
  const client = one(params.client);
  const from = one(params.from);
  const to = one(params.to);
  const q = one(params.q).trim();
  const before = Number(one(params.before)) || 0;

  const supabase = await createClient();
  let query = supabase.from("download_log").select("id, user_id, kind, action, outcome, label, client_id, person_id, details, created_at").order("id", { ascending: false }).limit(PAGE);
  if (before) query = query.lt("id", before);
  if (/^[0-9a-f-]{36}$/.test(person)) query = query.or(`user_id.eq.${person},person_id.eq.${person}`);
  if (/^[0-9a-f-]{36}$/.test(client)) query = query.eq("client_id", client);
  if (KIND[kind]) query = query.eq("kind", kind);
  if (/^\d{4}-\d{2}-\d{2}$/.test(from)) query = query.gte("created_at", `${from}T00:00:00+10:00`);
  if (/^\d{4}-\d{2}-\d{2}$/.test(to)) query = query.lte("created_at", `${to}T23:59:59+11:00`);
  if (q) query = query.ilike("label", `%${q.replace(/[%_,()]/g, " ")}%`);
  const [{ data, error }, { data: people }, timeZone] = await Promise.all([query, supabase.from("profiles").select("id, full_name, email").order("full_name"), getTimeZone()]);
  type Row = { id: number; user_id: string; kind: string; action: string; outcome: string; label: string; client_id: string | null; person_id: string | null; details: Record<string, unknown>; created_at: string };
  const rows = (data ?? []) as Row[];
  const clientIds = [...new Set(rows.map((r) => r.client_id).filter(Boolean))] as string[];
  const { data: clientRows } = clientIds.length ? await supabase.from("car_clients").select("id, name").in("id", clientIds) : { data: [] };
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const clientName = new Map((clientRows ?? []).map((c) => [c.id, c.name as string]));
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });
  const keep = new URLSearchParams(Object.entries({ person, kind, client, from, to, q }).filter(([, v]) => v));
  const older = rows.length === PAGE ? rows[rows.length - 1].id : 0;

  return (
    <>
      <PageHeader title="Downloads" intro="Who exported what, and who was given a download link for client documents and staff records (a link shows the file was handed over, not that it was saved). Refused attempts show as Denied. It can't be edited or deleted." />
      {error ? <p className="rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-900">The download trail isn&apos;t set up yet (update 154).</p> : null}
      <form method="get" action={basePath} className="grid gap-2 sm:grid-cols-2 lg:grid-cols-[1.4fr_1fr_1fr_9rem_9rem_auto]" role="search">
        {[...new URLSearchParams(baseQuery ?? "").entries()].map(([k, v]) => (
          <input key={k} type="hidden" name={k} value={v} />
        ))}
        {client ? <input type="hidden" name="client" value={client} /> : null}
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Search
          <input name="q" defaultValue={q} placeholder="For example: roster, care plan" className={inputClass} />
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
          Kind
          <select name="kind" defaultValue={kind} className={inputClass}>
            <option value="">All</option>
            {Object.entries(KIND).map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          From
          <DateInput name="from" defaultValue={from} className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          To
          <DateInput name="to" defaultValue={to} className={inputClass} />
        </label>
        <div className="flex items-end gap-2">
          <button className={buttonClass("primary", "h-11")}>
            Filter
            <FormPending />
          </button>
          {keep.toString() ? (
            <Link href={link("")} className={buttonClass("outline", "h-11")}>
              Clear
            </Link>
          ) : null}
        </div>
      </form>
      {client ? (
        <p className="text-sm text-muted">
          Showing downloads about <span className="font-semibold text-ink">{clientName.get(client) ?? "this client"}</span>.
        </p>
      ) : null}
      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <EmptyState icon={Download} title="Nothing found" text={keep.toString() ? "Try a different filter." : "Nothing has been downloaded yet."} />
        ) : (
          <ol className="divide-y divide-line">
            {rows.map((r) => (
              <li key={r.id} className="flex flex-wrap items-start gap-x-6 gap-y-1 px-5 py-3">
                <div className="min-w-0 flex-1 basis-80 text-sm">
                  <p>
                    <Link href={link(`person=${r.user_id}`)} className="font-semibold hover:underline">
                      {nameOf.get(r.user_id) ?? "Someone"}
                    </Link>{" "}
                    {r.action === "export" ? "exported" : r.action === "download_denied" ? "was refused" : "was given a download link for"} {r.label.replace(/^Refused: /, "")}
                    {typeof r.details?.rows === "number" ? ` (${r.details.rows} rows)` : ""}
                  </p>
                  <p className="mt-1 flex flex-wrap gap-3 text-xs text-muted">
                    <span className="rounded-full bg-page px-2 py-0.5 ring-1 ring-line">{KIND[r.kind] ?? r.kind}</span>
                    {r.outcome !== "success" ? <span className="rounded-full bg-red-50 px-2 py-0.5 font-semibold text-red-800 ring-1 ring-red-200">Denied</span> : null}
                    {r.client_id ? (
                      <>
                        <Link href={`/settings/clients/${r.client_id}`} className="font-semibold text-brand hover:underline">
                          {clientName.get(r.client_id) ?? "Client"}
                        </Link>
                        <Link href={link(`client=${r.client_id}`)} className="font-semibold text-brand hover:underline">
                          All downloads about this client
                        </Link>
                      </>
                    ) : null}
                    {r.person_id ? (
                      <Link href={link(`person=${r.person_id}`)} className="font-semibold text-brand hover:underline">
                        About {nameOf.get(r.person_id) ?? "a staff member"}
                      </Link>
                    ) : null}
                  </p>
                </div>
                <time dateTime={r.created_at} className="text-sm whitespace-nowrap text-muted">
                  {when.format(new Date(r.created_at))}
                </time>
              </li>
            ))}
          </ol>
        )}
      </Card>
      {older ? (
        <Link href={link(new URLSearchParams([...keep.entries(), ["before", String(older)]]).toString())} className={buttonClass("outline", "self-start")}>
          Older downloads
        </Link>
      ) : null}
    </>
  );
}
