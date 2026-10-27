// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { Table } from "@/lib/register-rows";

export function DataTable({ table, empty }: { table: Table; empty: string }) {
  if (table.rows.length === 0) return <p className="p-6 text-[15px] text-muted">{empty}</p>;
  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse text-[15px]">
        <thead>
          <tr className="text-left text-[13px] uppercase tracking-wide text-muted">
            {table.columns.map((c) => (
              <th key={c.key} scope="col" className={`whitespace-nowrap px-4 py-3 font-bold ${c.wide ? "min-w-64" : ""}`}>
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
                    {i <= 1 ? (
                      <Link href={row.href} className={`${i === 1 ? "font-bold text-ink" : "text-muted"} hover:text-brand`}>
                        {cell?.text}
                      </Link>
                    ) : (
                      <span className={c.wide ? "line-clamp-3" : ""}>{cell?.text}</span>
                    )}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
