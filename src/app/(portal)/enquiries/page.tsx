// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Badge, Button, Card, Notice, PageHeader, inputClass } from "@/components/ui";
import { updateEnquiry } from "./actions";
import { STAGES } from "./stages";

export const metadata: Metadata = { title: "Enquiries" };

const when = (iso: string) =>
  new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone: "Australia/Sydney" }).format(new Date(iso));

// cmeprojects: people who left their details on the website, for managers to
// call back and follow up.
export default async function EnquiriesPage({ searchParams }: PageProps<"/enquiries">) {
  const { features } = await requireRole(["manager", "system_admin"]);
  const query = await searchParams;
  const stage = typeof query.stage === "string" && STAGES.some((s) => s.key === query.stage) ? query.stage : "";
  const { data, error } = await (await createClient()).from("website_enquiries").select("*").order("created_at", { ascending: false }).limit(300);
  const all = data ?? [];
  const count = (k: string) => all.filter((e) => e.status === k).length;
  const rows = stage ? all.filter((e) => e.status === stage) : all;
  const chip = (on: boolean) =>
    `flex min-h-16 flex-col justify-center rounded-lg border px-4 py-2 ${on ? "border-brand bg-brand-soft" : "border-line bg-surface hover:border-muted"}`;

  return (
    <>
      <PageHeader title="Enquiries" intro="People who left their details on the website. Call them back and move them along." />
      {!features.assistant ? <Notice>The website is switched off, so no new enquiries will arrive. Old ones are kept.</Notice> : null}
      {error ? <Notice tone="error">Enquiries aren&apos;t set up in the database yet. Ask the system admin to run live update 36.</Notice> : null}

      <nav aria-label="Stage" className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        {STAGES.map((s) => (
          <Link key={s.key} href={stage === s.key ? "/enquiries" : `/enquiries?stage=${s.key}`} className={chip(stage === s.key)}>
            <span className="text-2xl font-bold">{count(s.key)}</span>
            <span className="text-sm">{s.label}</span>
          </Link>
        ))}
      </nav>

      {rows.length === 0 ? (
        <p className="rounded-lg border border-line bg-surface px-4 py-3 text-sm text-muted">{all.length ? "None at this stage." : "No enquiries yet."}</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {rows.map((e) => (
            <li key={e.id}>
              <Card className="flex flex-col gap-3 p-4">
                <div className="flex flex-wrap items-start justify-between gap-2">
                  <div>
                    <p className="text-lg font-semibold">{e.full_name}</p>
                    <p className="text-sm">
                      <a href={`tel:${e.phone.replace(/\s/g, "")}`} className="text-brand underline">
                        {e.phone}
                      </a>
                      {e.email ? (
                        <>
                          {" · "}
                          <a href={`mailto:${e.email}`} className="text-brand underline">
                            {e.email}
                          </a>
                        </>
                      ) : null}
                    </p>
                  </div>
                  <div className="flex flex-col items-end gap-1 text-xs text-muted">
                    <Badge tone={e.status === "new" ? "warn" : e.status === "client" ? "good" : "grey"}>{STAGES.find((s) => s.key === e.status)?.label}</Badge>
                    <span>
                      {e.source === "chat" ? "From the chat" : "Website form"} · {when(e.created_at)}
                    </span>
                  </div>
                </div>
                <dl className="grid gap-x-6 gap-y-1 text-sm sm:grid-cols-2">
                  {[
                    ["Suburb", e.suburb],
                    ["Support is for", e.support_for],
                    ["NDIS plan", [e.has_plan, e.managed_by].filter(Boolean).join(", ")],
                    ["Looking for", (e.needs ?? []).join(", ")],
                    ["Best time to call", e.best_time],
                    ["Heard about us", e.heard_from],
                  ]
                    .filter(([, v]) => v)
                    .map(([k, v]) => (
                      <div key={k} className="flex gap-2">
                        <dt className="w-32 shrink-0 text-muted">{k}</dt>
                        <dd>{v}</dd>
                      </div>
                    ))}
                </dl>
                {e.asked ? (
                  <p className="rounded-md bg-page px-3 py-2 text-sm">
                    <span className="text-muted">They asked the assistant: </span>
                    {e.asked}
                  </p>
                ) : null}
                {e.message ? <p className="whitespace-pre-line text-sm">{e.message}</p> : null}
                <form action={updateEnquiry} className="flex flex-wrap items-end gap-2 border-t border-line pt-3">
                  <input type="hidden" name="id" value={e.id} />
                  <label className="flex flex-col gap-1 text-xs font-medium">
                    Stage
                    <select name="status" defaultValue={e.status} className={`${inputClass} w-48`}>
                      {STAGES.map((s) => (
                        <option key={s.key} value={s.key}>
                          {s.label}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label className="flex min-w-48 flex-1 flex-col gap-1 text-xs font-medium">
                    Note
                    <input name="note" defaultValue={e.note} maxLength={1000} placeholder="For example: left a message" className={inputClass} />
                  </label>
                  <Button size="sm">Save</Button>
                </form>
              </Card>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
