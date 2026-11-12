// Staff Portal · © cmeproject. All rights reserved.
import { compliancePartOn } from "@/lib/feature-parts";
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getPeopleRules } from "@/lib/settings";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { CATEGORY_LABELS, FILES_BUCKET, KIND_TAB, isDone, stateBadges, type ComplianceItem, type ItemKind, type StatusRow } from "@/lib/compliance";
import { formatDate } from "@/lib/registers";
import { Badge, Card, Notice, PageHeader, Tabs, buttonClass } from "@/components/ui";
import { ItemForm, ReviewForm } from "./forms";
import { TemplateUpload } from "../people/tax-forms";
import { managesComplianceFor, seesComplianceFor } from "@/lib/module-access";

export const metadata: Metadata = { title: "Onboarding" };

const TABS = ["progress", "check", "read", "training", "upload", "agreement"] as const;
type Tab = (typeof TABS)[number];

export default async function CompliancePage({ searchParams }: PageProps<"/compliance">) {
  const { profile: me, features } = await requireSession();
  const rules = await getPeopleRules();
  if (!(await seesComplianceFor(me.role, rules))) redirect("/");
  const manages = await managesComplianceFor(me.role, rules);
  const params = await searchParams;
  const asked = String(params.tab ?? "progress") as Tab;
  // Each part can be switched off (cmeprojects): its tab is hidden, except for the system admin.
  const admin = me.role === "system_admin";
  const open = (t: Tab) => t === "progress" || t === "check" || admin || compliancePartOn(features, t);
  const tab: Tab = TABS.includes(asked) && (asked === "progress" || manages) && open(asked) ? asked : "progress";
  // cmeprojects: how many files are waiting to be checked (for the tab).
  const supabase = await createClient();
  const { count: toCheck } = manages
    ? await supabase.from("compliance_records").select("id", { count: "exact", head: true }).eq("status", "submitted").not("file_path", "is", null)
    : { count: 0 };

  const tabs = manages
    ? TABS.filter(open).map((t) => ({
        href: `/compliance?tab=${t}`,
        text: t === "progress" ? "Overview" : t === "check" ? `To check${toCheck ? ` · ${toCheck}` : ""}` : `${KIND_TAB[t]}${compliancePartOn(features, t) ? "" : " (off)"}`,
        current: t === tab,
      }))
    : [];

  return (
    <>
      <PageHeader
        title="Onboarding"
        intro={
          manages
            ? "Everyone's onboarding and compliance: what's done, what's waiting to be checked, what's expired, and who's cleared to work."
            : "Onboarding progress for your people. Only Compliance managers can open uploaded documents."
        }
        action={
          <Link href="/compliance/expiry" className={buttonClass("outline")}>
            Expiry list
          </Link>
        }
      />
      <BlankTfnForm />
      {tabs.length ? <Tabs label="Compliance sections" items={tabs} /> : null}
      {tab === "progress" ? (
        <Progress meId={me.id} role={me.role} show={String(params.show ?? "")} />
      ) : tab === "check" ? (
        <ToCheck meId={me.id} />
      ) : (
        <Items kind={tab} />
      )}
    </>
  );
}

type Work = { onboarding_complete: boolean; compliance_verified: boolean; cleared: boolean; can_work: boolean; override: { until: string } | null } | null;
const SHOW: Record<string, string> = {
  incomplete: "Onboarding not finished",
  checks: "Waiting for checks",
  expired: "Expired or expiring",
  clearance: "Waiting for clearance",
  override: "Working on an override",
};

async function Progress({ meId, role, show }: { meId: string; role: Role; show: string }) {
  const supabase = await createClient();
  let query = supabase.from("profiles").select("id, full_name, email, role, joined_at, onboarded_at").eq("active", true).neq("role", "system_admin").order("full_name");
  // Team leaders see the people in the team they lead.
  if (role === "team_leader") {
    const { data: led } = await supabase.from("team_leaders").select("team_id").eq("user_id", meId);
    const { data: members } = await supabase.from("team_members").select("user_id").in("team_id", (led ?? []).map((l) => l.team_id));
    query = query.in("id", [...new Set((members ?? []).map((m) => m.user_id))].filter((id) => id !== meId));
  }
  const { data: people } = await query;
  const rows = await Promise.all(
    (people ?? []).map(async (p) => {
      const [{ data }, { data: w }] = await Promise.all([supabase.rpc("compliance_status", { p_user: p.id }), supabase.rpc("work_status", { p_user: p.id })]);
      const status = (data ?? []) as StatusRow[];
      return { ...p, role: p.role as Role, total: status.length, done: status.filter((s) => isDone(s.state)).length, status, work: (w ?? null) as Work };
    }),
  );
  const behind = rows.filter((r) => r.total && r.done < r.total);
  // cmeprojects: the overview tiles, each a filter on the list.
  const is = {
    incomplete: (r: (typeof rows)[number]) => Boolean(r.total && r.done < r.total),
    checks: (r: (typeof rows)[number]) => r.status.some((s) => s.state === "submitted"),
    expired: (r: (typeof rows)[number]) => r.status.some((s) => s.state === "expired" || s.state === "expiring"),
    clearance: (r: (typeof rows)[number]) => Boolean(r.work && !r.work.cleared && !r.work.override),
    override: (r: (typeof rows)[number]) => Boolean(r.work && !r.work.cleared && r.work.override),
  };
  const shown = show in is ? rows.filter(is[show as keyof typeof is]) : rows;
  void behind;

  return (
    <>
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        {(Object.keys(SHOW) as (keyof typeof is)[]).map((k) => {
          const n = rows.filter(is[k]).length;
          const on = show === k;
          return (
            <Link
              key={k}
              href={on ? "/compliance" : `/compliance?show=${k}`}
              aria-current={on ? "true" : undefined}
              className={`shadow-card rounded-xl border p-4 transition hover:-translate-y-0.5 ${on ? "border-brand bg-brand-soft" : "border-line bg-surface"}`}
            >
              <p className={`heading ${n ? (k === "expired" || k === "clearance" ? "text-warn" : "text-brand") : "text-muted"}`}>{n}</p>
              <p className="text-sm text-muted">{SHOW[k]}</p>
            </Link>
          );
        })}
      </div>
      {show in is ? (
        <p className="text-sm">
          Showing: <strong>{SHOW[show]}</strong> ·{" "}
          <Link href="/compliance" className="text-brand underline">
            show everyone
          </Link>
        </p>
      ) : null}
      {rows.length > 0 && rows.every((r) => r.total === 0) ? (
        <Notice tone="info">Nothing is set up for onboarding yet. Add documents to read, trainings or uploads using the tabs above, and everyone&apos;s progress shows here.</Notice>
      ) : null}
      <Card className="overflow-hidden">
        {shown.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted">{rows.length ? "Nobody here right now." : "No one to show yet."}</p>
        ) : (
          <ul className="divide-y divide-line">
            {shown.map((r) => {
              const pct = r.total ? Math.round((r.done / r.total) * 100) : 0;
              const flags = r.status.filter((s) => ["expired", "expiring", "rejected", "submitted"].includes(s.state));
              return (
                <li key={r.id}>
                  {/* Opens in place; the full page is still there for files and checking. */}
                  <details name="compliance-person" className="group">
                    <summary className="flex cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3 hover:bg-page [&::-webkit-details-marker]:hidden">
                      <span className="min-w-48 flex-1">
                        <span className="block font-semibold">{r.full_name || r.email}</span>
                        <span className="block text-sm text-muted">
                          {ROLE_LABELS[r.role]}
                          {r.joined_at ? "" : " · hasn't joined yet"}
                        </span>
                      </span>
                      <span className="flex flex-wrap gap-1.5">
                        {r.work ? (
                          r.work.cleared ? (
                            <Badge tone="good">Cleared to work</Badge>
                          ) : r.work.override ? (
                            <Badge tone="warn">Override until {formatDate(r.work.override.until)}</Badge>
                          ) : (
                            <Badge tone="grey">Not cleared</Badge>
                          )
                        ) : null}
                        {r.work?.compliance_verified ? <Badge tone="good">Verified</Badge> : null}
                        {flags.some((s) => s.state === "submitted") ? <Badge tone="soft">To check</Badge> : null}
                        {flags.some((s) => s.state === "expired") ? <Badge tone="warn">Expired</Badge> : null}
                        {flags.some((s) => s.state === "expiring") ? <Badge tone="warn">Expiring</Badge> : null}
                        {r.status.some((s) => s.state === "rejected" || s.state === "replace_requested") ? <Badge tone="warn">Sent back</Badge> : null}
                      </span>
                      {/* cmeprojects: no bar when nothing applies to them, so an empty set-up doesn't look finished. */}
                      {r.total ? (
                        <span className="flex w-40 items-center gap-2" aria-label={`${r.done} of ${r.total} done`}>
                          <span className="h-2 flex-1 overflow-hidden rounded-full bg-page">
                            <span className={`block h-full rounded-full ${r.done === r.total ? "bg-good" : "bg-brand"}`} style={{ width: `${pct}%` }} />
                          </span>
                          <span className="w-12 text-right text-sm tabular-nums">{`${r.done}/${r.total}`}</span>
                        </span>
                      ) : (
                        <span className="w-40 text-right text-sm text-muted">Nothing set yet</span>
                      )}
                    </summary>
                    <div className="border-t border-brand/30 bg-brand-soft px-5 py-4 text-ink">
                      {r.status.length === 0 ? (
                        <p className="text-sm">Nothing applies to them yet.</p>
                      ) : (
                        <ul className="grid gap-2 sm:grid-cols-2">
                          {r.status.map((st) => (
                            <li key={st.item_id} className="flex flex-wrap items-center gap-2 rounded-md border border-line bg-surface px-3 py-2 text-sm">
                              <span className="min-w-32 flex-1 font-medium">{st.title}</span>
                              {st.expires_on ? <span className="text-xs">Expires {formatDate(st.expires_on)}</span> : null}
                              {stateBadges(st.state).map((b) => (
                                <Badge key={b.label} tone={b.tone}>
                                  {b.label}
                                </Badge>
                              ))}
                            </li>
                          ))}
                        </ul>
                      )}
                      <Link href={`/compliance/people/${r.id}`} className="mt-3 inline-block text-sm font-semibold text-brand underline">
                        Open their onboarding: files, checks and clearance
                      </Link>
                    </div>
                  </details>
                </li>
              );
            })}
          </ul>
        )}
      </Card>
    </>
  );
}

async function Items({ kind }: { kind: ItemKind }) {
  const supabase = await createClient();
  const [{ data: itemRows }, { data: teams }, { data: people }, { data: members }, { data: titles }, { data: versions }] = await Promise.all([
    supabase.from("compliance_items").select("*").eq("kind", kind).order("active", { ascending: false }).order("sort_order").order("title"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("profiles").select("id, role, full_name, email").eq("active", true).neq("role", "system_admin").order("full_name"),
    supabase.from("team_members").select("user_id, team_id"),
    supabase.from("job_titles").select("id, name").order("sort_order").order("name"),
    // cmeprojects Phase 4: earlier wording of policies and agreements.
    kind === "read" || kind === "agreement"
      ? supabase.from("compliance_item_versions").select("item_id, version, body, saved_at").order("version", { ascending: false })
      : Promise.resolve({ data: [] as { item_id: string; version: number; body: string; saved_at: string }[] }),
  ]);
  const pickPeople = (people ?? []).map((p) => ({ id: p.id, name: p.full_name || p.email }));
  // How many people an item reaches: a ticked role AND a ticked team must both
  // match (the same rule as the database's compliance_applies).
  const teamsOf = (id: string) => (members ?? []).filter((m) => m.user_id === id).map((m) => m.team_id);
  const reach = (i: ComplianceItem) =>
    (people ?? []).filter(
      (p) =>
        (!i.applies_roles.length || i.applies_roles.includes(p.role as Role)) &&
        (!i.applies_teams.length || teamsOf(p.id).some((t) => i.applies_teams.includes(t))) &&
        (!i.applies_people?.length || i.applies_people.includes(p.id)),
    ).length;
  const items = (itemRows ?? []) as ComplianceItem[];
  const teamName = new Map((teams ?? []).map((t) => [t.id, t.name]));
  const forWhom = (i: ComplianceItem) => {
    const parts = [...i.applies_roles.map((r) => ROLE_LABELS[r]), ...i.applies_teams.map((t) => teamName.get(t) ?? "a team")];
    const roles = i.applies_roles.map((r) => ROLE_LABELS[r]).join(" or ");
    const inTeams = i.applies_teams.map((t) => teamName.get(t) ?? "a team").join(" or ");
    if (!parts.length) return "Everyone";
    return roles && inTeams ? `${roles}, in ${inTeams}` : roles || `Anyone in ${inTeams}`;
  };
  const noun = kind === "read" ? "policy" : kind === "training" ? "training" : kind === "agreement" ? "agreement" : "document";

  return (
    <>
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a {noun}</h2>
        <ItemForm kind={kind} teams={teams ?? []} titles={titles ?? []} people={pickPeople} />
      </Card>
      {items.length === 0 ? (
        <p className="text-sm text-muted">Nothing here yet.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {items.map((i) => (
            <Card key={i.id} className="p-0">
              <details name="compliance-item" className="group">
                <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-2 px-5 py-3">
                  <span className={`min-w-48 flex-1 font-semibold ${i.active ? "" : "text-muted"}`}>{i.title}</span>
                  <span className="text-sm text-muted">{forWhom(i)}</span>
                  {i.active ? <Badge tone={reach(i) ? "soft" : "warn"}>{reach(i) === 1 ? "1 person" : `${reach(i)} people`}</Badge> : null}
                  {kind !== "upload" && i.version > 1 ? <Badge tone="grey">Version {i.version}</Badge> : null}
                  {i.active ? <Badge tone="good">{kind === "upload" ? "On" : "In use"}</Badge> : <Badge tone="grey">{kind === "upload" ? "Off" : "Not in use"}</Badge>}
                  <span className="text-sm font-semibold text-brand group-open:hidden">Edit</span>
                  <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                </summary>
                <div className="border-t border-line px-5 py-5">
                  <ItemForm kind={kind} item={i} teams={teams ?? []} titles={titles ?? []} people={pickPeople} />
                  {(versions ?? []).filter((v) => v.item_id === i.id && v.version < i.version).length ? (
                    <details className="mt-4 rounded-lg border border-line">
                      <summary className="cursor-pointer px-4 py-2 text-sm font-semibold">Earlier versions</summary>
                      <ul className="divide-y divide-line border-t border-line">
                        {(versions ?? [])
                          .filter((v) => v.item_id === i.id && v.version < i.version)
                          .map((v) => (
                            <li key={v.version} className="px-4 py-3 text-sm">
                              <p className="font-semibold">
                                Version {v.version} <span className="font-normal text-muted">· saved {new Date(v.saved_at).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}</span>
                              </p>
                              <p className="mt-1 max-h-40 overflow-y-auto whitespace-pre-wrap text-muted">{v.body || "(no wording)"}</p>
                            </li>
                          ))}
                      </ul>
                    </details>
                  ) : null}
                </div>
              </details>
            </Card>
          ))}
        </div>
      )}
    </>
  );
}

// cmeprojects: every file waiting to be checked, oldest first, with the buttons.
async function ToCheck({ meId }: { meId: string }) {
  const supabase = await createClient();
  const { data: recs } = await supabase
    .from("compliance_records")
    .select("id, user_id, item_id, file_path, file_name, created_at, expires_on, doc_number, issued_on, completed_on")
    .eq("status", "submitted")
    .not("file_path", "is", null)
    .order("created_at")
    .limit(100);
  const list = recs ?? [];
  const [{ data: people }, { data: itemRows }] = await Promise.all([
    list.length ? supabase.from("profiles").select("id, full_name, email").in("id", [...new Set(list.map((r) => r.user_id))]) : Promise.resolve({ data: [] }),
    list.length ? supabase.from("compliance_items").select("id, title, kind, category").in("id", [...new Set(list.map((r) => r.item_id))]) : Promise.resolve({ data: [] }),
  ]);
  const who = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const what = new Map((itemRows ?? []).map((i) => [i.id, i]));
  const links = new Map<number, string>();
  await Promise.all(
    list.map(async (r) => {
      const { data } = await supabase.storage.from(FILES_BUCKET).createSignedUrl(r.file_path!, 900);
      if (data?.signedUrl) links.set(r.id, data.signedUrl);
    }),
  );
  if (!list.length) return <Notice tone="info">Nothing waiting to be checked. New uploads and certificates show here.</Notice>;
  return (
    <div className="flex flex-col gap-3">
      {list.map((r) => {
        const item = what.get(r.item_id);
        return (
          <Card key={r.id} className="flex flex-col gap-3 p-5">
            <div className="flex flex-wrap items-center gap-x-3 gap-y-1.5">
              <span className="min-w-48 flex-1">
                <Link href={`/compliance/people/${r.user_id}`} className="block font-semibold hover:text-brand">
                  {who.get(r.user_id) ?? "Someone"}
                </Link>
                <span className="block text-sm text-muted">
                  {item?.title ?? "Document"}
                  {item?.kind === "training" ? " (certificate)" : ""} · sent {formatDate(r.created_at.slice(0, 10))}
                </span>
              </span>
              {item?.category ? <Badge tone="grey">{CATEGORY_LABELS[item.category] ?? item.category}</Badge> : null}
              {r.doc_number ? <span className="text-xs text-muted">No. {r.doc_number}</span> : null}
              {r.issued_on ? <span className="text-xs text-muted">Issued {formatDate(r.issued_on)}</span> : null}
              {r.completed_on ? <span className="text-xs text-muted">Completed {formatDate(r.completed_on)}</span> : null}
              {r.expires_on ? <span className="text-xs text-muted">Expires {formatDate(r.expires_on)}</span> : null}
              {links.get(r.id) ? (
                <a href={links.get(r.id)} target="_blank" rel="noopener noreferrer" className="text-sm font-semibold text-brand underline">
                  Open {r.file_name ?? "file"}
                </a>
              ) : null}
            </div>
            {r.user_id === meId ? <p className="text-xs text-muted">Someone else needs to check your own documents.</p> : <ReviewForm recordId={r.id} />}
          </Card>
        );
      })}
    </div>
  );
}

// cmeprojects: the blank TFN declaration, for the system admin and people with Payroll and tax access.
async function BlankTfnForm() {
  const supabase = await createClient();
  const { data: holds, error } = await supabase.rpc("holds_area", { p_area: "payroll_tax" });
  if (error || holds !== true) return null;
  const { data } = await supabase.from("app_settings").select("value").eq("key", "records.tfn_template").maybeSingle();
  return (
    <details className="rounded-xl border border-line bg-surface shadow-card">
      <summary className="cursor-pointer px-5 py-3 text-sm font-semibold">Blank TFN declaration form{typeof data?.value === "string" && data.value ? " · on file" : " · not added yet"}</summary>
      <div className="border-t border-line p-5">
        <TemplateUpload current={typeof data?.value === "string" ? data.value : ""} />
      </div>
    </details>
  );
}
