// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { BadgeCheck, Briefcase, ChevronDown, Landmark, CircleCheck, CircleDashed, ClipboardList, FileCheck2, GraduationCap, PenLine, ShieldCheck, UserRound } from "lucide-react";
import { requireSession } from "@/lib/session";
import { onboardingOn } from "@/lib/feature-parts";
import { createClient } from "@/lib/supabase/server";
import { formatDate } from "@/lib/registers";
import { loadPerson, profilesReady } from "@/lib/profiles";
import { EMPLOYMENT } from "@/lib/profiles-shared";
import { CATEGORY_LABELS, LIBRARY_BUCKET, STATE_LABELS, isDone, stateBadges, type ComplianceItem, type ItemKind, type StatusRow } from "@/lib/compliance";
import { Badge, Card, PageHeader, buttonClass } from "@/components/ui";
import { ProfileForm } from "@/components/profile-form";
import { ConfirmButton } from "./forms";
import { OpenSectionOnHash } from "./open-section";
import { AgreementStep, DocumentStep, PolicyStep, TrainingStep, type HistoryRow } from "./steps";

export const metadata: Metadata = { title: "My onboarding" };

type WorkStatus = {
  onboarding_complete: boolean;
  compliance_verified: boolean;
  cleared: boolean;
  can_work: boolean;
  before_work_missing: string[];
  override: { until: string; reason: string } | null;
} | null;

type Rec = {
  id: number;
  item_id: string;
  file_name: string | null;
  created_at: string;
  status: string;
  uploaded_by: string | null;
  reviewed_by: string | null;
  reviewed_at: string | null;
  review_note: string;
  expires_on: string | null;
  doc_number?: string;
  version: number;
};

const SECTIONS: { key: string; title: string; icon: typeof UserRound; kinds?: ItemKind[] }[] = [
  { key: "personal", title: "Personal information", icon: UserRound },
  { key: "employment", title: "Employment details", icon: Briefcase },
  // cmeprojects: bank, super, right to work, and a contract to sign.
  { key: "pay", title: "Pay, work rights and contract", icon: Landmark },
  { key: "policies", title: "Policies and acknowledgements", icon: ClipboardList, kinds: ["read"] },
  { key: "training", title: "Training", icon: GraduationCap, kinds: ["training"] },
  { key: "documents", title: "Documents and qualifications", icon: FileCheck2, kinds: ["upload"] },
  { key: "agreement", title: "Employment agreement", icon: PenLine, kinds: ["agreement"] },
  { key: "forms", title: "Forms", icon: ClipboardList, kinds: ["form"] },
  { key: "final", title: "Final verification", icon: ShieldCheck },
];

// cmeprojects: My onboarding, in clear sections. Progress counts only what
// applies to this person. Everything saves as they go.
export default async function MyOnboardingPage() {
  const { profile, features } = await requireSession();
  if (!onboardingOn(features)) redirect(features.forms === true ? "/forms" : "/");
  const supabase = await createClient();
  // cmeprojects: only onboarding forms count here; other forms sent to this
  // person are in My forms (no duplicates).
  const [{ data: rows }, { data: work }, { data: profileNeeded }, person, bankQ, superQ, rightsQ, contractsQ, taxQ] = await Promise.all([
    supabase.rpc("compliance_status", { p_user: profile.id }),
    supabase.rpc("work_status", { p_user: profile.id }),
    supabase.rpc("profile_required", { p_user: profile.id }),
    features.hr_profiles !== false && (await profilesReady()) ? loadPerson(profile.id) : Promise.resolve(null),
    supabase.from("staff_bank").select("account_number, verified_at").eq("user_id", profile.id).maybeSingle(),
    supabase.from("staff_super").select("fund_name, verified_at").eq("user_id", profile.id).maybeSingle(),
    supabase.from("staff_work_rights").select("status, verified_at").eq("user_id", profile.id).maybeSingle(),
    supabase.from("contracts").select("id, title, status").eq("user_id", profile.id).in("status", ["awaiting_employee", "awaiting_employer", "fully_signed"]).order("created_at", { ascending: false }),
    supabase.from("staff_tax").select("form_path, verified_at").eq("user_id", profile.id).maybeSingle(),
  ]);
  // cmeprojects: pay and work rights (only once this copy has update 62), and contracts (update 64).
  const payItems = bankQ.error
    ? []
    : [
        { key: "bank", title: "Bank account for your pay", given: Boolean(bankQ.data?.account_number), checked: Boolean(bankQ.data?.verified_at), href: "/account/records" },
        { key: "super", title: "Superannuation", given: Boolean(superQ.data?.fund_name), checked: Boolean(superQ.data?.verified_at), href: "/account/records" },
        { key: "rights", title: "Right to work in Australia", given: Boolean(rightsQ.data?.status), checked: Boolean(rightsQ.data?.verified_at), href: "/account/records" },
        ...(taxQ.error
          ? []
          : [{ key: "tax", title: "Tax file number declaration", given: Boolean(taxQ.data?.form_path), checked: Boolean(taxQ.data?.verified_at), href: "/account/records" }]),
      ];
  const myContracts = (contractsQ.error ? [] : (contractsQ.data ?? [])) as { id: string; title: string; status: string }[];
  const toSign = myContracts.filter((c) => c.status === "awaiting_employee");
  const payTotal = payItems.length + toSign.length + (toSign.length ? 0 : myContracts.length ? 1 : 0);
  const payDone = payItems.filter((i) => i.given).length + (toSign.length ? 0 : myContracts.length ? 1 : 0);
  const status = (rows ?? []) as StatusRow[];
  const ws = (work ?? null) as WorkStatus;
  const ids = status.map((s) => s.item_id);
  const [{ data: itemRows }, { data: recRows }, { data: openRows }] = await Promise.all([
    ids.length ? supabase.from("compliance_items").select("*").in("id", ids) : Promise.resolve({ data: [] }),
    supabase.from("compliance_records").select("*").eq("user_id", profile.id).order("created_at", { ascending: false }),
    supabase.from("compliance_opens").select("item_id, version").eq("user_id", profile.id),
  ]);
  const items = new Map(((itemRows ?? []) as ComplianceItem[]).map((i) => [i.id, i]));
  const records = (recRows ?? []) as Rec[];
  const opened = new Set((openRows ?? []).map((o) => `${o.item_id}:${o.version}`));
  // Reviewers' names for document history.
  const reviewerIds = [...new Set(records.map((r) => r.reviewed_by).filter((x): x is string => Boolean(x)))];
  const { data: reviewers } = reviewerIds.length ? await supabase.from("profiles").select("id, full_name, email").in("id", reviewerIds) : { data: [] };
  const reviewerName = new Map((reviewers ?? []).map((r) => [r.id, r.full_name || r.email]));
  // Library files open through short-lived links.
  const links = new Map<string, string>();
  await Promise.all(
    [...items.values()]
      .filter((i) => i.file_path)
      .map(async (i) => {
        const { data } = await supabase.storage.from(LIBRARY_BUCKET).createSignedUrl(i.file_path!, 3600);
        if (data?.signedUrl) links.set(i.id, data.signedUrl);
      }),
  );

  // What applies, by section. The profile photo upload sits with personal information.
  const photoIds = new Set([...items.values()].filter((i) => (i as ComplianceItem & { sets_photo?: boolean }).sets_photo).map((i) => i.id));
  const inSection = (key: string) =>
    key === "personal"
      ? status.filter((s) => photoIds.has(s.item_id))
      : status.filter((s) => SECTIONS.find((x) => x.key === key)?.kinds?.includes(s.kind) && !photoIds.has(s.item_id));
  const profileApplies = profileNeeded === true || profileNeeded === false ? features.hr_profiles !== false : false;
  const profileDone = profileNeeded === false;
  const total = status.length + (profileApplies ? 1 : 0) + payTotal;
  const done = status.filter((s) => isDone(s.state)).length + (profileApplies && profileDone ? 1 : 0) + payDone;
  const pct = total ? Math.round((done / total) * 100) : 100;
  const counts = (key: string) => {
    const list = inSection(key);
    const extra = key === "personal" && profileApplies ? 1 : 0;
    const extraDone = key === "personal" && profileApplies && profileDone ? 1 : 0;
    if (key === "pay") return { total: payTotal, done: payDone };
    return { total: list.length + extra, done: list.filter((s) => isDone(s.state)).length + extraDone };
  };
  const visible = SECTIONS.filter((s) => s.key === "employment" || s.key === "final" || counts(s.key).total > 0);
  const beforeWork = ws?.before_work_missing ?? [];
  const historyFor = (itemId: string): HistoryRow[] =>
    records
      .filter((r) => r.item_id === itemId && r.file_name !== null)
      .slice(0, 8)
      .map((r) => ({
        id: r.id,
        when: formatDate(r.created_at.slice(0, 10)),
        file: r.file_name ?? "",
        status: STATE_LABELS[(r.status as keyof typeof STATE_LABELS) ?? "submitted"] ?? r.status,
        reviewer: r.reviewed_by ? (reviewerName.get(r.reviewed_by) ?? "") : "",
        reviewedOn: r.reviewed_at ? formatDate(r.reviewed_at.slice(0, 10)) : "",
        note: r.review_note ?? "",
        expires: r.expires_on ? formatDate(r.expires_on) : "",
        number: r.doc_number ?? "",
      }));
  const doc = (i: ComplianceItem) => ({
    id: i.id,
    title: i.title,
    description: i.description,
    body: i.body,
    link: i.link_url || null,
    fileLink: links.get(i.id) ?? null,
    fileName: i.file_name,
  });

  const itemCard = (s: StatusRow) => {
    const item = items.get(s.item_id);
    if (!item) return null;
    const finished = isDone(s.state);
    const rec = records.find((r) => r.id === s.record_id);
    const header = (
      <>
        <StateIcon done={finished} />
        <span className="min-w-0 flex-1">
          <span className="block font-semibold">{item.title}</span>
          {finished && rec ? <span className="block text-xs text-muted">{doneLine(item.kind, rec)}</span> : null}
        </span>
        {s.before_work && !finished ? <Badge tone="warn">Needed before working</Badge> : null}
        {item.category ? <Badge tone="grey">{CATEGORY_LABELS[item.category] ?? item.category}</Badge> : null}
        {s.expires_on ? <span className="text-xs text-muted">Expires {formatDate(s.expires_on)}</span> : null}
        {stateBadges(s.state, rec?.status).map((b) => (
          <Badge key={b.label} tone={b.tone}>
            {b.label}
          </Badge>
        ))}
      </>
    );
    const note = (s.state === "rejected" || s.state === "replace_requested") && s.note ? (
      <p className="rounded-md bg-warn-soft px-3 py-2 text-sm text-warn">Checked by a staff admin: {s.note}</p>
    ) : null;
    let body: ReactNode = null;
    if (item.kind === "read") {
      body = finished ? (
        <p className="text-sm text-good">You acknowledged this{rec ? ` on ${formatDate(rec.created_at.slice(0, 10))}` : ""} (version {item.version}).</p>
      ) : (
        <PolicyStep doc={doc(item)} opened={opened.has(`${item.id}:${item.version}`)} fullName={profile.full_name} />
      );
    } else if (item.kind === "training") {
      body = finished && s.state !== "expiring" ? (
        <p className="text-sm text-good">Recorded. {rec?.status === "submitted" ? "Your certificate is being checked." : ""}</p>
      ) : (
        <TrainingStep
          itemId={item.id}
          userId={profile.id}
          description={item.description}
          link={item.link_url || null}
          certificate={item.certificate ?? "optional"}
          needsExpiry={item.needs_expiry}
          mandatory={Boolean(item.before_work)}
        />
      );
    } else if (item.kind === "upload") {
      body = (
        <DocumentStep
          itemId={item.id}
          userId={profile.id}
          description={item.description}
          needsExpiry={item.needs_expiry}
          needsIssue={Boolean(item.needs_issue_date)}
          needsNumber={Boolean(item.needs_number)}
          askIssue={!photoIds.has(item.id)}
          again={Boolean(s.record_id)}
          history={historyFor(item.id)}
        />
      );
    } else if (item.kind === "agreement") {
      body = finished ? (
        <p className="text-sm text-good">You signed this{rec ? ` on ${formatDate(rec.created_at.slice(0, 10))}` : ""} (version {item.version}).</p>
      ) : (
        <AgreementStep doc={doc(item)} opened={opened.has(`${item.id}:${item.version}`)} fullName={profile.full_name} userId={profile.id} />
      );
    } else if (item.kind === "form") {
      body = finished ? (
        <p className="text-sm text-good">You&apos;ve filled this in.</p>
      ) : item.form_id ? (
        <Link href={`/forms/${item.form_id}`} className={buttonClass("primary", "self-start")}>
          Answer now
        </Link>
      ) : (
        <ConfirmButton itemId={item.id} label="Done" />
      );
    }
    return (
      <Card key={s.item_id} className="p-0">
        <ItemShell finished={finished && item.kind !== "upload"} header={header}>
          <div className="flex flex-col gap-3 border-t border-line px-5 py-4">
            {note}
            {body}
          </div>
        </ItemShell>
      </Card>
    );
  };

  return (
    <>
      <PageHeader title="My onboarding" intro="Everything to set you up, in order. It saves as you go, so you can stop and come back any time." />

      {/* Progress and the three statuses */}
      <Card className="flex flex-wrap items-center gap-5 p-5 sm:p-6">
        <Ring pct={pct} />
        <div className="min-w-56 flex-1">
          <p className="heading-sm">{total === 0 ? "Nothing to do yet" : done === total ? "All done, thank you" : `${done} of ${total} done`}</p>
          <p className="text-sm text-muted">
            {total - done > 0 ? `${total - done} still to do.` : "Nothing waiting on you."} Only what applies to you is counted.
          </p>
          {ws ? (
            <div className="mt-3 flex flex-wrap gap-2">
              <StatusChip on={ws.onboarding_complete} label="Onboarding complete" />
              <StatusChip on={ws.compliance_verified} label="Compliance verified" />
              <StatusChip on={ws.cleared} label={ws.cleared ? "Cleared to work" : ws.override ? `Can work until ${formatDate(ws.override.until)}` : "Cleared to work"} warn={!ws.cleared && Boolean(ws.override)} />
            </div>
          ) : null}
        </div>
      </Card>

      {ws && !ws.cleared && beforeWork.length ? (
        <Card className="flex flex-col gap-2 border-warn/40 bg-warn-soft/40 p-5">
          <p className="font-semibold">Needed before you can start work · {beforeWork.length}</p>
          <ul className="list-disc pl-5 text-sm">
            {beforeWork.map((t) => (
              <li key={t}>{t}</li>
            ))}
          </ul>
          <p className="text-xs text-muted">Documents and certificates also need to be checked by a staff admin. You&apos;ll be told when you&apos;re cleared.</p>
        </Card>
      ) : null}

      <div className="grid grid-cols-[minmax(0,1fr)] gap-5 lg:grid-cols-[15rem_minmax(0,1fr)]">
        {/* Sections: a list on wide screens, a row of chips on phones */}
        <nav aria-label="Onboarding sections" className="lg:sticky lg:top-4 lg:self-start">
          <ol className="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:gap-1 lg:overflow-visible">
            {visible.map((s, i) => {
              const c = counts(s.key);
              const complete = s.key === "final" ? Boolean(ws?.cleared) : s.key === "employment" ? true : c.done === c.total;
              return (
                <li key={s.key} className="shrink-0">
                  <a href={`#${s.key}`} className="flex min-h-10 items-center gap-2 rounded-lg border border-line bg-surface px-3 py-2 text-sm hover:border-brand lg:border-transparent lg:bg-transparent lg:hover:bg-surface">
                    <span className={`grid size-6 shrink-0 place-items-center rounded-full text-xs font-bold ${complete ? "bg-good text-white" : "bg-page text-muted ring-1 ring-line"}`}>
                      {complete ? "✓" : i + 1}
                    </span>
                    <span className="font-medium whitespace-nowrap lg:whitespace-normal">{s.title}</span>
                    {c.total ? <span className="ml-auto text-xs text-muted">{c.done}/{c.total}</span> : null}
                  </a>
                </li>
              );
            })}
          </ol>
        </nav>

        <div className="flex min-w-0 flex-col gap-4">
          <OpenSectionOnHash />
          {visible.map((sec) => {
            const Icon = sec.icon;
            const c = counts(sec.key);
            // cmeprojects: every section folds the same way; open where something is still to do.
            const due = sec.key === "final" ? !ws?.cleared : sec.key === "employment" ? false : c.done < c.total;
            return (
              <details key={sec.key} id={sec.key} open={due} className="group scroll-mt-4 rounded-xl border border-line bg-surface/60 open:border-transparent open:bg-transparent">
                <summary className="flex min-h-12 cursor-pointer list-none items-center gap-2 rounded-xl px-3 py-2 hover:bg-surface [&::-webkit-details-marker]:hidden">
                  <h2 id={`h-${sec.key}`} className="heading-sm flex flex-1 flex-wrap items-center gap-2">
                    <Icon aria-hidden="true" className="size-5 text-brand" /> {sec.title}
                    {c.total ? <span className="text-sm font-normal text-muted">· {c.done} of {c.total}</span> : null}
                    {!due && c.total && c.done === c.total ? <CircleCheck aria-label="All done" className="size-4 text-good" /> : null}
                  </h2>
                  <ChevronDown aria-hidden="true" className="size-5 shrink-0 text-muted transition-transform group-open:rotate-180" />
                </summary>
                <div className="flex flex-col gap-3 pt-3">

                {sec.key === "personal" ? (
                  <>
                    {profileApplies && person ? (
                      <Card className="p-0">
                        <ItemShell
                          finished={profileDone}
                          header={
                            <>
                              <StateIcon done={profileDone} />
                              <span className="min-w-0 flex-1 font-semibold">Contact details and emergency contact</span>
                              <Badge tone={profileDone ? "good" : "warn"}>{profileDone ? "Done" : "To do"}</Badge>
                            </>
                          }
                        >
                          <div className="border-t border-line px-5 py-4">
                            <ProfileForm person={person} employment={false} />
                          </div>
                        </ItemShell>
                      </Card>
                    ) : null}
                    {inSection("personal").map(itemCard)}
                  </>
                ) : sec.key === "pay" ? (
                  <Card className="divide-y divide-line p-0">
                    {payItems.map((i) => (
                      <div key={i.key} className="flex flex-wrap items-center gap-3 px-5 py-4">
                        <StateIcon done={i.given} />
                        <span className="min-w-48 flex-1">
                          <span className="block font-semibold">{i.title}</span>
                          <span className="block text-sm text-muted">{!i.given ? "Not given yet" : i.checked ? "Given and checked" : "Given, waiting to be checked"}</span>
                        </span>
                        <Link href={i.href} className={buttonClass(i.given ? "outline" : "primary", "", "sm")}>
                          {i.given ? "View or change" : "Fill in"}
                        </Link>
                      </div>
                    ))}
                    {myContracts.map((c) => (
                      <div key={c.id} className="flex flex-wrap items-center gap-3 px-5 py-4">
                        <StateIcon done={c.status !== "awaiting_employee"} />
                        <span className="min-w-48 flex-1">
                          <span className="block font-semibold">{c.title}</span>
                          <span className="block text-sm text-muted">
                            {c.status === "awaiting_employee" ? "Please read and sign" : c.status === "awaiting_employer" ? "You've signed; waiting for the employer" : "Fully signed"}
                          </span>
                        </span>
                        <Link href={`/account/contracts/${c.id}`} className={buttonClass(c.status === "awaiting_employee" ? "primary" : "outline", "", "sm")}>
                          {c.status === "awaiting_employee" ? "Read and sign" : "Open"}
                        </Link>
                      </div>
                    ))}
                    <p className="px-5 py-3 text-xs text-muted">Private: only you and the people who look after payroll or work rights see these.</p>
                  </Card>
                ) : sec.key === "employment" ? (
                  <Card className="flex flex-col gap-3 p-5">
                    <dl className="grid gap-x-6 gap-y-3 text-sm sm:grid-cols-2">
                      <Detail label="Position">{person?.jobTitle || "Not set yet"}</Detail>
                      <Detail label="Department">{person?.directory.department || "Not set yet"}</Detail>
                      <Detail label="Employment type">{(person?.private?.employment_type && EMPLOYMENT[person.private.employment_type]) || "Not set yet"}</Detail>
                      <Detail label="Start date">{person?.private?.start_date ? formatDate(person.private.start_date) : "Not set yet"}</Detail>
                    </dl>
                    <p className="text-xs text-muted">Set by your manager. If something&apos;s wrong, let them know. Your usual availability is under Personal information.</p>
                  </Card>
                ) : sec.key === "final" ? (
                  <Card className="flex flex-col gap-4 p-5">
                    {ws ? (
                      <ol className="flex flex-col gap-3 text-sm">
                        <FinalStep on={ws.onboarding_complete} title="Onboarding complete" text="Everything above is done or sent." />
                        <FinalStep on={ws.compliance_verified} title="Compliance verified" text="A staff admin has checked your documents and certificates." />
                        <FinalStep
                          on={ws.cleared}
                          title="Cleared to work"
                          text={ws.cleared ? "You're cleared to work." : ws.override ? `You can work until ${formatDate(ws.override.until)} while you finish.` : "A manager clears you once everything needed before working is done and checked."}
                        />
                      </ol>
                    ) : (
                      <p className="text-sm text-muted">Once everything above is done, a staff admin checks it and you&apos;ll be told.</p>
                    )}
                    {profile.role === "new_starter" ? <p className="text-xs text-muted">A staff admin sets your role and team once you&apos;re ready.</p> : null}
                  </Card>
                ) : (
                  inSection(sec.key).map(itemCard)
                )}
                </div>
              </details>
            );
          })}
        </div>
      </div>
    </>
  );
}

function doneLine(kind: ItemKind, r: Rec) {
  const on = formatDate(r.created_at.slice(0, 10));
  if (kind === "read") return `Acknowledged ${on}`;
  if (kind === "agreement") return `Signed ${on}`;
  if (kind === "training") return `Completed · recorded ${on}`;
  return `Sent ${on}`;
}

function StateIcon({ done }: { done: boolean }) {
  return done ? <CircleCheck aria-label="Done" className="size-5 shrink-0 text-good" /> : <CircleDashed aria-label="To do" className="size-5 shrink-0 text-muted" />;
}

function StatusChip({ on, label, warn }: { on: boolean; label: string; warn?: boolean }) {
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold ${on ? "bg-good-soft text-good" : warn ? "bg-warn-soft text-warn" : "bg-page text-muted ring-1 ring-line"}`}>
      {on ? <BadgeCheck aria-hidden="true" className="size-3.5" /> : <CircleDashed aria-hidden="true" className="size-3.5" />}
      {label}
    </span>
  );
}

function FinalStep({ on, title, text }: { on: boolean; title: string; text: string }) {
  return (
    <li className="flex gap-3">
      <StateIcon done={on} />
      <span>
        <span className="block font-semibold">{title}</span>
        <span className="block text-muted">{text}</span>
      </span>
    </li>
  );
}

function Detail({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <dt className="text-xs text-muted">{label}</dt>
      <dd className="font-medium">{children}</dd>
    </div>
  );
}

function Ring({ pct }: { pct: number }) {
  const r = 30;
  const c = 2 * Math.PI * r;
  return (
    <div className="relative size-20 shrink-0" role="progressbar" aria-valuenow={pct} aria-valuemin={0} aria-valuemax={100} aria-label="Onboarding progress">
      <svg viewBox="0 0 72 72" className="size-20 -rotate-90">
        <circle cx="36" cy="36" r={r} fill="none" strokeWidth="8" className="stroke-page" />
        <circle cx="36" cy="36" r={r} fill="none" strokeWidth="8" strokeLinecap="round" className={pct === 100 ? "stroke-good" : "stroke-brand"} strokeDasharray={c} strokeDashoffset={c - (c * pct) / 100} />
      </svg>
      <span className="absolute inset-0 grid place-items-center text-sm font-bold">{pct}%</span>
    </div>
  );
}

// Things still to do are open; finished ones fold away.
function ItemShell({ finished, header, children }: { finished: boolean; header: ReactNode; children: ReactNode }) {
  const row = "flex min-h-14 flex-wrap items-center gap-x-3 gap-y-2 px-5 py-3";
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
