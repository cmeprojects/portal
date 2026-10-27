// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useMemo, useState } from "react";
import { inputClass } from "@/components/ui";

export type Person = { id: string; name: string; detail: string };

// Choose several people: a search box over a list of checkboxes.
export function PeopleChecklist({
  name,
  people,
  exclude = [],
  label,
}: {
  name: string;
  people: Person[];
  exclude?: string[];
  label: string;
}) {
  const [query, setQuery] = useState("");
  const [chosen, setChosen] = useState<string[]>([]);
  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    return people.filter((p) => !exclude.includes(p.id) && (!q || `${p.name} ${p.detail}`.toLowerCase().includes(q)));
  }, [people, exclude, query]);

  return (
    <fieldset className="flex flex-col gap-2">
      <legend className="mb-1.5 text-sm font-semibold">{label}</legend>
      {people.length > 6 ? (
        <input
          type="search"
          aria-label={`Search ${label.toLowerCase()}`}
          placeholder="Search by name"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          className={inputClass}
        />
      ) : null}
      <div className="flex max-h-64 flex-col overflow-y-auto rounded-md border border-line">
        {shown.length === 0 ? <p className="p-3 text-sm text-muted">No one matches.</p> : null}
        {shown.map((p) => (
          <label key={p.id} className="flex min-h-12 items-center gap-3 border-b border-line px-3 last:border-b-0">
            <input
              type="checkbox"
              name={name}
              value={p.id}
              checked={chosen.includes(p.id)}
              onChange={(e) => setChosen(e.target.checked ? [...chosen, p.id] : chosen.filter((c) => c !== p.id))}
              className="h-5 w-5 accent-[var(--brand-primary)]"
            />
            <span className="flex flex-col">
              <span className="text-sm font-semibold">{p.name}</span>
              <span className="text-sm text-muted">{p.detail}</span>
            </span>
          </label>
        ))}
      </div>
      {/* Keep choices that the search is hiding. */}
      {chosen
        .filter((id) => !shown.some((p) => p.id === id) && !exclude.includes(id))
        .map((id) => (
          <input key={id} type="hidden" name={name} value={id} />
        ))}
      {chosen.length ? <p className="text-sm text-muted">{chosen.length} chosen</p> : null}
    </fieldset>
  );
}
