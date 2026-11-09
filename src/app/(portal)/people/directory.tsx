// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import Link from "next/link";
import { Search, Users } from "lucide-react";
import { Avatar } from "@/components/avatar";
import { EmptyState, inputClass } from "@/components/ui";

export type DirectoryEntry = { id: string; name: string; preferred: string; jobTitle: string; department: string; phone: string; photo?: string; teams: string[]; skills: string[] };

// cmeprojects: the staff directory: photo cards with a search box.
export function Directory({ people }: { people: DirectoryEntry[] }) {
  const [q, setQ] = useState("");
  const term = q.trim().toLowerCase();
  const shown = term
    ? people.filter((p) => [p.name, p.preferred, p.jobTitle, p.department, ...p.teams, ...p.skills].join(" ").toLowerCase().includes(term))
    : people;
  return (
    <div className="flex flex-col gap-4">
      <label className="relative block max-w-md">
        <span className="sr-only">Search the directory</span>
        <Search aria-hidden="true" className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted" />
        <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search by name, role, team or skill" className={`${inputClass} pl-9`} />
      </label>
      {shown.length === 0 ? (
        <div className="shadow-card rounded-xl border border-line bg-surface">
          <EmptyState icon={Users} title={term ? "Nobody matches that search" : "No staff yet"} />
        </div>
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {shown.map((p) => (
            <li key={p.id}>
              <Link href={`/people/${p.id}`} className="shadow-card flex h-full gap-3 rounded-xl border border-line bg-surface p-4 transition hover:-translate-y-0.5 hover:border-brand/40 hover:shadow-lg">
                <Avatar name={p.name} src={p.photo} size={52} className="bg-brand-soft text-brand" />
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-semibold text-ink">{p.name}</span>
                  <span className="block truncate text-sm text-muted">
                    {p.jobTitle}
                    {p.department ? ` · ${p.department}` : ""}
                  </span>
                  {p.teams.length ? <span className="block truncate text-xs text-muted">{p.teams.join(", ")}</span> : null}
                  {p.phone ? <span className="mt-1 block text-xs text-brand">{p.phone}</span> : null}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
