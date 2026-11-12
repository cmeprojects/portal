// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getPeopleRules } from "@/lib/settings";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { formatDate } from "@/lib/registers";
import { FILES_BUCKET, KIND_LABELS, isDone, stateBadges, type ItemKind, type StatusRow } from "@/lib/compliance";
import { Badge, Card, PageHeader } from "@/components/ui";
import { ClearancePanel, ReviewForm, UploadForPersonForm } from "../../forms";
import { managesComplianceFor, seesComplianceFor } from "@/lib/module-access";

export const metadata: Metadata = { title: "Onboarding progress" };

export default async function PersonCompliancePage({ params }: PageProps<"/compliance/people/[id]">) {
  const { profile: me } = await requireSession();
  const rules = await getPeopleRules();
  if (!(await seesComplianceFor(me.role, rules))) redirect("/");
  const manages = await managesComplianceFor(me.role, rules);
  const { id } = await params;
  const supabase = await createClient();
  const { data: person } = await supabase.from("profiles").select("id, full_name, email, role, joined_at, onboarded_at").eq("id", id).maybeSingle();
  if (!person) notFound();
  const { data } = await supabase.rpc("compliance_status", { p_user: id });
  const status = (data ?? []) as StatusRow[];
  if (!status.length && me.role === "team_leader") redirect("/compliance");

  // Only Compliance managers can open the files (the database checks too).
  const { data: records } = manages
    ? await supabase.from("compliance_records").select("*").eq("user_id", id)
    : { data: [] };
  // cmeprojects (update 58): statuses, clearance and how things were signed.
  const [{ data: work }, { data: canClear }] = await Promise.all([
    supabase.rpc("work_status", { p_user: id }),
    supabase.rpc("can_grant_clearance"),
  ]);
  const ws = work as {
    onboarding_complete: boolean;
    compliance_verified: boolean;
    cleared: boolean;
    cleared_at: string | null;
    cleared_by: string | null;
    before_work_missing: string[];
    override: { id: number; until: string; reason: string; by: string } | null;
  } | null;
  const signed = new Map<number, { name: string; at: string; version: number; signature: string | null }>();
  await Promise.all(
    (records ?? [])
      .filter((r) => r.signed_name)
      .map(async (r) => {
        const sig = r.signature_path ? (await supabase.storage.from(FILES_BUCKET).createSignedUrl(r.signature_path, 600)).data?.signedUrl ?? null : null;
        signed.set(r.id, { name: r.signed_name, at: r.created_at, version: r.version, signature: sig });
      }),
  );
  const today = new Date(new Intl.DateTimeFormat("en-CA", { timeZone: "Australia/Sydney" }).format(new Date()));
  const maxOverride = new Date(today.getTime() + 30 * 86400000).toISOString().slice(0, 10);
  const fileLinks = new Map<
    number,
    { url: string; name: string; at: string; status: string; reviewedBy: string | null; reviewedAt: string | null; uploadedBy: string | null }
  >();
  await Promise.all(
    (records ?? [])
      .filter((r) => r.file_path)
      .map(async (r) => {
        const { data: signed } = await supabase.storage.from(FILES_BUCKET).createSignedUrl(r.file_path!, 600);
        if (signed?.signedUrl)
          fileLinks.set(r.id, {
            url: signed.signedUrl,
            name: r.file_name ?? "file",
            at: r.created_at,
            status: r.status,
            reviewedBy: r.reviewed_by,
            reviewedAt: r.reviewed_at,
            uploadedBy: r.uploaded_by,
          });
      }),
  );
  const done = status.filter((s) => isDone(s.state)).length;
  // Staff admins (Compliance managers) and managers can upload for someone.
  const canUploadFor = (manages || me.role === "manager") && person.id !== me.id;
  const uploadItems = status.filter((s) => s.kind === "upload").map((s) => s.item_id);
  const { data: needsExpiry } = uploadItems.length
    ? await supabase.from("compliance_items").select("id, needs_expiry").in("id", uploadItems)
    : { data: [] as { id: string; needs_expiry: boolean }[] };
  const reviewerIds = [
    ...new Set([...fileLinks.values()].flatMap((f) => [f.reviewedBy, f.uploadedBy]).filter((x): x is string => Boolean(x))),
  ];
  const { data: reviewers } = reviewerIds.length
    ? await supabase.from("profiles").select("id, full_name, email, role").in("id", reviewerIds)
    : { data: [] as { id: string; full_name: string; email: string; role: string }[] };
  // System admins stay hidden from staff.
  const reviewerName = new Map((reviewers ?? []).map((r) => [r.id, r.role === "system_admin" ? "Admin" : r.full_name || r.email]));

  return (
    <>
      <p className="text-sm">
        <Link href="/compliance" className="text-brand underline">Onboarding</Link> / {person.full_name || person.email}
      </p>
      <PageHeader
        title={person.full_name || person.email}
        intro={`${ROLE_LABELS[person.role as Role]} · ${done} of ${status.length} done${person.onboarded_at ? ` · onboarding finished ${formatDate(person.onboarded_at)}` : ""}`}
      />
      {ws ? (
        <Card className="flex flex-col gap-4 p-5">
          <div className="flex flex-wrap gap-2">
            <Badge tone={ws.onboarding_complete ? "good" : "grey"}>{ws.onboarding_complete ? "✓ " : ""}Onboarding complete</Badge>
            <Badge tone={ws.compliance_verified ? "good" : "grey"}>{ws.compliance_verified ? "✓ " : ""}Compliance verified</Badge>
            <Badge tone={ws.cleared ? "good" : ws.override ? "warn" : "grey"}>
              {ws.cleared ? `✓ Cleared to work${ws.cleared_at ? ` ${formatDate(ws.cleared_at.slice(0, 10))}` : ""}${ws.cleared_by ? ` by ${ws.cleared_by}` : ""}` : ws.override ? `Override until ${formatDate(ws.override.until)}` : "Not cleared to work"}
            </Badge>
          </div>
          {ws.override ? (
            <p className="text-sm text-muted">
              Override by {ws.override.by}: {ws.override.reason}
            </p>
          ) : null}
          {!ws.cleared && ws.before_work_missing.length ? (
            <div className="text-sm">
              <p className="font-semibold">Still needed before working</p>
              <ul className="list-disc pl-5 text-muted">
                {ws.before_work_missing.map((t) => (
                  <li key={t}>{t}</li>
                ))}
              </ul>
            </div>
          ) : null}
          {canClear === true && person.id !== me.id ? (
            <ClearancePanel
              userId={person.id}
              name={person.full_name?.split(" ")[0] || "them"}
              cleared={ws.cleared}
              missing={ws.before_work_missing}
              override={ws.override}
              maxDate={maxOverride}
            />
          ) : null}
        </Card>
      ) : null}
      {(["read", "training", "upload", "agreement", "form"] as ItemKind[]).map((kind) => {
        const list = status.filter((s) => s.kind === kind);
        if (!list.length) return null;
        return (
          <Card key={kind} className="overflow-hidden">
            <h2 className="heading-sm border-b border-line px-5 py-3">{KIND_LABELS[kind]}</h2>
            <ul className="divide-y divide-line">
              {list.map((s) => {
                const file = s.record_id ? fileLinks.get(s.record_id) : undefined;
                return (
                  <li key={s.item_id} className="flex flex-col gap-1.5 px-5 py-3">
                    <div className="flex flex-wrap items-center gap-x-3 gap-y-1.5">
                      <span className="min-w-40 flex-1 font-medium">{s.title}</span>
                      {s.expires_on ? <span className="text-sm text-muted">Expires {formatDate(s.expires_on)}</span> : null}
                      {stateBadges(s.state, file?.status).map((b) => (
                        <Badge key={b.label} tone={b.tone}>{b.label}</Badge>
                      ))}
                      {manages && file ? (
                        <a href={file.url} target="_blank" rel="noopener noreferrer" className="text-sm font-semibold text-brand underline">
                          Open file
                        </a>
                      ) : null}
                    </div>
                    {/* One short line: what was uploaded, by whom, and who checked it. */}
                    {manages && file ? (
                      <p className="text-xs text-muted">
                        {file.name} · uploaded {formatDate(file.at)}
                        {file.uploadedBy && file.uploadedBy !== person.id
                          ? ` by ${reviewerName.get(file.uploadedBy) ?? "Admin"} on their behalf`
                          : ""}
                        {/* Uploaded and checked by the same person on their behalf: no need to say it twice. */}
                        {file.status === "accepted" && file.uploadedBy !== person.id && file.reviewedBy === file.uploadedBy
                          ? ""
                          : file.status === "accepted"
                          ? ` · checked${file.reviewedBy ? ` by ${reviewerName.get(file.reviewedBy) ?? "Admin"}` : ""}${file.reviewedAt ? ` ${formatDate(file.reviewedAt)}` : ""}`
                          : file.status === "rejected"
                            ? " · sent back, waiting for a new copy"
                            : " · waiting to be checked"}
                      </p>
                    ) : null}
                    {(s.state === "rejected" || s.state === "replace_requested") && s.note ? <p className="text-xs text-warn">Sent back: {s.note}</p> : null}
                    {s.record_id && signed.get(s.record_id) ? (
                      <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
                        {kind === "agreement" ? "Signed" : "Acknowledged"} by typing &ldquo;{signed.get(s.record_id)!.name}&rdquo; on{" "}
                        {formatDate(signed.get(s.record_id)!.at.slice(0, 10))} · version {signed.get(s.record_id)!.version}
                        {signed.get(s.record_id)!.signature ? (
                          <a href={signed.get(s.record_id)!.signature!} target="_blank" rel="noopener noreferrer" className="font-semibold text-brand underline">
                            View signature
                          </a>
                        ) : null}
                      </p>
                    ) : null}
                    {/* Only uploads waiting to be checked get the buttons. */}
                    {manages && file?.status === "submitted" && s.record_id && person.id !== me.id ? (
                      <div className="mt-1 rounded-md bg-page p-3">
                        <ReviewForm recordId={s.record_id} />
                      </div>
                    ) : null}
                    {canUploadFor && kind === "upload" ? (
                      <details name="upload-for" className="text-sm">
                        <summary className="cursor-pointer text-xs font-semibold text-brand">
                          {s.record_id ? "Upload a new copy" : "Upload"} for {person.full_name?.split(" ")[0] || "them"}
                        </summary>
                        <div className="pt-3">
                          <UploadForPersonForm
                            userId={person.id}
                            itemId={s.item_id}
                            needsExpiry={(needsExpiry ?? []).find((n) => n.id === s.item_id)?.needs_expiry ?? false}
                            checksItself={manages}
                          />
                        </div>
                      </details>
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
