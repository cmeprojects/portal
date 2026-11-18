// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { Card, Notice, PageHeader } from "@/components/ui";
import { mayManageShiftTypes } from "./actions";
import { AddShiftTypeForm, ShiftTypeRow } from "./forms";

export const metadata: Metadata = { title: "Shift types" };

// cmeprojects (update 141): the shift types offered when adding a shift.
// Manager Administrators add, rename and switch them off; a type in use is
// never deleted. Cost codes attach here later, through funding and pricing.
export default async function ShiftTypesPage() {
  await requireSession();
  if (!(await canDo("ops.roster", "view"))) notFound();
  const supabase = await createClient();
  const [{ data, error }, manage, { data: used }] = await Promise.all([
    supabase.from("shift_types").select("*").order("sort_order").order("label"),
    mayManageShiftTypes(),
    supabase.from("shifts").select("shift_type").neq("status", "cancelled").limit(20000),
  ]);
  const count = new Map<string, number>();
  for (const r of (used ?? []) as { shift_type: string }[]) count.set(r.shift_type, (count.get(r.shift_type) ?? 0) + 1);
  const types = ((data ?? []) as { key: string; label: string; active: boolean; used_for?: string }[]).map((t) => ({ ...t, used: count.get(t.key) ?? 0 }));
  return (
    <div className="flex flex-col gap-5">
      <PageHeader eyebrow="Rostering" title="Shift types" intro="The types offered when adding a shift. Switching one off hides it for new shifts; shifts that already have it keep it." action={<Link href="/roster" className="text-sm font-semibold text-brand underline">Back to the roster</Link>} />
      {error ? <Notice tone="info">Shift types can be managed once update 141 has been run.</Notice> : null}
      {!manage ? <Notice tone="info">Only Manager Administrators can change shift types.</Notice> : null}
      {manage && !error ? (
        <Card className="p-4">
          <AddShiftTypeForm withUse={types.some((t) => t.used_for !== undefined)} />
        </Card>
      ) : null}
      {types.length ? (
        <Card className="divide-y divide-line p-0">
          {manage
            ? types.map((t) => <ShiftTypeRow key={t.key} type={t} />)
            : types.map((t) => (
                <p key={t.key} className="flex justify-between px-4 py-2.5 text-sm">
                  <span className={t.active ? "" : "text-muted line-through"}>
                    {t.label}
                    {t.used_for ? <span className="ml-2 text-xs text-muted">{t.used_for === "internal" ? "internal work" : t.used_for === "both" ? "client or internal" : "client shifts"}</span> : null}
                  </span>
                  <span className="text-xs text-muted">{t.used ? `${t.used} shifts` : ""}</span>
                </p>
              ))}
        </Card>
      ) : null}
      <p className="text-xs text-muted">Cost codes for each type will be set here once funding and pricing are set up.</p>
    </div>
  );
}
