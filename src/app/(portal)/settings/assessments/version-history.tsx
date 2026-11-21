// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { AQuestion, ASection } from "@/lib/assessment-rules";

// cmeprojects (update 160): template version control. Who drafted and published
// each version, from when, how many assessments use it, and a read-only list of
// what changed from the version before. Published versions never change.
export type VersionRow = { id: string; version: number; status: "draft" | "published" | "retired"; effective_from: string | null; published_at: string | null; created_by: string | null; created_at: string | null; published_by: string | null };

const day = (v: string | null) => (v ? new Date(v.length === 10 ? `${v}T00:00:00` : v).toLocaleDateString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric" }) : "");

export function VersionHistory({ templateId, versions, names, uses, shownId }: { templateId: string; versions: VersionRow[]; names: Map<string, string>; uses: Map<string, number>; shownId?: string }) {
  const who = (id: string | null) => (id ? (names.get(id) ?? "someone") : "set up by the portal");
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[36rem] text-left text-sm">
        <caption className="sr-only">Version history</caption>
        <thead className="text-xs text-muted">
          <tr>
            <th className="py-1 pr-3 font-semibold">Version</th>
            <th className="py-1 pr-3 font-semibold">Status</th>
            <th className="py-1 pr-3 font-semibold">Drafted</th>
            <th className="py-1 pr-3 font-semibold">Published</th>
            <th className="py-1 pr-3 font-semibold">Used from</th>
            <th className="py-1 text-right font-semibold">Assessments</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-line">
          {versions.map((v) => (
            <tr key={v.id} className={v.id === shownId ? "bg-page" : ""}>
              <td className="py-1.5 pr-3">
                <Link href={`/settings/assessments/${templateId}?v=${v.version}`} className="font-semibold text-brand underline">
                  v{v.version}
                </Link>
              </td>
              <td className="py-1.5 pr-3">{v.status === "draft" ? "Draft" : v.status === "published" ? "Published (in use)" : "Retired"}</td>
              <td className="py-1.5 pr-3 text-xs">
                {who(v.created_by)}
                {v.created_at ? `, ${day(v.created_at)}` : ""}
              </td>
              <td className="py-1.5 pr-3 text-xs">{v.published_at ? `${who(v.published_by)}, ${day(v.published_at)}` : "–"}</td>
              <td className="py-1.5 pr-3 text-xs">{v.effective_from ? day(v.effective_from) : "–"}</td>
              <td className="py-1.5 text-right">{uses.get(v.id) ?? 0}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

type Q = AQuestion & { sectionTitle?: string };
const FIELDS: [keyof AQuestion | "sectionTitle", string][] = [
  ["label", "wording"],
  ["type", "kind of answer"],
  ["required", "required"],
  ["help", "help text"],
  ["options", "options"],
  ["validation", "limits"],
  ["rule", "show-only-when rule"],
  ["mappings", "findings it makes"],
  ["sectionTitle", "section"],
];
const same = (a: unknown, b: unknown) => JSON.stringify(a ?? null) === JSON.stringify(b ?? null);

// Compares two versions by question key and section title.
export function whatChanged(prevSections: ASection[], prevQs: AQuestion[], sections: ASection[], qs: AQuestion[]): string[] {
  const out: string[] = [];
  const title = (list: ASection[], id: string) => list.find((s) => s.id === id)?.title ?? "";
  const prevTitles = new Map(prevSections.map((s) => [s.title, s]));
  const nowTitles = new Map(sections.map((s) => [s.title, s]));
  for (const s of sections) {
    const p = prevTitles.get(s.title);
    if (!p) out.push(`Section added: "${s.title}"`);
    else {
      if (p.enabled !== s.enabled) out.push(`Section "${s.title}" ${s.enabled ? "switched on" : "switched off"}`);
      if (!same(p.rule, s.rule)) out.push(`Section "${s.title}": show-only-when rule changed`);
    }
  }
  for (const p of prevSections) if (!nowTitles.has(p.title)) out.push(`Section removed or renamed: "${p.title}"`);
  const prev = new Map<string, Q>(prevQs.map((q) => [q.key, { ...q, sectionTitle: title(prevSections, q.section_id) }]));
  const now = new Map<string, Q>(qs.map((q) => [q.key, { ...q, sectionTitle: title(sections, q.section_id) }]));
  for (const [key, q] of now) {
    const p = prev.get(key);
    if (!p) {
      out.push(`Question added: "${q.label}"`);
      continue;
    }
    const changed = FIELDS.filter(([f]) => !same(p[f as keyof Q], q[f as keyof Q])).map(([, l]) => l);
    if (changed.length) out.push(`"${q.label}": ${changed.join(", ")} changed${!same(p.type, q.type) ? " (answers aren't reused across a different kind of answer)" : ""}`);
  }
  for (const [key, p] of prev) if (!now.has(key)) out.push(`Question removed: "${p.label}"`);
  return out;
}

export function WhatChanged({ from, to, changes }: { from: number; to: number; changes: string[] }) {
  return (
    <div className="flex flex-col gap-2">
      <h3 className="text-sm font-semibold">
        What changed from v{from} to v{to}
      </h3>
      {changes.length ? (
        <ul className="list-disc pl-5 text-sm">
          {changes.map((c, i) => (
            <li key={i}>{c}</li>
          ))}
        </ul>
      ) : (
        <p className="text-sm text-muted">No changes to sections or questions.</p>
      )}
    </div>
  );
}
