// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { canManageCompliance, getPeopleRules, seesCompliance } from "@/lib/settings";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { formatDate } from "@/lib/registers";
import { FILES_BUCKET, KIND_LABELS, STATE_LABELS, STATE_TONE, isDone, type ItemKind, type StatusRow } from "@/lib/compliance";
import { Badge, Card, PageHeader } from "@/components/ui";
import { ReviewForm } from "../../forms";

export const metadata: Metadata = { title: "Onboarding progress" };

export default async function PersonCompliancePage({ params }: PageProps<"/compliance/people/[id]">) {
  const { profile: me } = await requireSession();
  const rules = await getPeopleRules();
  if (!seesCompliance(me.role, rules)) redirect("/");
  const manages = canManageCompliance(me.role, rules);
  const { id } = await params;
  const supabase = await createClient();
  const { data: person } = await supabase.from("profiles").select("id, full_name, email, role, joined_at, onboarded_at").eq("id", id).maybeSingle();
  if (!person) notFound();
  const { data } = await supabase.rpc("compliance_status", { p_user: id });
  const status = (data ?? []) as StatusRow[];
  if (!status.length && me.role === "team_leader") redirect("/compliance");

  // Only Compliance managers can open the files (the database checks too).
  const { data: records } = manages
    ? await supabase.from("compliance_records").select("id, file_path, file_name, created_at").eq("user_id", id)
    : { data: [] };
  const fileLinks = new Map<number, { url: string; name: string; at: string }>();
  await Promise.all(
    (records ?? [])
      .filter((r) => r.file_path)
      .map(async (r) => {
        const { data: signed } = await supabase.storage.from(FILES_BUCKET).createSignedUrl(r.file_path!, 600);
        if (signed?.signedUrl) fileLinks.set(r.id, { url: signed.signedUrl, name: r.file_name ?? "file", at: r.created_at });
      }),
  );
  const done = status.filter((s) => isDone(s.state)).length;

  return (
    <>
      <p className="text-sm">
        <Link href="/compliance" className="text-brand underline">Compliance</Link> / Onboarding progress
      </p>
      <PageHeader
        title={person.full_name || person.email}
        intro={`${ROLE_LABELS[person.role as Role]} · ${done} of ${status.length} done${person.onboarded_at ? ` · onboarding finished ${formatDate(person.onboarded_at)}` : ""}`}
      />
      {(["read", "training", "upload"] as ItemKind[]).map((kind) => {
        const list = status.filter((s) => s.kind === kind);
        if (!list.length) return null;
        return (
          <Card key={kind} className="overflow-hidden">
            <h2 className="heading-sm border-b border-line px-5 py-3">{KIND_LABELS[kind]}</h2>
            <ul className="divide-y divide-line">
              {list.map((s) => {
                const file = s.record_id ? fileLinks.get(s.record_id) : undefined;
                return (
                  <li key={s.item_id} className="flex flex-col gap-3 px-5 py-3">
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
                      <span className="min-w-48 flex-1 font-medium">{s.title}</span>
                      {s.expires_on ? <span className="text-sm text-muted">Expires {formatDate(s.expires_on)}</span> : null}
                      <Badge tone={STATE_TONE[s.state]}>{STATE_LABELS[s.state]}</Badge>
                    </div>
                    {s.state === "rejected" && s.note ? <p className="text-sm text-warn">Sent back: {s.note}</p> : null}
                    {manages && file ? (
                      <div className="flex flex-col gap-3 rounded-md bg-page p-3">
                        <a href={file.url} target="_blank" rel="noopener noreferrer" className="text-sm font-semibold text-brand underline">
                          Open {file.name} (uploaded {formatDate(file.at)})
                        </a>
                        {s.record_id && person.id !== me.id ? <ReviewForm recordId={s.record_id} /> : null}
                      </div>
                    ) : null}
                  </li>
                );
              })}
            </ul>
          </Card>
        );
      })}
      {status.length === 0 ? <p className="text-sm text-muted">Nothing applies to them yet.</p> : null}
    </>
  );
}
