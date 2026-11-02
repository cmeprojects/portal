// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { canManageCompliance, getPeopleRules, seesCompliance } from "@/lib/settings";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { ITEM_COLUMNS, KIND_TAB, isDone, stateBadges, type ComplianceItem, type ItemKind, type StatusRow } from "@/lib/compliance";
import { formatDate } from "@/lib/registers";
import { Badge, Card, PageHeader, Tabs } from "@/components/ui";
import { ItemForm } from "./forms";

export const metadata: Metadata = { title: "Compliance" };

const TABS = ["progress", "read", "training", "upload"] as const;
type Tab = (typeof TABS)[number];

export default async function CompliancePage({ searchParams }: PageProps<"/compliance">) {
  const { profile: me } = await requireSession();
  const rules = await getPeopleRules();
  if (!seesCompliance(me.role, rules)) redirect("/");
  const manages = canManageCompliance(me.role, rules);
  const params = await searchParams;
  const asked = String(params.tab ?? "progress") as Tab;
  const tab: Tab = TABS.includes(asked) && (asked === "progress" || manages) ? asked : "progress";

  const tabs = manages
    ? TABS.map((t) => ({ href: `/compliance?tab=${t}`, text: t === "progress" ? "Progress" : KIND_TAB[t], current: t === tab }))
    : [];

  return (
    <>
      <SectionTabs section="people" current="/compliance" />
      <PageHeader
        title="Compliance"
        intro={
          manages
            ? "Onboarding for everyone: documents to read and confirm, trainings, and documents to upload. Switch uploads on or off as you need them."
            : "Onboarding progress for your people. Only Compliance managers can open uploaded documents."
        }
      />
      {tabs.length ? <Tabs label="Compliance sections" items={tabs} /> : null}
      {tab === "progress" ? <Progress meId={me.id} role={me.role} /> : <Items kind={tab} />}
    </>
  );
}

async function Progress({ meId, role }: { meId: string; role: Role }) {
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
      const { data } = await supabase.rpc("compliance_status", { p_user: p.id });
      const status = (data ?? []) as StatusRow[];
      return { ...p, role: p.role as Role, total: status.length, done: status.filter((s) => isDone(s.state)).length, status };
    }),
  );
  const behind = rows.filter((r) => r.total && r.done < r.total);

  return (
    <>
      <div className="grid gap-3 sm:grid-cols-3">
        <Card className="p-4">
          <p className="heading text-brand">{rows.length}</p>
          <p className="text-sm text-muted">People</p>
        </Card>
        <Card className="p-4">
          <p className="heading text-warn">{behind.length}</p>
          <p className="text-sm text-muted">Still to finish</p>
        </Card>
        <Card className="p-4">
          <p className="heading text-warn">{rows.filter((r) => r.status.some((s) => s.state === "expired" || s.state === "expiring")).length}</p>
          <p className="text-sm text-muted">Documents expired or expiring</p>
        </Card>
      </div>
      <Card className="overflow-hidden">
        {rows.length === 0 ? (
          <p className="px-5 py-4 text-sm text-muted">No one to show yet.</p>
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((r) => {
              const pct = r.total ? Math.round((r.done / r.total) * 100) : 100;
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
                        {flags.some((s) => s.state === "submitted") ? <Badge tone="soft">To check</Badge> : null}
                        {flags.some((s) => s.state === "expired") ? <Badge tone="warn">Expired</Badge> : null}
                        {flags.some((s) => s.state === "expiring") ? <Badge tone="warn">Expiring</Badge> : null}
                        {flags.some((s) => s.state === "rejected") ? <Badge tone="warn">Sent back</Badge> : null}
                      </span>
                      <span className="flex w-40 items-center gap-2">
                        <span className="h-2 flex-1 overflow-hidden rounded-full bg-page">
                          <span className="block h-full rounded-full bg-brand" style={{ width: `${pct}%` }} />
                        </span>
                        <span className="w-12 text-right text-sm tabular-nums">{r.total ? `${r.done}/${r.total}` : "—"}</span>
                      </span>
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
                        Files, checking and uploads
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
  const [{ data: itemRows }, { data: teams }, { data: people }, { data: members }] = await Promise.all([
    supabase.from("compliance_items").select(ITEM_COLUMNS).eq("kind", kind).order("active", { ascending: false }).order("sort_order").order("title"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("profiles").select("id, role").eq("active", true).neq("role", "system_admin"),
    supabase.from("team_members").select("user_id, team_id"),
  ]);
  // How many people an item reaches: a ticked role AND a ticked team must both
  // match (the same rule as the database's compliance_applies).
  const teamsOf = (id: string) => (members ?? []).filter((m) => m.user_id === id).map((m) => m.team_id);
  const reach = (i: ComplianceItem) =>
    (people ?? []).filter(
      (p) => (!i.applies_roles.length || i.applies_roles.includes(p.role as Role)) && (!i.applies_teams.length || teamsOf(p.id).some((t) => i.applies_teams.includes(t))),
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
  const noun = kind === "read" ? "document" : kind === "training" ? "training" : "upload";

  return (
    <>
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a {noun}</h2>
        <ItemForm kind={kind} teams={teams ?? []} />
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
                  <ItemForm kind={kind} item={i} teams={teams ?? []} />
                </div>
              </details>
            </Card>
          ))}
        </div>
      )}
    </>
  );
}
