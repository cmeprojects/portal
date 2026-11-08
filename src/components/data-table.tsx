// Staff Portal · © cmeproject. All rights reserved.
import { EmptyState } from "@/components/ui";
import { Inbox } from "lucide-react";
import Link from "next/link";
import type { Table } from "@/lib/register-rows";
import { CHOICE_COLOUR_CLASS } from "@/lib/registers";

export function DataTable({ table, empty }: { table: Table; empty: string }) {
  if (table.rows.length === 0) return <EmptyState icon={Inbox} title={empty} />;
  const [refCol, titleCol, ...rest] = table.columns;
  return (
    <>
    {/* cmeprojects: on a phone each row is a small card instead of a wide table. */}
    <ul className="divide-y divide-line md:hidden">
      {table.rows.map((row) => {
        const title = titleCol ? row.cells[titleCol.key]?.text : row.cells[refCol.key]?.text;
        const body = (
          <>
            {titleCol ? <span className="block text-xs text-muted">{row.cells[refCol.key]?.text}</span> : null}
            <span className="block font-semibold text-ink">{title || "—"}</span>
            <dl className="mt-1.5 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-sm">
              {rest
                .filter((c) => row.cells[c.key]?.text)
                .slice(0, 5)
                .map((c) => {
                  const cell = row.cells[c.key]!;
                  return (
                    <div key={c.key} className="contents">
                      <dt className="text-muted">{c.label}</dt>
                      <dd className={`min-w-0 ${cell.tone === "danger" ? "font-semibold text-danger" : ""}`}>
                        {cell.badge ? (
                          <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${CHOICE_COLOUR_CLASS[cell.badge]}`}>{cell.text}</span>
                        ) : (
                          <span className="line-clamp-2">{cell.text}</span>
                        )}
                      </dd>
                    </div>
                  );
                })}
            </dl>
          </>
        );
        return (
          <li key={row.id}>
            {row.href ? (
              <Link href={row.href} className="block px-4 py-3 hover:bg-page">
                {body}
              </Link>
            ) : (
              <div className="px-4 py-3">{body}</div>
            )}
          </li>
        );
      })}
    </ul>
    <div className="hidden overflow-x-auto md:block">
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="text-left text-xs uppercase tracking-wide text-muted">
            {table.columns.map((c) => (
              <th key={c.key} scope="col" className={`whitespace-nowrap px-4 py-3 font-semibold ${c.wide ? "min-w-64" : ""}`}>
                {c.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {table.rows.map((row) => (
            <tr key={row.id} className="border-t border-line align-top hover:bg-page">
              {table.columns.map((c, i) => {
                const cell = row.cells[c.key];
                const tone = cell?.tone === "danger" ? "font-semibold text-danger" : cell?.tone === "muted" ? "text-muted" : "";
                return (
                  <td key={c.key} className={`px-4 py-3 ${c.wide ? "max-w-md" : "whitespace-nowrap"} ${tone}`}>
                    {i <= 1 && row.href ? (
                      <Link href={row.href} className={`${i === 1 ? "font-semibold text-ink" : "text-muted"} hover:text-brand`}>
                        {cell?.text}
                      </Link>
                    ) : cell?.badge && cell.text ? (
                      <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ${CHOICE_COLOUR_CLASS[cell.badge]}`}>{cell.text}</span>
                    ) : (
                      <span className={`${c.wide ? "line-clamp-3" : ""} ${i === 0 && !row.href ? "font-semibold" : ""}`}>{cell?.text}</span>
                    )}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
    </>
  );
}
