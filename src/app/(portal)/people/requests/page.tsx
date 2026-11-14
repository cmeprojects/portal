// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { CircleCheck, CircleHelp, CircleX, Hourglass, Inbox } from "lucide-react";
import { requireSession } from "@/lib/session";
import { REQUEST_STATUS, REQUEST_TYPES, type RequestStatus } from "@/lib/requests-shared";
import { PageHeader, Tabs, buttonClass, inputClass } from "@/components/ui";
import { Tile } from "@/components/dash";
import { RequestList, loadRequests, waitingFor } from "../../requests/list";
import { FormPending } from "@/components/form-pending";

export const metadata: Metadata = { title: "Staff requests" };

const one = (v: string | string[] | undefined) => (typeof v === "string" ? v : "");

// cmeprojects: People → Staff requests: requests waiting for me to approve, and
// (for people who manage staff) everyone's requests, with a summary, filters
// and search. Team leaders, staff admins, managers and the system admin; the
// database decides who may act on each one (approval rules are unchanged).
export default async function StaffRequestsPage({ searchParams }: PageProps<"/people/requests">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const peopleManager = ["manager", "staff_admin", "system_admin"].includes(profile.role);
  if (!peopleManager && profile.role !== "team_leader") notFound();
  const all = await loadRequests();
  if (!all) notFound(); // before live update 56
  const params = await searchParams;
  const tab = String(params.tab ?? (profile.role === "system_admin" ? "all" : "approve")) === "all" && peopleManager ? "all" : "approve";
  const status = one(params.status) as RequestStatus | "";
  const type = one(params.type);
  const q = one(params.q).trim().toLowerCase();
  const waiting = await waitingFor(all, profile.id);

  const base = tab === "all" ? all : waiting;
  const rows = base.filter(
    (r) =>
      (!status || r.status === status) &&
      (!type || r.type === type) &&
      (!q || `${r.subject} ${r.ref_number}`.toLowerCase().includes(q)),
  );
  const count = (s: RequestStatus) => all.filter((r) => r.status === s).length;
  const filtered = Boolean(status || type || q);
  const keepTab = tab === "all" ? "tab=all&" : "";

  return (
    <>
      <PageHeader title="Staff requests" intro="Leave, shift swaps, availability and other requests from staff." />

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <Tile label="Waiting for me" value={waiting.length} icon={Inbox} accent="brand" href="/people/requests" />
        <Tile label="Pending" value={count("pending")} icon={Hourglass} accent="warn" href={`/people/requests?${peopleManager ? "tab=all&" : ""}status=pending`} />
        <Tile label="Awaiting info" value={count("info_needed")} icon={CircleHelp} accent="accent" href={`/people/requests?${peopleManager ? "tab=all&" : ""}status=info_needed`} />
        <Tile label="Approved" value={count("approved")} icon={CircleCheck} accent="good" href={`/people/requests?${peopleManager ? "tab=all&" : ""}status=approved`} />
        <Tile label="Rejected" value={count("declined")} icon={CircleX} accent="danger" href={`/people/requests?${peopleManager ? "tab=all&" : ""}status=declined`} />
      </div>

      <Tabs
        label="Staff requests"
        items={[
          { href: "/people/requests", text: `Waiting for me${waiting.length ? ` · ${waiting.length}` : ""}`, current: tab === "approve" },
          ...(peopleManager ? [{ href: "/people/requests?tab=all", text: "All requests", current: tab === "all" }] : []),
        ]}
      />

      <form method="get" action="/people/requests" className="flex flex-wrap items-end gap-2" role="search">
        {tab === "all" ? <input type="hidden" name="tab" value="all" /> : null}
        <label className="flex min-w-48 flex-1 flex-col gap-1 text-sm font-semibold">
          Search
          <input name="q" defaultValue={one(params.q)} placeholder="Subject or reference number" className={inputClass} />
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Status
          <select name="status" defaultValue={status} className={inputClass}>
            <option value="">Any status</option>
            {(Object.keys(REQUEST_STATUS) as RequestStatus[]).map((s) => (
              <option key={s} value={s}>
                {REQUEST_STATUS[s].label}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1 text-sm font-semibold">
          Type
          <select name="type" defaultValue={type} className={inputClass}>
            <option value="">Any type</option>
            {REQUEST_TYPES.map((t) => (
              <option key={t.key} value={t.key}>
                {t.label}
              </option>
            ))}
          </select>
        </label>
        <button className={buttonClass("primary")}>Filter<FormPending /></button>
        {filtered ? (
          <Link href={`/people/requests${keepTab ? "?tab=all" : ""}`} className={buttonClass("outline")}>
            Clear
          </Link>
        ) : null}
      </form>
      {filtered ? (
        <p className="text-sm text-muted" role="status">
          Showing {rows.length} of {base.length}.
        </p>
      ) : null}

      <RequestList
        rows={rows}
        me={profile.id}
        empty={{ title: filtered ? "No requests match" : tab === "approve" ? "Nothing waiting for you" : "No requests yet", text: filtered ? "Try a different filter, or clear it." : undefined }}
      />
    </>
  );
}
