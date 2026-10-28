// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { PRIORITY_CLASS, PRIORITY_LABELS, STATUS_LABELS, dueState, formatDue, todayIn, type Priority, type Status } from "@/lib/tasks";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import type { Registry } from "@/lib/registers";
import { parseFilter, registerTable } from "@/lib/register-rows";
import { Card, PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { ExportPanel } from "./export-panel";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { getBranding } from "@/lib/branding";

export const metadata: Metadata = { title: "Register" };

export default async function RegisterPage({ params, searchParams }: PageProps<"/registers/[id]">) {
  const { id } = await params;
  const filter = parseFilter(await searchParams);
  const { features, profile } = await requireTaskAccess();
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) notFound();
  // Staff admins get an overview of open tasks, without the details.
  if (profile.role === "staff_admin" && registry.kind === "tasks") {
    return <RegisterOverview registry={registry} canCreate={features.tasks !== false && registry.active} />;
  }

  const supabase = await createClient();
  const [fields, people, assets, timeZone, { data: manages }] = await Promise.all([
    getFields(),
    getPeople(),
    getAssets(),
    getTimeZone(),
    supabase.rpc("manages_registry", { p_registry_id: id }),
  ]);
  const table = await registerTable(registry, fields, people, assets, filter, todayIn(timeZone));
  const records = registry.kind === "records";
  const tabs = records
    ? [
        { key: "open", label: "In the list" },
        { key: "done", label: "Archived" },
        { key: "all", label: "All" },
      ]
    : [
        { key: "open", label: "Open" },
        { key: "done", label: "Completed" },
        { key: "all", label: "All" },
      ];
  const qs = (status: string) => {
    const p = new URLSearchParams();
    if (status !== "open") p.set("status", status);
    if (filter.q) p.set("q", filter.q);
    const s = p.toString();
    return s ? `?${s}` : "";
  };

  const brand = await getBranding();
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());

  return (
    <>
      <PrintHeader brand={brand} title={registry.name} subtitle={`${tabs.find((t) => t.key === filter.status)?.label ?? ""}${filter.q ? ` · "${filter.q}"` : ""}`} printedAt={printedAt} />
      <PageHeader
        eyebrow={`Registers · ${registry.prefix}`}
        title={registry.name}
        intro={registry.description || undefined}
        action={
          <div className="flex flex-wrap gap-2 print:hidden">
            <PrintButton />
            {manages ? (
              <Link href={`/registers/${id}/setup`} className={buttonClass("outline")}>
                Set up
              </Link>
            ) : null}
            <ExportPanel registerId={id} today={todayIn(timeZone)} records={records} status={filter.status} q={filter.q} />
            {records ? (
              manages ? (
                <Link href={`/registers/${id}/new`} className={buttonClass("primary")}>
                  + Add item
                </Link>
              ) : null
            ) : features.tasks !== false && registry.active ? (
              <Link href={`/tasks/new?register=${id}`} className={buttonClass("primary")}>
                + New task
              </Link>
            ) : null}
          </div>
        }
      />

      <Card className="overflow-hidden">
        <div className="flex flex-wrap items-end justify-between gap-3 border-b border-line px-4 pt-2 pb-3">
          <Tabs
            label="Filter"
            items={tabs.map((t) => ({ href: `/registers/${id}${qs(t.key)}`, text: t.label, current: filter.status === t.key }))}
          />
          <form className="flex min-w-60 flex-1 gap-2 sm:max-w-sm print:hidden" role="search">
            {filter.status !== "open" ? <input type="hidden" name="status" value={filter.status} /> : null}
            <label htmlFor="q" className="sr-only">
              Search this register
            </label>
            <input id="q" name="q" type="search" defaultValue={filter.q} placeholder="Search by title" className={inputClass} />
          </form>
        </div>
        <DataTable
          table={table}
          empty={filter.q ? "Nothing matches your search." : records ? "Nothing in this list yet." : "No tasks here yet."}
        />
      </Card>
      {!records ? (
        <p className="text-sm text-muted">
          Showing the tasks you&apos;re allowed to see. Follow-up actions are listed on their main task.
        </p>
      ) : null}
    </>
  );
}

type OverviewRow = {
  ref: string;
  title: string;
  description: string;
  priority: Priority;
  status: Status;
  due_date: string | null;
  assigned_name: string;
};

// People management view: what's open in a register and who has it.
async function RegisterOverview({ registry, canCreate }: { registry: Registry; canCreate: boolean }) {
  const supabase = await createClient();
  const [{ data }, timeZone] = await Promise.all([
    supabase.rpc("register_overview", { p_registry_id: registry.id }),
    getTimeZone(),
  ]);
  const rows = (data ?? []) as OverviewRow[];
  const today = todayIn(timeZone);
  return (
    <>
      <PageHeader
        eyebrow={`Registers · ${registry.prefix}`}
        title={registry.name}
        intro={registry.description || undefined}
        action={
          canCreate ? (
            <Link href={`/tasks/new?register=${registry.id}`} className={buttonClass("primary")}>
              + New task
            </Link>
          ) : null
        }
      />
      <Card className="overflow-hidden">
        <h2 className="heading-sm border-b border-line px-5 py-3">Open tasks · {rows.length}</h2>
        {rows.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted">Nothing open in this register.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[44rem] text-sm">
              <thead className="bg-page text-left text-xs tracking-wider text-muted uppercase">
                <tr>
                  <th scope="col" className="px-4 py-3 font-medium">Task</th>
                  <th scope="col" className="px-4 py-3 font-medium">Description</th>
                  <th scope="col" className="px-4 py-3 font-medium">Priority</th>
                  <th scope="col" className="px-4 py-3 font-medium">Due</th>
                  <th scope="col" className="px-4 py-3 font-medium">Assigned to</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line">
                {rows.map((r) => {
                  const due = dueState(r.due_date, today, r.status);
                  return (
                    <tr key={r.ref}>
                      <td className="px-4 py-3 align-top">
                        <span className="block font-semibold">{r.title}</span>
                        <span className="text-xs text-muted">{r.ref} · {STATUS_LABELS[r.status]}</span>
                      </td>
                      <td className="max-w-80 px-4 py-3 align-top text-muted">
                        {r.description.length > 160 ? `${r.description.slice(0, 160)}…` : r.description || "—"}
                      </td>
                      <td className="px-4 py-3 align-top">
                        <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${PRIORITY_CLASS[r.priority]}`}>{PRIORITY_LABELS[r.priority]}</span>
                      </td>
                      <td className={`px-4 py-3 align-top whitespace-nowrap ${due === "overdue" ? "font-semibold text-danger" : due === "today" ? "text-warn" : "text-muted"}`}>
                        {formatDue(r.due_date, today, r.status)}
                      </td>
                      <td className="px-4 py-3 align-top">{r.assigned_name}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      <p className="text-sm text-muted">
        An overview for people management. Task details stay with the people working on them and their managers.
      </p>
    </>
  );
}
