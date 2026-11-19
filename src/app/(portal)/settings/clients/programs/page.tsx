// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { managesPrograms } from "@/lib/programs-access";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { AddProgramForm, ProgramRow, SchemeRow, type Scheme } from "../care-forms";

export const metadata: Metadata = { title: "Programs and schemes" };

// cmeprojects (owner, 19 Nov 2026; update 152): programs and schemes, in Portal
// settings for the system admin and Manager Administrators (and anyone given the
// Care settings area). The database checks too.
export default async function ProgramsPage() {
  await requireSession();
  if (!(await managesPrograms())) notFound();
  const supabase = await createClient();
  const [{ data: programRows }, schemeRes, { data: wordRow }] = await Promise.all([
    supabase.from("client_programs").select("id, name, needs_dob, active, scheme").order("sort_order").order("name"),
    supabase.from("client_schemes").select("key, label, person_word, review_label, change_review_label, review_lead_days, needs_dob").order("sort_order"),
    supabase.from("app_settings").select("value").eq("key", "wording.client").maybeSingle(),
  ]);
  const programs = (programRows ?? []) as { id: string; name: string; needs_dob: boolean; active: boolean; scheme: string }[];
  const schemes = schemeRes.error ? [] : ((schemeRes.data ?? []) as Scheme[]);
  const orgWord = typeof wordRow?.value === "string" && wordRow.value ? wordRow.value : "Client";
  return (
    <div className="flex flex-col gap-4">
      <PageHeader
        eyebrow="Portal settings"
        title="Programs and schemes"
        intro="Every program sits under one scheme (NDIS, Support at Home, CHSP, Private or Other). The scheme decides the wording and rules, so they never mix."
        action={
          <Link href="/settings" className="text-sm font-semibold text-brand underline">
            Back to settings
          </Link>
        }
      />
      <Card className="p-4">
        <h2 className="heading-sm">Programs</h2>
        <p className="mb-2 text-sm text-muted">Add or rename programs, or untick In use. A program is never deleted, and its scheme can&apos;t change once a service uses it.</p>
        <ul className="divide-y divide-line">
          {programs.map((p) => (
            <ProgramRow key={p.id} program={p} canEdit schemes={schemes} />
          ))}
        </ul>
        {schemes.length ? <AddProgramForm schemes={schemes} /> : null}
      </Card>
      {schemes.length ? (
        <Card className="p-4">
          <h2 className="heading-sm">Schemes: wording and rules</h2>
          <ul className="divide-y divide-line">
            {schemes.map((sc) => (
              <SchemeRow key={sc.key} scheme={sc} canEdit orgWord={orgWord} />
            ))}
          </ul>
        </Card>
      ) : null}
    </div>
  );
}
