// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { sydneyToday } from "@/lib/sydney-time";
import { nowMs } from "@/lib/access";
import { DOC_TYPE_LABELS } from "@/lib/client-sections";
import { NoteForm, ReportForm } from "../forms";

export const metadata: Metadata = { title: "Client" };

const day = (d: string) => new Date(`${d.slice(0, 10)}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });

// cmeprojects (update 124, Stage 6): one client, as an Allied Health
// practitioner sees them: only the sections they were given.
export default async function PractitionerClientPage({ params }: PageProps<"/practitioner/[id]">) {
  const { profile } = await requireSession();
  if (profile.role !== "external") notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const today = sydneyToday();
  const [{ data: client }, { data: accessRows }] = await Promise.all([
    supabase.from("car_clients").select("id, name, preferred_name, client_ref").eq("id", id).maybeSingle(),
    supabase.from("client_external_access").select("sections, ends_on").eq("client_id", id).eq("user_id", profile.id).is("ended_at", null).lte("starts_on", today).gte("ends_on", today).limit(1),
  ]);
  const access = (accessRows ?? [])[0] as { sections: string[]; ends_on: string } | undefined;
  if (!client || !access) notFound();
  const has = (s: string) => access.sections.includes(s);
  // Opening the page is logged for the client's team.
  await supabase.from("client_external_views").insert({ client_id: id });

  const [details, alerts, plan, instructions, docsRes, notesRes] = await Promise.all([
    has("details") ? supabase.from("client_details").select("date_of_birth, communication_needs, preferred_contact, about").eq("client_id", id).maybeSingle() : Promise.resolve({ data: null }),
    has("alerts") ? supabase.from("client_alerts").select("id, title, severity, worker_instructions").eq("client_id", id).eq("active", true) : Promise.resolve({ data: [] }),
    has("care_plan") ? supabase.from("client_care_plans").select("id, title, summary, starts_on, review_by").eq("client_id", id).eq("status", "current").is("archived_at", null).maybeSingle() : Promise.resolve({ data: null }),
    has("care_plan") ? supabase.from("client_worker_instructions").select("id, title, instructions").eq("client_id", id).eq("active", true).order("sort_order") : Promise.resolve({ data: [] }),
    supabase.from("client_documents").select("id, title, doc_type, file_path, uploaded_by, created_at").eq("client_id", id).is("archived_at", null).order("created_at", { ascending: false }),
    supabase.from("client_practitioner_notes").select("id, author_id, note_date, body, created_at").eq("client_id", id).order("note_date", { ascending: false }).order("created_at", { ascending: false }).limit(50),
  ]);
  const d = details.data as { date_of_birth: string | null; communication_needs: string | null; preferred_contact: string | null; about: string | null } | null;
  const alertRows = (alerts.data ?? []) as { id: string; title: string; severity: string; worker_instructions: string | null }[];
  const p = plan.data as { id: string; title: string; summary: string | null; starts_on: string | null; review_by: string | null } | null;
  const { data: goals } = p ? await supabase.from("client_care_goals").select("id, goal, measure, status").eq("plan_id", p.id).order("sort_order") : { data: [] };
  const instr = (instructions.data ?? []) as { id: string; title: string; instructions: string }[];
  const docs = (docsRes.data ?? []) as { id: string; title: string; doc_type: string; file_path: string; uploaded_by: string | null; created_at: string }[];
  const links = new Map<string, string>();
  if (docs.length) {
    const { data: signed } = await supabase.storage.from("client-docs").createSignedUrls(docs.map((x) => x.file_path), 600);
    for (const s of signed ?? []) if (s.signedUrl && s.path) links.set(s.path, s.signedUrl);
  }
  const notes = (notesRes.data ?? []) as { id: string; author_id: string | null; note_date: string; body: string; created_at: string }[];
  const shown = client.preferred_name || client.name;
  const docType = (v: string) => DOC_TYPE_LABELS.find(([k]) => k === v)?.[1] ?? v;

  return (
    <>
      <Link href="/" className="text-sm font-semibold text-brand hover:underline">
        ← My clients
      </Link>
      <PageHeader title={shown} intro={`${client.client_ref ?? ""}${client.preferred_name ? ` · ${client.name}` : ""} · your access ends ${day(access.ends_on)}`} />

      {alertRows.length ? (
        <Card className="flex flex-col gap-2 border-danger p-4">
          <h2 className="heading-sm">Alerts</h2>
          {alertRows.map((a) => (
            <div key={a.id} className="text-sm">
              <p className="font-semibold">{a.title}</p>
              {a.worker_instructions ? <p className="whitespace-pre-line text-muted">{a.worker_instructions}</p> : null}
            </div>
          ))}
        </Card>
      ) : null}

      {d ? (
        <Card className="grid gap-3 p-4 text-sm sm:grid-cols-2">
          <h2 className="heading-sm sm:col-span-2">About {shown}</h2>
          {d.date_of_birth ? <p><span className="block text-xs text-muted">Date of birth</span>{day(d.date_of_birth)}</p> : null}
          {d.preferred_contact ? <p><span className="block text-xs text-muted">Preferred contact</span>{d.preferred_contact}</p> : null}
          {d.communication_needs ? <p className="sm:col-span-2"><span className="block text-xs text-muted">Communication needs</span>{d.communication_needs}</p> : null}
          {d.about ? <p className="whitespace-pre-line sm:col-span-2"><span className="block text-xs text-muted">About</span>{d.about}</p> : null}
        </Card>
      ) : null}

      {has("care_plan") ? (
        <Card className="flex flex-col gap-3 p-4 text-sm">
          <h2 className="heading-sm">Care plan</h2>
          {p ? (
            <>
              <p className="font-semibold">
                {p.title}
                {p.review_by ? <span className="font-normal text-muted"> · review by {day(p.review_by)}</span> : null}
              </p>
              {p.summary ? <p className="whitespace-pre-line">{p.summary}</p> : null}
              {(goals ?? []).length ? (
                <ul className="list-disc pl-5">
                  {((goals ?? []) as { id: string; goal: string; measure: string | null }[]).map((g) => (
                    <li key={g.id}>
                      {g.goal}
                      {g.measure ? <span className="text-muted"> ({g.measure})</span> : null}
                    </li>
                  ))}
                </ul>
              ) : null}
            </>
          ) : (
            <p className="text-muted">No current care plan.</p>
          )}
          {instr.length ? (
            <div className="flex flex-col gap-2 border-t border-line pt-3">
              <h3 className="font-semibold">How to support {shown}</h3>
              {instr.map((i) => (
                <p key={i.id} className="whitespace-pre-line">
                  <span className="font-semibold">{i.title}: </span>
                  {i.instructions}
                </p>
              ))}
            </div>
          ) : null}
        </Card>
      ) : null}

      <Card className="flex flex-col gap-3 p-4">
        <h2 className="heading-sm">Documents</h2>
        {docs.length ? (
          <ul className="divide-y divide-line rounded-md border border-line text-sm">
            {docs.map((x) => (
              <li key={x.id} className="flex flex-wrap items-center gap-2 px-3 py-2">
                {links.get(x.file_path) ? (
                  <a href={links.get(x.file_path)} target="_blank" rel="noreferrer" className="flex-1 font-semibold text-brand hover:underline">
                    {x.title}
                  </a>
                ) : (
                  <span className="flex-1 font-semibold">{x.title}</span>
                )}
                <span className="text-xs text-muted">
                  {docType(x.doc_type)} · {day(x.created_at)}
                  {x.uploaded_by === profile.id ? " · uploaded by you" : ""}
                </span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-sm text-muted">No documents shared with you yet.</p>
        )}
        <details>
          <summary className="cursor-pointer text-sm font-semibold text-brand">Upload a report</summary>
          <div className="mt-2">
            <ReportForm clientId={id} />
          </div>
        </details>
      </Card>

      <Card className="flex flex-col gap-3 p-4">
        <h2 className="heading-sm">Notes</h2>
        <NoteForm clientId={id} today={today} />
        {notes.length ? (
          <ul className="flex flex-col gap-2">
            {notes.map((n) => {
              const mine = n.author_id === profile.id;
              const canChange = mine && new Date(n.created_at).getTime() > nowMs() - 24 * 3_600_000;
              return (
                <li key={n.id} className="rounded-md border border-line p-3 text-sm">
                  <p className="text-xs text-muted">
                    {day(n.note_date)} · {mine ? "you" : "another practitioner"}
                  </p>
                  <p className="mt-1 whitespace-pre-line">{n.body}</p>
                  {canChange ? (
                    <details className="mt-2">
                      <summary className="cursor-pointer text-xs font-semibold text-brand">Change (within 24 hours)</summary>
                      <div className="mt-2">
                        <NoteForm clientId={id} today={today} note={n} />
                      </div>
                    </details>
                  ) : null}
                </li>
              );
            })}
          </ul>
        ) : (
          <p className="text-sm text-muted">No notes yet.</p>
        )}
      </Card>
    </>
  );
}
