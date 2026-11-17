// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useMemo, useState } from "react";
import { Eye, Pencil, Search } from "lucide-react";
import { Avatar } from "@/components/avatar";
import { inputClass } from "@/components/ui";

export type StaffRow = {
  id: string;
  name: string;
  email: string;
  photo: string | null;
  role: string;
  sub: string;
  team: string;
  employment: string;
  startDate: string;
  status: string;
  // Expired, expiring within 60 days, and onboarding still to do.
  expired: number;
  expiring: number;
  todo: number;
  conditional: boolean;
  waiting: boolean;
  leaving: string;
  hours: number | null;
  nextShift: string;
  tag: string;
  protectedAdmin: boolean;
};

const day = (d: string) => (d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

export function ChecksChip({ r }: { r: Pick<StaffRow, "expired" | "expiring" | "todo" | "status"> }) {
  if (r.status === "Deactivated") return <span className="text-xs text-muted">—</span>;
  const n = r.expired + r.expiring;
  if (r.expired) return <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">{n} {n === 1 ? "check needs" : "checks need"} action</span>;
  if (r.expiring) return <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold text-ink">{n} expiring soon</span>;
  if (r.todo) return <span className="rounded-full bg-yellow-soft px-2 py-0.5 text-xs font-semibold text-ink">Onboarding: {r.todo} to do</span>;
  return <span className="rounded-full bg-good-soft px-2 py-0.5 text-xs font-semibold text-ink">All checks current</span>;
}

// cmeprojects (owner's concept, 17 Nov 2026): the staff list as a table; a
// row opens the person on the right (Details, Access, Compliance, Tasks).
export function StaffTable({ rows, selected, showTeams, showRoster = false }: { rows: StaffRow[]; selected: string | null; showTeams: boolean; showRoster?: boolean }) {
  const router = useRouter();
  const path = usePathname();
  const params = useSearchParams();
  const [q, setQ] = useState("");
  const [show, setShow] = useState<"current" | "onboarding" | "action" | "deactivated" | "all">("current");
  const list = useMemo(() => {
    const term = q.trim().toLowerCase();
    return rows.filter(
      (r) =>
        (show === "all" ||
          (show === "current" && r.status !== "Deactivated") ||
          (show === "deactivated" && r.status === "Deactivated") ||
          (show === "onboarding" && r.status !== "Deactivated" && r.status !== "Active") ||
          (show === "action" && r.status !== "Deactivated" && (r.expired > 0 || r.expiring > 0 || r.waiting || !!r.leaving))) &&
        (!term || [r.name, r.email, r.role, r.sub, r.team].some((v) => v.toLowerCase().includes(term))),
    );
  }, [rows, q, show]);
  const open = (id: string) => {
    const next = new URLSearchParams(params.toString());
    next.set("p", id);
    next.delete("t");
    router.push(`${path}?${next.toString()}`, { scroll: false });
  };
  return (
    <div className="shadow-card flex flex-col rounded-xl border border-line bg-surface">
      <div className="flex flex-wrap items-center gap-2 p-3">
        <label className="relative min-w-48 flex-1">
          <span className="sr-only">Search staff</span>
          <Search aria-hidden="true" className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted" />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search name, email, role or team" className={`${inputClass} pl-8`} />
        </label>
        <select aria-label="Show" value={show} onChange={(e) => setShow(e.target.value as typeof show)} className={`${inputClass.replace("w-full", "")} w-full sm:w-52`}>
          <option value="current">Current staff</option>
          <option value="onboarding">Invited and onboarding</option>
          <option value="action">Needs action</option>
          <option value="deactivated">Deactivated</option>
          <option value="all">Everyone</option>
        </select>
      </div>
      {list.length ? (
        <div className="overflow-x-auto">
          <table className={`w-full text-sm ${showRoster ? "min-w-[60rem]" : "min-w-[44rem]"}`}>
            <thead className="border-y border-line bg-page/60 text-left text-xs font-semibold text-muted">
              <tr>
                <th scope="col" className="px-3 py-2">Name</th>
                <th scope="col" className="px-3 py-2">Role</th>
                {showTeams ? <th scope="col" className="px-3 py-2">Team</th> : null}
                <th scope="col" className="px-3 py-2">Employment</th>
                {showRoster ? <th scope="col" className="px-3 py-2">Hours this week</th> : null}
                {showRoster ? <th scope="col" className="px-3 py-2">Next shift</th> : null}
                <th scope="col" className="px-3 py-2">Status</th>
                <th scope="col" className="px-3 py-2">Compliance</th>
                <th scope="col" className="px-3 py-2 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-line">
              {list.map((r) => (
                <tr key={r.id} onClick={() => open(r.id)} className={`cursor-pointer hover:bg-page/70 ${selected === r.id ? "bg-brand-soft/40" : ""} ${r.status === "Deactivated" ? "text-muted" : ""}`}>
                  <td className="px-3 py-2">
                    <span className="flex items-center gap-3">
                      <Avatar name={r.name} src={r.photo ?? undefined} size={34} className="bg-brand-soft text-brand" />
                      <span className="min-w-0">
                        <button type="button" onClick={() => open(r.id)} className="block text-left font-semibold hover:text-brand">
                          {r.name}
                          {r.tag ? <span className="font-normal text-muted"> ({r.tag})</span> : null}
                        </button>
                        <span className="block truncate text-xs text-muted">{r.email}</span>
                      </span>
                    </span>
                  </td>
                  <td className="px-3 py-2">
                    {r.protectedAdmin ? <span className="rounded-full bg-ink px-2 py-0.5 text-xs font-semibold text-surface">Developer · protected</span> : <span className="block font-medium">{r.role}</span>}
                    {r.sub ? <span className="block text-xs text-muted">{r.sub}</span> : null}
                  </td>
                  {showTeams ? <td className="px-3 py-2 text-muted">{r.team}</td> : null}
                  <td className="px-3 py-2">
                    {r.employment || <span className="text-muted">—</span>}
                    {r.startDate ? <span className="block text-xs text-muted">since {day(r.startDate)}</span> : null}
                  </td>
                  {showRoster ? <td className={`px-3 py-2 tabular-nums ${(r.hours ?? 0) > 38 ? "font-semibold text-warn" : ""}`}>{r.hours === null ? "" : r.hours ? r.hours.toFixed(1) : "—"}</td> : null}
                  {showRoster ? (
                    <td className="px-3 py-2 text-xs">
                      {r.nextShift ? new Date(r.nextShift).toLocaleString("en-AU", { timeZone: "Australia/Sydney", weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit", hourCycle: "h23" }) : <span className="text-muted">—</span>}
                    </td>
                  ) : null}
                  <td className="px-3 py-2">
                    <span className="flex flex-wrap gap-1">
                      <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${r.status === "Active" ? "bg-good-soft" : r.status === "Deactivated" ? "bg-line" : "bg-brand-soft"}`}>{r.status}</span>
                      {r.conditional ? <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">Conditional</span> : null}
                      {r.waiting ? <span className="rounded-full bg-warn-soft px-2 py-0.5 text-xs font-semibold">Role change waiting</span> : null}
                      {r.leaving ? <span className="rounded-full bg-danger-soft px-2 py-0.5 text-xs font-semibold text-danger">Leaving {day(r.leaving)}</span> : null}
                    </span>
                  </td>
                  <td className="px-3 py-2">
                    <ChecksChip r={r} />
                  </td>
                  <td className="px-3 py-2" onClick={(e) => e.stopPropagation()}>
                    <span className="flex justify-end gap-1">
                      <Link href={`/settings/staff/${r.id}`} title="View" aria-label={`View ${r.name}`} className="inline-flex size-8 items-center justify-center rounded-full bg-brand-soft text-brand hover:opacity-80">
                        <Eye aria-hidden="true" className="size-4" />
                      </Link>
                      {r.protectedAdmin ? null : (
                        <Link href={`/settings/staff/${r.id}?edit=info`} title="Edit" aria-label={`Edit ${r.name}`} className="inline-flex size-8 items-center justify-center rounded-full bg-good-soft text-ink hover:opacity-80">
                          <Pencil aria-hidden="true" className="size-4" />
                        </Link>
                      )}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <p className="px-4 pb-6 pt-2 text-center text-sm text-muted">Nobody matches.</p>
      )}
    </div>
  );
}
