// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import Link from "next/link";
import { ChevronDown, History } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { Card, EmptyState } from "@/components/ui";
import { ROLE_LABELS, isRole } from "@/lib/roles";

// cmeprojects (update 155): a client's Activity and audit trail, in their
// profile. One timeline from what the portal already records: the change log
// (written by the database whenever a client record changes), download links
// and exports (update 154), and page openings. The database decides what each
// person may see; before and after values come back for the system admin
// only. Opening this tab is itself recorded.

const LIMIT = 300;
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type Cat = "change" | "document" | "download" | "access" | "denied";
type Event = {
  key: string;
  at: string;
  actorId: string | null;
  cat: Cat;
  text: string;
  item?: string;
  fields?: string[];
  values?: Record<string, [unknown, unknown]>;
  outcome: string;
  role?: string;
  source?: string;
  record?: string;
  version?: string;
};

export const ACTIVITY_FILTERS: [string, string][] = [
  ["", "All activity"],
  ["changes", "Record changes"],
  ["documents", "Document activity"],
  ["downloads", "Downloads"],
  ["access", "Information access"],
  ["denied", "Access denied"],
];

const TABLE: Record<string, [string, string]> = {
  car_clients: ["the client record", "Client record"],
  client_details: ["personal and contact details", "Personal details"],
  client_locations: ["a service location", "Service location"],
  client_people: ["a contact or representative", "Contacts and representatives"],
  client_comms: ["communication and accessibility needs", "Communication needs"],
  client_alerts: ["a safety alert", "Safety alert"],
  client_alert_notes: ["a safety alert note", "Safety alert note"],
  client_services: ["an approved service", "Approved service"],
  client_agreements: ["a service agreement", "Service agreement"],
  client_care_plans: ["a care plan", "Care plan"],
  client_care_goals: ["a care plan goal", "Care plan goal"],
  client_worker_instructions: ["worker instructions", "Worker instructions"],
  client_funding: ["funding and budget", "Funding"],
  client_reviews: ["a review", "Review"],
  client_documents: ["a document", "Document"],
  client_assignments: ["a staff assignment", "Staff assignment"],
  client_communications: ["a communication log entry", "Communication log"],
  client_practitioner_notes: ["a practitioner note", "Practitioner note"],
  client_external_access: ["practitioner access", "Practitioner access"],
  // cmeprojects (updates 160 and 161): billing-related records in the client's audit history.
  client_service_terms: ["billing terms for a service", "Billing terms"],
  client_contribution_rates: ["a contribution rate", "Contribution rate"],
  shift_cancellations: ["cancellation details", "Cancellation details"],
  client_budget_proposals: ["a proposed budget", "Proposed budget"],
  client_budget_lines: ["a proposed budget line", "Proposed budget line"],
};
const VERB: Record<string, string> = { approved: "approved", needs_approval: "changed the address of (needs approving again)", added: "added", changed: "changed", removed: "removed", archived: "archived", restored: "restored", replaced: "uploaded a new version of" };

const fieldLabel = (k: string) => {
  const t = k.replace(/_id$/, "").replace(/_/g, " ");
  return t.charAt(0).toUpperCase() + t.slice(1);
};

function parseAction(action: string, details: Record<string, unknown>): { table: string; verb: string } {
  // Older entries: added_car_client / changed_car_client.
  const legacy = action.match(/^(added|changed)_car_client$/);
  if (legacy) return { table: "car_clients", verb: legacy[1] };
  // Older entries from the location and status guards (before update 156).
  const loc = action.match(/^client_location_(added|changed|approved|needs_approval)$/);
  if (loc) return { table: "client_locations", verb: loc[1] };
  if (action === "client_status") return { table: "car_clients", verb: "status" };
  const m = action.match(/^(.*)_(added|changed|removed|archived|restored|replaced)$/);
  if (m) return { table: typeof details.table === "string" ? details.table : m[1], verb: m[2] };
  return { table: "", verb: action.replace(/_/g, " ") };
}

export async function ClientActivity({ clientId, filter, isSystemAdmin }: { clientId: string; filter: string; isSystemAdmin: boolean }) {
  const supabase = await createClient();
  // Opening the trail is recorded (at most once an hour for each person, like the page).
  const { data: me } = await supabase.auth.getUser();
  if (me.user) {
    const since = new Date(Date.parse(new Date().toISOString()) - 3_600_000).toISOString();
    const { data: recent } = await supabase.from("client_staff_views").select("id").eq("client_id", clientId).eq("user_id", me.user.id).eq("area", "audit_trail").gte("viewed_at", since).limit(1);
    if (!recent?.length) await supabase.from("client_staff_views").insert({ client_id: clientId, area: "audit_trail" });
  }

  const [audit, downloads, views] = await Promise.all([
    supabase.from("audit_log").select("id, actor_id, action, details, created_at").in("entity", ["client", "car_client"]).eq("entity_id", clientId).order("id", { ascending: false }).limit(LIMIT),
    supabase.from("download_log").select("id, user_id, kind, action, outcome, label, details, created_at").eq("client_id", clientId).order("id", { ascending: false }).limit(LIMIT),
    supabase.from("client_staff_views").select("id, user_id, viewed_at, area").eq("client_id", clientId).order("viewed_at", { ascending: false }).limit(LIMIT),
  ]);
  if (audit.error) {
    return (
      <Card className="p-5 text-sm text-muted">
        The activity and audit trail isn&apos;t set up yet (update 155).
      </Card>
    );
  }
  const auditRows = (audit.data ?? []) as { id: number; actor_id: string | null; action: string; details: Record<string, unknown> | null; created_at: string }[];
  const { data: valueRows } = auditRows.length ? await supabase.from("client_audit_values").select("audit_id, changes").in("audit_id", auditRows.map((r) => r.id)) : { data: [] };
  const valuesOf = new Map(((valueRows ?? []) as { audit_id: number; changes: Record<string, [unknown, unknown]> }[]).map((v) => [v.audit_id, v.changes]));

  const events: Event[] = [];
  for (const r of auditRows) {
    const d = r.details ?? {};
    const { table, verb } = parseAction(r.action, d);
    const [what, heading] = TABLE[table] ?? [table.replace(/^client_/, "").replace(/_/g, " ") || "a record", "Record"];
    const word = (v: unknown) => String(v ?? "").replace(/_/g, " ");
    const text =
      table === "car_clients" && verb === "added"
        ? "created the client record"
        : verb === "status"
          ? `changed the status from ${word(d.from)} to ${word(d.to)}`
          : `${VERB[verb] ?? verb} ${what}`;
    // Older entries kept the whole record as before/after.
    const legacyValues =
      d.before && d.after && typeof d.before === "object" && typeof d.after === "object"
        ? Object.fromEntries(
            Object.keys(d.after as object)
              .filter((k) => JSON.stringify((d.before as Record<string, unknown>)[k]) !== JSON.stringify((d.after as Record<string, unknown>)[k]) && !/updated_|_at$/.test(k))
              .map((k) => [k, [(d.before as Record<string, unknown>)[k], (d.after as Record<string, unknown>)[k]]]),
          )
        : undefined;
    const values = valuesOf.get(r.id) ?? (isSystemAdmin ? (legacyValues as Record<string, [unknown, unknown]> | undefined) : undefined);
    const fields = Array.isArray(d.fields) ? (d.fields as string[]) : values ? Object.keys(values) : legacyValues ? Object.keys(legacyValues) : [];
    events.push({
      key: `a${r.id}`,
      at: r.created_at,
      actorId: r.actor_id,
      cat: table === "client_documents" ? "document" : "change",
      text,
      item: typeof d.item === "string" && d.item && table !== "car_clients" ? `${heading}: ${d.item}` : typeof d.location === "string" ? `${heading}: ${d.location}` : heading,
      fields,
      values,
      outcome: typeof d.outcome === "string" ? d.outcome : "success",
      role: typeof d.role === "string" ? d.role : undefined,
      source: typeof d.source === "string" ? d.source : undefined,
      record: typeof d.record === "string" ? d.record : undefined,
      version: d.version !== undefined && d.version !== null ? String(d.version) : undefined,
    });
  }
  for (const r of (downloads.data ?? []) as { id: number; user_id: string; kind: string; action: string; outcome: string; label: string; details: Record<string, unknown>; created_at: string }[]) {
    const denied = r.action === "download_denied";
    events.push({
      key: `d${r.id}`,
      at: r.created_at,
      actorId: r.user_id,
      cat: denied ? "denied" : "download",
      text: denied ? "was refused a download" : r.action === "export" ? "exported" : "was given a download link for",
      item: r.label.replace(/^Refused: /, ""),
      outcome: r.outcome,
      record: typeof r.details?.file === "string" ? r.details.file : undefined,
      source: "portal",
    });
  }
  for (const r of (views.data ?? []) as { id: number; user_id: string; viewed_at: string; area?: string }[]) {
    events.push({
      key: `v${r.id}`,
      at: r.viewed_at,
      actorId: r.user_id,
      cat: "access",
      text: r.area === "audit_trail" ? "opened the activity and audit trail" : "opened the client's profile",
      outcome: "success",
      source: "portal",
    });
  }
  events.sort((a, b) => (a.at < b.at ? 1 : a.at > b.at ? -1 : 0));

  const shown = events.filter((e) =>
    !filter ? true : filter === "changes" ? e.cat === "change" : filter === "documents" ? e.cat === "document" || (e.cat === "download" && /document/i.test(e.item ?? "")) : filter === "downloads" ? e.cat === "download" || e.cat === "denied" : filter === "access" ? e.cat === "access" : filter === "denied" ? e.outcome !== "success" : true,
  );

  // Names: who did it, and people named in the values (for example an assignment).
  const ids = new Set<string>();
  for (const e of shown) {
    if (e.actorId) ids.add(e.actorId);
    for (const [b, a] of Object.values(e.values ?? {})) for (const v of [b, a]) if (typeof v === "string" && UUID.test(v)) ids.add(v);
  }
  const { data: people } = ids.size ? await supabase.from("profiles").select("id, full_name, email").in("id", [...ids]) : { data: [] };
  const nameOf = new Map(((people ?? []) as { id: string; full_name: string | null; email: string }[]).map((p) => [p.id, p.full_name || p.email]));
  const show = (v: unknown): string => {
    if (v === null || v === undefined || v === "") return "blank";
    if (typeof v === "boolean") return v ? "Yes" : "No";
    if (Array.isArray(v)) return v.map(show).join(", ") || "none";
    if (typeof v === "object") return JSON.stringify(v).slice(0, 200);
    const t = String(v);
    if (UUID.test(t)) return nameOf.get(t) ?? "(a linked record)";
    if (/^\d{4}-\d{2}-\d{2}T/.test(t)) return new Date(t).toLocaleString("en-AU", { timeZone: "Australia/Sydney", dateStyle: "medium", timeStyle: "short" });
    return t;
  };
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone: "Australia/Sydney" });
  const base = `/settings/clients/${clientId}?tab=activity`;

  return (
    <section id="activity" className="flex flex-col gap-3">
      <div className="flex flex-wrap items-center gap-2">
        <History aria-hidden="true" className="size-5 text-brand" />
        <h2 className="heading-sm flex-1">Activity and audit trail</h2>
      </div>
      <p className="text-sm text-muted">
        Who opened, changed, uploaded, exported or was given a download link for this client&apos;s information. Recorded by the portal itself; it can&apos;t be edited or deleted.{" "}
        {isSystemAdmin ? "As the system admin, you also see the before and after values." : "Before and after values are shown to the system admin only."}
      </p>
      <nav aria-label="Filter the activity" className="flex flex-wrap gap-1.5">
        {ACTIVITY_FILTERS.map(([k, l]) => (
          <Link key={k || "all"} href={k ? `${base}&f=${k}` : base} scroll={false} aria-current={filter === k ? "page" : undefined} className={`rounded-full px-3 py-1 text-sm font-semibold ring-1 ${filter === k ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line hover:text-ink"}`}>
            {l}
          </Link>
        ))}
      </nav>
      <Card className="overflow-hidden">
        {shown.length === 0 ? (
          <EmptyState icon={History} title="Nothing here" text={filter ? "Nothing of this kind has been recorded." : "Nothing has been recorded yet."} />
        ) : (
          <ol className="divide-y divide-line">
            {shown.map((e) => (
              <li key={e.key}>
                <details className="group">
                  <summary className="flex cursor-pointer list-none flex-wrap items-start gap-x-4 gap-y-1 px-5 py-3 hover:bg-page/60 [&::-webkit-details-marker]:hidden">
                    <div className="min-w-0 flex-1 basis-72 text-sm">
                      <p>
                        <span className="font-semibold">{e.actorId ? (nameOf.get(e.actorId) ?? (e.role && isRole(e.role) ? `A ${ROLE_LABELS[e.role]}` : "Someone")) : "The system"}</span> {e.text}
                        {e.cat === "download" || e.cat === "denied" ? <> {e.item}</> : null}
                      </p>
                      <p className="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted">
                        {e.item && e.cat !== "download" && e.cat !== "denied" ? <span className="rounded-full bg-page px-2 py-0.5 ring-1 ring-line">{e.item}</span> : null}
                        {e.fields?.length ? <span>{e.fields.slice(0, 4).map(fieldLabel).join(", ")}{e.fields.length > 4 ? ` and ${e.fields.length - 4} more` : ""}</span> : null}
                        {e.outcome !== "success" ? <span className="rounded-full bg-red-50 px-2 py-0.5 font-semibold text-red-800 ring-1 ring-red-200">Denied</span> : null}
                      </p>
                    </div>
                    <time dateTime={e.at} className="text-sm whitespace-nowrap text-muted">
                      {when.format(new Date(e.at))}
                    </time>
                    <ChevronDown aria-hidden="true" className="mt-0.5 size-4 text-muted transition-transform group-open:rotate-180" />
                  </summary>
                  <div className="flex flex-col gap-3 border-t border-line bg-page/40 px-5 py-3 text-sm">
                    <dl className="grid gap-x-6 gap-y-1 sm:grid-cols-2">
                      <div className="flex gap-2"><dt className="text-muted">Outcome</dt><dd className="font-semibold">{e.outcome === "success" ? "Successful" : e.outcome === "denied" ? "Denied" : "Failed"}</dd></div>
                      {e.role ? <div className="flex gap-2"><dt className="text-muted">Their role then</dt><dd>{isRole(e.role) ? ROLE_LABELS[e.role] : e.role}</dd></div> : null}
                      {e.source ? <div className="flex gap-2"><dt className="text-muted">From</dt><dd>{e.source === "portal" ? "The portal" : e.source === "automation" ? "Automatic (no person)" : "The database"}</dd></div> : null}
                      {e.version ? <div className="flex gap-2"><dt className="text-muted">Version</dt><dd>{e.version}</dd></div> : null}
                      {e.record ? <div className="flex gap-2"><dt className="text-muted">Reference</dt><dd className="font-mono text-xs break-all">{e.record}</dd></div> : null}
                      {e.cat === "download" && e.text.includes("link") ? <div className="sm:col-span-2 text-xs text-muted">A download link was handed over; the portal can&apos;t confirm the file was saved.</div> : null}
                    </dl>
                    {e.values && Object.keys(e.values).length ? (
                      <table className="w-full text-left text-sm">
                        <thead className="text-xs text-muted">
                          <tr>
                            <th className="py-1 pr-3 font-semibold">Field</th>
                            <th className="py-1 pr-3 font-semibold">Before</th>
                            <th className="py-1 font-semibold">After</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-line">
                          {Object.entries(e.values).map(([k, [b, a]]) => (
                            <tr key={k} className="align-top">
                              <td className="py-1 pr-3 font-semibold">{fieldLabel(k)}</td>
                              <td className="py-1 pr-3 break-words text-muted">{show(b)}</td>
                              <td className="py-1 break-words">{show(a)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    ) : e.fields?.length ? (
                      <p className="text-muted">Fields: {e.fields.map(fieldLabel).join(", ")}.</p>
                    ) : null}
                  </div>
                </details>
              </li>
            ))}
          </ol>
        )}
      </Card>
      {events.length >= LIMIT ? <p className="text-xs text-muted">Showing the most recent activity.</p> : null}
    </section>
  );
}
