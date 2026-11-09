// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import Link from "next/link";
import { Search, Users } from "lucide-react";
import { Avatar } from "@/components/avatar";
import { EmptyState, inputClass } from "@/components/ui";

export type DirectoryEntry = { id: string; name: string; preferred: string; jobTitle: string; department: string; phone: string; photo?: string; teams: string[]; skills: string[] };

// cmeprojects: the staff directory list: compact rows with a search box. Picking
// someone shows their details beside the list (?p=their id).
export function Directory({ people, selected }: { people: DirectoryEntry[]; selected: string | null }) {
  const [q, setQ] = useState("");
  const term = q.trim().toLowerCase();
  const shown = term
    ? people.filter((p) => [p.name, p.preferred, p.jobTitle, p.department, ...p.teams, ...p.skills].join(" ").toLowerCase().includes(term))
    : people;
  return (
    <div className="flex flex-col gap-4">
      <label className="relative block">
        <span className="sr-only">Search the directory</span>
        <Search aria-hidden="true" className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted" />
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search by name, role, team or skill" className={`${inputClass} pl-9`} />
      </label>
      {shown.length === 0 ? (
        <div className="shadow-card rounded-xl border border-line bg-surface">
          <EmptyState icon={Users} title={term ? "Nobody matches that search" : "No staff yet"} />
        </div>
      ) : (
        <ul className="shadow-card max-h-[calc(100vh-12rem)] divide-y divide-line overflow-y-auto rounded-xl border border-line bg-surface max-lg:max-h-none">
          {shown.map((p) => {
            const on = p.id === selected;
            return (
              <li key={p.id}>
                <Link
                  href={`/people?p=${p.id}`}
                  scroll={false}
                  aria-current={on ? "true" : undefined}
                  className={`flex items-center gap-3 px-4 py-3 transition ${on ? "bg-brand-soft" : "hover:bg-page"}`}
                >
                  <Avatar name={p.name} src={p.photo} size={40} className="bg-brand-soft text-brand" />
                  <span className="min-w-0 flex-1">
                    <span className={`block truncate font-semibold ${on ? "text-brand" : "text-ink"}`}>{p.name}</span>
                    <span className="block truncate text-xs text-muted">
                      {p.jobTitle}
                      {p.department ? ` · ${p.department}` : ""}
                      {p.teams.length ? ` · ${p.teams.join(", ")}` : ""}
                    </span>
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
