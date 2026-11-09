// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireSession } from "@/lib/session";
import { formsInOnboarding, onboardingOn } from "@/lib/feature-parts";
import { redirect } from "next/navigation";
import { getFormsToFill } from "@/lib/forms";
import { createClient } from "@/lib/supabase/server";
import { formatDate } from "@/lib/registers";
import {
  KIND_LABELS,
  LIBRARY_BUCKET,
  isDone,
  stateBadges,
  type ComplianceItem,
  type ItemKind,
  type StatusRow,
} from "@/lib/compliance";
import Link from "next/link";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { ConfirmButton, UploadForm } from "./forms";

export const metadata: Metadata = { title: "My onboarding" };

const KINDS: ItemKind[] = ["read", "training", "upload", "form"];

export default async function MyOnboardingPage() {
  const { profile, features } = await requireSession();
  // Only while at least one compliance part is on (cmeprojects); forms follow Forms.
  if (!onboardingOn(features)) redirect(features.forms === true ? "/forms" : "/");
  const supabase = await createClient();
  const [{ data: rows }, sentForms] = await Promise.all([
    supabase.rpc("compliance_status", { p_user: profile.id }),
    formsInOnboarding(features) ? getFormsToFill(profile.id) : Promise.resolve([]),
  ]);
  const status = (rows ?? []) as StatusRow[];
  const ids = status.map((s) => s.item_id);
  const [{ data: itemRows }, { data: records }] = await Promise.all([
    ids.length ? supabase.from("compliance_items").select("*").in("id", ids) : Promise.resolve({ data: [] }),
    supabase
      .from("compliance_records")
      .select("id, file_name, created_at, status, uploaded_by")
      .eq("user_id", profile.id),
  ]);
  // Who uploaded things for this person (staff admins or managers).
  const uploaderIds = [...new Set((records ?? []).map((r) => r.uploaded_by).filter((x): x is string => Boolean(x) && x !== profile.id))];
  const { data: uploaders } = uploaderIds.length
    ? await supabase.from("profiles").select("id, full_name, email, role").in("id", uploaderIds)
    : { data: [] as { id: string; full_name: string; email: string; role: string }[] };
  const uploaderName = new Map((uploaders ?? []).map((u) => [u.id, u.role === "system_admin" ? "Admin" : u.full_name || u.email]));
  const items = new Map(((itemRows ?? []) as ComplianceItem[]).map((i) => [i.id, i]));
  // Library files (policies, training material) open through short-lived links.
  const links = new Map<string, string>();
  await Promise.all(
    [...items.values()]
      .filter((i) => i.file_path)
      .map(async (i) => {
        const { data } = await supabase.storage.from(LIBRARY_BUCKET).createSignedUrl(i.file_path!, 3600);
        if (data?.signedUrl) links.set(i.id, data.signedUrl);
      }),
  );
  const done = status.filter((s) => isDone(s.state)).length;
  const pct = status.length ? Math.round((done / status.length) * 100) : 100;

  // cmeprojects: completing your profile is part of onboarding (HR Pack → Staff profiles, after live update 57).
  const { data: profileNeeded } = await supabase.rpc("profile_required", { p_user: profile.id });
  return (
    <>
      <PageHeader
        title="My onboarding"
        intro="Everything you need to read, complete and upload. Your progress saves as you go."
      />
      {profileNeeded === true ? (
        <Card className="flex flex-wrap items-center gap-4 border-warn/40 p-5">
          <span className="min-w-56 flex-1">
            <span className="block font-semibold">Step 1: Complete your profile</span>
            <span className="block text-sm text-muted">Add a contact phone and an emergency contact. Your onboarding can&apos;t finish until it&apos;s done.</span>
          </span>
          <Link href="/account" className={buttonClass("primary")}>
            Complete my profile
          </Link>
        </Card>
      ) : profileNeeded === false && features.hr_profiles !== false ? (
        <Card className="flex items-center gap-3 p-4 text-sm">
          <span className="rounded-full bg-good-soft px-2.5 py-0.5 text-xs font-semibold text-good">Done</span> Your profile is complete.
        </Card>
      ) : null}
      <Card className="flex flex-col gap-3 p-5">
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <p className="heading-sm">{status.length === 0 ? "Nothing to do yet" : done === status.length && !sentForms.length ? "All done, thank you. You don't have any actions waiting." : `${done} of ${status.length} done`}</p>
          {profile.role === "new_starter" ? (
            <p className="text-sm text-muted">Once it&apos;s all done, a staff admin will set up your role and team.</p>
          ) : null}
        </div>
        <div className="h-2.5 overflow-hidden rounded-full bg-page" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Onboarding progress">
          <div className="h-full rounded-full bg-brand" style={{ width: `${pct}%` }} />
        </div>
      </Card>

      {sentForms.length ? (
        <section className="flex flex-col gap-3" aria-labelledby="h-sent">
          <h2 id="h-sent" className="heading-sm">
            Forms sent to you · {sentForms.length}
          </h2>
          {sentForms.map((f) => (
            <Card key={f.id} className="flex flex-wrap items-center justify-between gap-3 px-5 py-4">
              <span className="min-w-48 flex-1">
                <span className="block font-semibold">{f.title}</span>
                <span className="block text-sm text-muted">
                  {f.due_date ? `Please answer by ${formatDate(f.due_date)}. ` : ""}You can save it and finish later.
                </span>
              </span>
              {f.started ? <Badge tone="warn">Started</Badge> : null}
              <Link href={`/forms/${f.id}`} className={buttonClass("primary")}>
                {f.started ? "Carry on" : "Answer now"}
              </Link>
            </Card>
          ))}
        </section>
      ) : null}

      {KINDS.map((kind) => {
        const list = status.filter((s) => s.kind === kind);
        if (!list.length) return null;
        return (
          <section key={kind} className="flex flex-col gap-3" aria-labelledby={`h-${kind}`}>
            <h2 id={`h-${kind}`} className="heading-sm">
              {KIND_LABELS[kind]} · {list.filter((s) => isDone(s.state)).length} of {list.length}
            </h2>
            {list.map((s) => {
              const item = items.get(s.item_id);
              if (!item) return null;
              const finished = isDone(s.state);
              return (
                <Card key={s.item_id} className="p-0">
                  <ItemShell finished={finished} header={
                    <>
                      <span className="min-w-48 flex-1 font-semibold">{item.title}</span>
                      {s.expires_on ? <span className="text-sm text-muted">Expires {formatDate(s.expires_on)}</span> : null}
                      {stateBadges(s.state, (records ?? []).find((r) => r.id === s.record_id)?.status).map((b) => (
                        <Badge key={b.label} tone={b.tone}>{b.label}</Badge>
                      ))}
                    </>
                  }>
                    {/* Opened details stand out from the list (clear in light and dark). */}
                    <div className="mx-4 mb-4 flex flex-col gap-3 rounded-lg border border-brand/20 bg-brand-soft p-4 text-ink">
                      {item.description ? <p className="text-sm">{item.description}</p> : null}
                      {item.body ? <div className="max-h-[28rem] overflow-y-auto rounded-md border border-line bg-surface p-4 text-sm leading-relaxed whitespace-pre-line">{item.body}</div> : null}
                      {item.link_url || links.has(item.id) ? (
                        <p className="flex flex-wrap gap-4 text-sm">
                          {item.link_url ? (
                            <a href={item.link_url} target="_blank" rel="noopener noreferrer" className="font-semibold text-brand underline">
                              {kind === "training" ? "Open the training" : "Open the link"}
                            </a>
                          ) : null}
                          {links.has(item.id) ? (
                            <a href={links.get(item.id)} target="_blank" rel="noopener noreferrer" className="font-semibold text-brand underline">
                              Open {item.file_name ?? "the document"}
                            </a>
                          ) : null}
                        </p>
                      ) : null}
                      {s.state === "rejected" && s.note ? <p className="text-sm text-warn">Staff admin&apos;s note: {s.note}</p> : null}
                      {kind === "upload" ? (
                        <>
                          {s.record_id
                            ? (() => {
                                const r = (records ?? []).find((x) => x.id === s.record_id);
                                const by = r?.uploaded_by && r.uploaded_by !== profile.id ? uploaderName.get(r.uploaded_by) ?? "a staff admin" : null;
                                return (
                                  <p className="text-sm text-muted">
                                    Last upload: {r?.file_name ?? "a file"}
                                    {by ? ` · uploaded for you by ${by}` : ""}
                                  </p>
                                );
                              })()
                            : null}
                          <UploadForm itemId={item.id} userId={profile.id} needsExpiry={item.needs_expiry} again={Boolean(s.record_id)} />
                        </>
                      ) : kind === "form" ? (
                        finished ? (
                          <p className="text-sm text-good">You&apos;ve filled this in.</p>
                        ) : item.form_id ? (
                          <div className="flex flex-wrap items-center justify-between gap-3 rounded-md border border-line bg-page px-4 py-3">
                            <p className="text-sm text-muted">A short form to answer. You can save it and finish later.</p>
                            <Link href={`/forms/${item.form_id}`} className={buttonClass("primary")}>
                              Answer now
                            </Link>
                          </div>
                        ) : null
                      ) : finished ? (
                        <p className="text-sm text-good">You&apos;ve {kind === "training" ? "completed this" : "confirmed this"}.</p>
                      ) : (
                        <>
                          {kind === "read" ? <p className="text-sm font-medium">Please confirm that you&apos;ve read and understood this document.</p> : null}
                          <ConfirmButton itemId={item.id} label={kind === "training" ? "I've completed this training" : "I confirm I've read and understood this"} />
                        </>
                      )}
                    </div>
                  </ItemShell>
                </Card>
              );
            })}
          </section>
        );
      })}
    </>
  );
}

// Things still to do are shown in full; finished ones fold away.
function ItemShell({ finished, header, children }: { finished: boolean; header: React.ReactNode; children: React.ReactNode }) {
  const row = "flex min-h-14 flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3";
  if (!finished) {
    return (
      <div>
        <div className={row}>{header}</div>
        {children}
      </div>
    );
  }
  return (
    <details name="onboarding-item">
      <summary className={`${row} cursor-pointer list-none`}>{header}</summary>
      {children}
    </details>
  );
}
