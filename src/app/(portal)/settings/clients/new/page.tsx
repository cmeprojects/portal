// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { PageHeader } from "@/components/ui";
import { NewClientFullForm, NewClientHeading } from "./new-client-form";

export const metadata: Metadata = { title: "New client" };

// cmeprojects (owner, 19 Nov 2026): the full New participant page. The pop-up's
// answers arrive in the address and fill the form; nothing is saved until Save.
export default async function NewClientPage({ searchParams }: PageProps<"/settings/clients/new">) {
  await requireSession();
  if (!(await canDo("clients.list", "edit"))) notFound();
  const sp = await searchParams;
  const initial: Record<string, string> = {};
  for (const k of ["name", "scheme", "ndis_number", "aged_care_id", "reference", "manager_id", "assigned_as"]) {
    const v = sp[k];
    if (typeof v === "string") initial[k] = v.slice(0, 120);
  }
  const supabase = await createClient();
  const [{ data: schemeRows }, { data: wordRow }, canAssign] = await Promise.all([
    supabase.from("client_schemes").select("key, label, person_word").order("sort_order"),
    supabase.from("app_settings").select("value").eq("key", "wording.client").maybeSingle(),
    canDo("clients.assign", "edit"),
  ]);
  const schemeList = (schemeRows ?? []) as { key: string; label: string; person_word: string | null }[];
  const word = typeof wordRow?.value === "string" && wordRow.value ? wordRow.value : "Client";
  // Who can manage them: care partners (Case Managers, main or extra job title) and managers.
  const [{ data: staffRows }, { data: cmTitles }] = canAssign
    ? await Promise.all([
        supabase.from("profiles").select("*").eq("active", true).not("role", "in", "(new_starter,system_admin,external)").order("full_name"),
        supabase.from("job_titles").select("id").ilike("name", "case manager%"),
      ])
    : [{ data: null }, { data: [] }];
  const cmIds = new Set(((cmTitles ?? []) as { id: string }[]).map((t) => t.id));
  const staff = staffRows
    ? (staffRows as { id: string; full_name: string | null; email: string; role: string; job_title_id: string | null; extra_job_title_ids?: string[] }[])
        .filter((p) => p.role === "manager" || (p.job_title_id && cmIds.has(p.job_title_id)) || (p.extra_job_title_ids ?? []).some((t) => cmIds.has(t)))
        .map((p) => ({ id: p.id, name: `${p.full_name || p.email}${p.role === "manager" ? " (Manager)" : " (Case Manager)"}` }))
    : null;
  return (
    <div className="flex flex-col gap-4">
      <PageHeader eyebrow="Step 1 of 4: Basic details" title={<NewClientHeading word={word} schemes={schemeList.map((x) => [x.key, x.label] as [string, string])} schemeWords={Object.fromEntries(schemeList.map((x) => [x.key, x.person_word ?? ""]))} />} intro="Check what came from the pop-up and add the rest. Nothing is saved until you press Save; they're then added as “To check”." />
      <NewClientFullForm initial={initial} schemes={schemeList.map((s) => [s.key, s.label])} staff={staff} word={word} />
    </div>
  );
}
