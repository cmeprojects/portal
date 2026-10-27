// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { STATUS_LABELS, todayIn, type Status } from "@/lib/tasks";
import { formatValue, refLabel, type Details } from "@/lib/registers";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { Badge, Card, Notice } from "@/components/ui";
import { RecordForm } from "../record-form";

export const metadata: Metadata = { title: "Item" };

const UUID = /^[0-9a-f-]{36}$/i;

export default async function RecordPage({ params, searchParams }: PageProps<"/records/[id]">) {
  const { id } = await params;
  const { saved } = await searchParams;
  if (!UUID.test(id)) notFound();
  await requireSession();
  const supabase = await createClient();
  const { data: record } = await supabase
    .from("records")
    .select("id, registry_id, ref_number, title, details, archived, created_by, created_at")
    .eq("id", id)
    .maybeSingle();
  if (!record) notFound();

  const [registries, allFields, people, assets, timeZone, { data: events }, { data: manages }] = await Promise.all([
    getRegistries(),
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
    supabase.from("record_events").select("id, actor_id, type, details, created_at").eq("record_id", id).order("created_at"),
    supabase.rpc("manages_registry", { p_registry_id: record.registry_id }),
  ]);
  const registry = registries.find((r) => r.id === record.registry_id);
  if (!registry) notFound();
  const fields = allFields.filter((f) => f.registry_id === registry.id);
  const names = new Map(people.map((p) => [p.id, p.name]));
  const details = (record.details ?? {}) as Details;
  const when = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone });

  // Tasks in any register that link to this item (for example its repairs).
  const linkKeys = [...new Set(allFields.filter((f) => f.type === "asset").map((f) => f.key))];
  const { data: linked } = linkKeys.length
    ? await supabase
        .from("tasks")
        .select("id, ref_number, title, status, registry_id")
        .or(linkKeys.map((k) => `details->>${k}.eq.${id}`).join(","))
        .order("created_at", { ascending: false })
    : { data: [] };

  return (
    <>
      {saved ? <Notice tone="success">Saved.</Notice> : null}
      <div className="flex flex-col gap-2">
        <Link href={`/registers/${registry.id}`} className="text-[15px] font-semibold text-brand">
          ← {registry.name}
        </Link>
        <p className="text-sm font-semibold text-muted">{refLabel(registry.prefix, record.ref_number)}</p>
        <h1 className="text-[28px] font-extrabold leading-tight">{record.title}</h1>
        {record.archived ? <span><Badge tone="grey">Archived</Badge></span> : null}
      </div>

      <div className="grid items-start gap-4 lg:grid-cols-[1fr_340px]">
        <div className="flex min-w-0 flex-col gap-4">
          <Card className="p-5">
            <dl className="grid gap-x-6 gap-y-4 sm:grid-cols-2">
              {fields
                .filter((f) => f.active || details[f.key] !== undefined)
                .map((f) => (
                  <div key={f.id}>
                    <dt className="text-[13px] font-bold uppercase tracking-wide text-muted">{f.label}</dt>
                    <dd className="text-[15px]">
                      {formatValue(f, details[f.key], { person: (pid) => names.get(pid) ?? "", asset: (aid) => assets.find((a) => a.id === aid)?.label ?? "" }) || (
                        <span className="text-muted">Not filled in</span>
                      )}
                    </dd>
                  </div>
                ))}
            </dl>
          </Card>
          {manages ? (
            <details className="rounded-[20px] border border-line bg-white">
              <summary className="flex min-h-14 cursor-pointer list-none items-center px-5 font-bold text-brand">Edit</summary>
              <div className="px-5 pb-5">
                <RecordForm
                  registry={registry}
                  fields={fields.filter((f) => f.active)}
                  people={people.filter((p) => p.active).map((p) => ({ id: p.id, label: p.name }))}
                  assets={assets.filter((a) => !a.archived && a.id !== id)}
                  record={{ id: record.id, title: record.title, details, archived: record.archived }}
                  today={todayIn(timeZone)}
                />
              </div>
            </details>
          ) : null}
          <Card className="p-5">
            <h2 className="mb-3 text-lg font-bold">Linked tasks</h2>
            {(linked ?? []).length ? (
              <ul className="flex flex-col divide-y divide-line">
                {(linked ?? []).map((t) => {
                  const reg = registries.find((r) => r.id === t.registry_id);
                  return (
                    <li key={t.id}>
                      <Link href={`/tasks/${t.id}`} className="flex flex-wrap justify-between gap-2 py-3 hover:text-brand">
                        <span className="font-semibold">
                          {refLabel(reg?.prefix, t.ref_number)} · {t.title}
                        </span>
                        <span className="text-sm text-muted">{STATUS_LABELS[t.status as Status]}</span>
                      </Link>
                    </li>
                  );
                })}
              </ul>
            ) : (
              <p className="text-[15px] text-muted">No tasks you can see link to this yet.</p>
            )}
          </Card>
        </div>
        <Card className="p-5">
          <h2 className="mb-3 text-lg font-bold">History</h2>
          <ol className="flex flex-col gap-3">
            {(events ?? []).map((e) => {
              const changed = (e.details as { fields?: string[] })?.fields;
              return (
                <li key={e.id} className="text-[15px]">
                  <strong>{e.actor_id ? names.get(e.actor_id) ?? "Someone" : "System"}</strong>{" "}
                  {e.type === "created" ? "added it" : `changed ${changed?.join(", ") ?? "it"}`}
                  <time dateTime={e.created_at} className="block text-sm text-muted">
                    {when.format(new Date(e.created_at))}
                  </time>
                </li>
              );
            })}
          </ol>
        </Card>
      </div>
    </>
  );
}
