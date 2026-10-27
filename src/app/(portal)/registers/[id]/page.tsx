// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { todayIn } from "@/lib/tasks";
import { getAssets, getFields, getPeople, getRegistries } from "@/lib/register-data";
import { parseFilter, registerTable } from "@/lib/register-rows";
import { Card, PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";

export const metadata: Metadata = { title: "Register" };

export default async function RegisterPage({ params, searchParams }: PageProps<"/registers/[id]">) {
  const { id } = await params;
  const filter = parseFilter(await searchParams);
  const { features } = await requireSession();
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) notFound();

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

  return (
    <>
      <PageHeader
        eyebrow={`Registers · ${registry.prefix}`}
        title={registry.name}
        intro={registry.description || undefined}
        action={
          <div className="flex flex-wrap gap-2">
            {manages ? (
              <Link href={`/registers/${id}/setup`} className={buttonClass("outline")}>
                Set up
              </Link>
            ) : null}
            <a href={`/registers/${id}/export${qs(filter.status)}`} className={buttonClass("outline")}>
              Download for Excel
            </a>
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
          <form className="flex min-w-60 flex-1 gap-2 sm:max-w-sm" role="search">
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
