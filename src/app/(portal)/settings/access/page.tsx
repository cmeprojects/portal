// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { Badge, Card, PageHeader } from "@/components/ui";
import { ACCESS_AREAS, ACCESS_HINT, ACCESS_LABEL, nowMs, type AccessArea, type Grant } from "@/lib/access";
import { RemoveAccessButton } from "./forms";
import { ModuleAccessEditor, NominateForm, NominationButtons, type Existing, type Limit, type Person, type TreeNode } from "./delegation-centre";
import { DelegationPicker, type DelegationValue, type PersonChoice } from "../../system/forms";
import { AREAS, AREA_HINTS, AREA_LABELS, type Area } from "@/lib/delegation";
import { getDrafts } from "@/lib/drafts";
import { ROLE_LABELS, isRole } from "@/lib/roles";
import { DeleteRecordsButton } from "../../people/tax-forms";
import { SettingForm } from "../../system/forms";
import { withSettingDrafts } from "@/lib/drafts";

// cmeprojects: staff records areas as modules in the tree.
const AREA_MODULE: Record<AccessArea, string> = { staff_details: "hr.records.details", payroll_tax: "hr.records.payroll", identity_docs: "hr.records.identity" };

export const metadata: Metadata = { title: "Access" };

// cmeprojects Phase 2: who can see and change staff records. The system admin
// gives access to managers (and staff admins for Staff details); a manager
// allowed to pass it on gives the same, never wider, to staff admins. Removing
// access is immediate and also removes what was passed on. Nothing is deleted:
// removed access stays in the history.
//
// cmeprojects step 3 (Delegation Centre): the system admin nominates Manager
// Administrators and gives them admin access to modules with the permission
// tree; a Manager Administrator passes on what they're allowed to, to staff
// admins. Everything is checked again by the database and logged.
type Designation = { id: string; user_id: string; status: "active" | "suspended" | "ended"; starts_at: string; expires_at: string | null; note: string; granted_by: string | null; created_at: string; changed_at: string | null; changed_by: string | null };
type ModGrant = { id: string; module_id: string; effect: "allow" | "restrict"; actions: string[]; user_id: string; scope: "all" | "teams" | "people"; scope_ids: string[]; can_pass_on: boolean; expires_at: string | null; granted_by: string | null; parent_id: string | null; note: string; created_at: string; revoked_at: string | null; revoked_by: string | null };
type ModRow = { id: string; parent_id: string | null; category: string; label: string; sensitivity: TreeNode["sensitivity"]; delegable: boolean; legacy_kind: TreeNode["legacy"]; legacy_area: string | null; actions: string[]; sort_order: number };

export default async function AccessPage() {
  const { profile } = await requireRole(["system_admin", "manager", "staff_admin"]);
  const admin = profile.role === "system_admin";
  const supabase = await createClient();
  const [{ data: grantRows, error }, { data: people }, { data: teams }, timeZone, { data: desigRows }, { data: modRows }, { data: rules }, { data: shares }] = await Promise.all([
    supabase.from("access_grants").select("*").order("created_at", { ascending: false }).limit(1000),
    supabase.from("profiles").select("id, full_name, email, role, active").order("full_name"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    getTimeZone(),
    supabase.from("admin_designations").select("*").order("created_at", { ascending: false }),
    supabase.from("app_modules").select("id, parent_id, category, label, sensitivity, delegable, legacy_kind, legacy_area, actions, sort_order").eq("status", "active").order("sort_order"),
    admin ? supabase.from("delegation_rules").select("area, mode, people") : Promise.resolve({ data: [] }),
    admin ? supabase.from("delegation_shares").select("area, user_id") : Promise.resolve({ data: [] }),
  ]);
  if (error) notFound(); // before the database update
  const allRows = (grantRows ?? []) as (Grant & { module_id: string | null })[];
  const grants = allRows.filter((g) => g.area) as Grant[];
  const modGrants = allRows.filter((g) => !g.area) as unknown as ModGrant[];
  const designations = (desigRows ?? []) as Designation[];
  const now = nowMs();
  const live = (g: Grant) => !g.revoked_at && (!g.expires_at || new Date(g.expires_at).getTime() > now);
  // What this manager may pass on.
  const passOn = admin ? [...ACCESS_AREAS] : grants.filter((g) => g.user_id === profile.id && g.can_pass_on && live(g)).map((g) => g.area);
  const myGrants = grants.filter((g) => g.user_id === profile.id && live(g));
  const liveMod = (g: ModGrant) => !g.revoked_at && (!g.expires_at || new Date(g.expires_at).getTime() > now);
  const openDesig = designations.filter((d) => d.status !== "ended");
  const iAmMA = openDesig.some((d) => d.user_id === profile.id && d.status === "active" && (!d.expires_at || new Date(d.expires_at).getTime() > now));
  // What I may pass on: module access (Manager Administrators) and staff records access.
  const myLimits: Limit[] = [
    ...(iAmMA ? modGrants.filter((g) => g.user_id === profile.id && liveMod(g) && g.can_pass_on && g.effect === "allow").map((g) => ({ module: g.module_id, actions: g.actions })) : []),
    ...(admin ? [] : grants.filter((g) => g.user_id === profile.id && g.can_pass_on && live(g)).map((g) => ({ module: AREA_MODULE[g.area], actions: g.area === "payroll_tax" && !g.can_reveal_tfn ? ["view"] : [] }))),
  ];
  const myModAccess = modGrants.filter((g) => g.user_id === profile.id && liveMod(g));
  if (!admin && !passOn.length && !myGrants.length && !iAmMA && !myModAccess.length) notFound();

  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const teamOf = new Map((teams ?? []).map((t) => [t.id, t.name]));
  const day = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone });
  const active = (role: string) => (people ?? []).filter((p) => p.active && p.role === role).map((p) => ({ id: p.id, name: p.full_name || p.email }));
  const scopeText = (g: Grant) =>
    g.scope === "all"
      ? "All staff"
      : g.scope === "teams"
        ? `Teams: ${g.scope_ids.map((t) => teamOf.get(t) ?? "a team").join(", ")}`
        : `People: ${g.scope_ids.map((p) => nameOf.get(p) ?? "someone").join(", ")}`;

  // The permission tree: delegable categories, modules and submodules.
  const mods = ((modRows ?? []) as ModRow[]).filter((m) => m.delegable || m.sensitivity === "protected");
  const modById = new Map(mods.map((m) => [m.id, m]));
  const depthOf = (m: ModRow): number => (m.id.startsWith("cat_") ? 0 : m.parent_id && modById.has(m.parent_id) ? depthOf(modById.get(m.parent_id) as ModRow) + 1 : 1);
  const nodes: TreeNode[] = [];
  const addTree = (m: ModRow) => {
    // Staff records: the only choice besides On is revealing TFNs.
    const actions = m.legacy_kind === "record" ? (m.id === "hr.records.payroll" ? ["view", "reveal_tfn"] : ["view"]) : m.actions;
    nodes.push({ id: m.id, parent: m.id.startsWith("cat_") ? null : m.parent_id && modById.has(m.parent_id) ? m.parent_id : `cat_${m.category}`, category: m.category, label: m.label, sensitivity: m.sensitivity, legacy: m.legacy_kind, actions, depth: depthOf(m) });
    for (const c of mods.filter((x) => x.parent_id === m.id && !x.id.startsWith("cat_"))) addTree(c);
  };
  for (const c of mods.filter((m) => m.id.startsWith("cat_"))) {
    addTree(c);
    for (const m of mods.filter((x) => x.category === c.category && !x.id.startsWith("cat_") && (!x.parent_id || !modById.has(x.parent_id)))) addTree(m);
  }
  const labelOf = (id: string) => modById.get(id)?.label ?? id;
  const dayInput = (iso: string | null) => (iso ? new Intl.DateTimeFormat("en-CA", { timeZone }).format(new Date(iso)) : "");
  const existing: Record<string, Existing[]> = {};
  for (const g of modGrants.filter((x) => !x.revoked_at && (admin || x.granted_by === profile.id))) {
    (existing[g.user_id] ??= []).push({ module: g.module_id, effect: g.effect, actions: g.actions, scope: g.scope, ids: g.scope_ids, expires: dayInput(g.expires_at), passOn: g.can_pass_on, note: g.note });
  }
  for (const g of grants.filter((x) => !x.revoked_at && (admin || x.granted_by === profile.id))) {
    (existing[g.user_id] ??= []).push({
      module: AREA_MODULE[g.area],
      effect: "allow",
      actions: g.area === "payroll_tax" && !g.can_reveal_tfn ? ["view"] : [],
      scope: g.scope,
      ids: g.scope_ids,
      expires: dayInput(g.expires_at),
      passOn: g.can_pass_on,
      note: g.note,
    });
  }
  const isMA = (id: string) => openDesig.some((d) => d.user_id === id && d.status === "active" && (!d.expires_at || new Date(d.expires_at).getTime() > now));
  const editorPeople: Person[] = admin
    ? [
        ...active("manager").map((p) => ({ ...p, role: "manager" as const, ma: isMA(p.id) })),
        ...active("staff_admin").map((p) => ({ ...p, role: "staff_admin" as const, ma: false })),
      ]
    : active("staff_admin").map((p) => ({ ...p, role: "staff_admin" as const, ma: false }));
  const scopePeople = (people ?? []).filter((p) => p.active && p.role !== "system_admin").map((p) => ({ id: p.id, name: p.full_name || p.email }));
  // Settings areas each person looks after today (all managers, chosen people, or shared with them).
  const legacyOn: Record<string, string[]> = {};
  for (const m of mods.filter((x) => x.legacy_kind === "settings" && x.legacy_area)) {
    const r = ((rules ?? []) as { area: string; mode: string; people: string[] }[]).find((x) => x.area === m.legacy_area);
    for (const p of editorPeople) {
      const on =
        (r?.mode === "managers" && p.role === "manager") ||
        (r?.mode === "selected" && r.people.includes(p.id)) ||
        ((shares ?? []) as { area: string; user_id: string }[]).some((x) => x.area === m.legacy_area && x.user_id === p.id);
      if (on) (legacyOn[p.id] ??= []).push(m.id);
    }
  }
  const nominatable = active("manager").filter((m) => !openDesig.some((d) => d.user_id === m.id));
  const actionText = (g: ModGrant) => (g.effect === "restrict" ? "blocked" : g.actions.length ? g.actions.join(", ").replace(/_/g, " ") : "everything");
  const holders = [...new Set(modGrants.filter((g) => !g.revoked_at && (admin || g.granted_by === profile.id)).map((g) => g.user_id))];

  // What this manager passed on (modules and staff records), per person.
  const passedOn = admin
    ? []
    : [...new Set([...modGrants, ...grants].filter((g) => g.granted_by === profile.id && !g.revoked_at).map((g) => g.user_id))].map((id) => ({
        id,
        name: nameOf.get(id) ?? "Someone",
        what: [
          ...modGrants.filter((g) => g.user_id === id && g.granted_by === profile.id && !g.revoked_at).map((g) => `${labelOf(g.module_id)} (${actionText(g)})`),
          ...grants.filter((g) => g.user_id === id && g.granted_by === profile.id && !g.revoked_at).map((g) => ACCESS_LABEL[g.area]),
        ],
      }));
  const current = grants.filter((g) => !g.revoked_at && g.user_id !== profile.id);
  const history = grants.filter((g) => g.revoked_at);

  // A staff admin only sees what they were given (opened from a notice).
  if (profile.role === "staff_admin") {
    return (
      <>
        <PageHeader title="Your access" intro="What you were given, by whom, and until when. Ask the person who gave it if something should change." />
        <Card className="flex flex-col gap-2 p-5">
          <ul className="flex flex-col gap-1 text-sm">
            {myModAccess.map((g) => (
              <li key={g.id}>
                <strong>{labelOf(g.module_id)}</strong> · {actionText(g)} · from {nameOf.get(g.granted_by ?? "") ?? "the system admin"}
                {g.expires_at ? ` · until ${day.format(new Date(g.expires_at))}` : ""}
              </li>
            ))}
            {myGrants.map((g) => (
              <li key={g.id}>
                <strong>{ACCESS_LABEL[g.area]}</strong> · {scopeText(g)} · from {nameOf.get(g.granted_by ?? "") ?? "the system admin"}
                {g.expires_at ? ` · until ${day.format(new Date(g.expires_at))}` : ""}
              </li>
            ))}
          </ul>
        </Card>
      </>
    );
  }

  return (
    <>
      <PageHeader
        title={admin ? "Access" : "Delegate"}
        intro={
          admin
            ? "Who can run which parts of the portal (Manager Administrators and what they pass on to staff admins) and who can see private staff records. Changes work straight away and are recorded."
            : "Share the admin work you've been allowed to pass on with your staff admins. They get only what you choose, never more than you have, and it stops if your own access stops. Everything is recorded."
        }
      />

      {admin ? (
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        {[
          ["Manager Administrators", openDesig.filter((d) => d.status === "active").length],
          ["Suspended", openDesig.filter((d) => d.status === "suspended").length],
          ["People with admin access", holders.length],
          ["Staff records access", new Set(grants.filter((g) => live(g)).map((g) => g.user_id)).size],
        ].map(([t, n]) => (
          <Card key={t as string} className="px-4 py-3">
            <p className="text-xs font-semibold tracking-wide text-muted uppercase">{t}</p>
            <p className="text-2xl font-semibold tabular-nums">{n}</p>
          </Card>
        ))}
      </div>
      ) : null}

      {admin ? (
        <Card className="flex flex-col gap-4 p-5 sm:p-6">
          <div>
            <h2 className="heading-sm">Manager Administrators</h2>
            <p className="text-sm text-muted">Managers you nominate to run parts of the portal. Only they can be given admin access below. Suspend to pause it; end it to remove their admin access.</p>
          </div>
          {openDesig.length ? (
            <ul className="divide-y divide-line rounded-lg border border-line">
              {openDesig.map((d) => (
                <li key={d.id} className="flex flex-wrap items-start justify-between gap-3 px-4 py-3 text-sm">
                  <div className="min-w-0 flex-1 basis-64">
                    <p className="flex flex-wrap items-center gap-2 font-semibold">
                      {nameOf.get(d.user_id) ?? "Someone"}
                      {d.status === "suspended" ? <Badge tone="warn">Suspended</Badge> : d.expires_at && new Date(d.expires_at).getTime() <= now ? <Badge tone="warn">Ended by date</Badge> : <Badge tone="good">Active</Badge>}
                    </p>
                    <p className="text-muted">
                      Since {day.format(new Date(d.starts_at))}
                      {d.expires_at ? ` · until ${day.format(new Date(d.expires_at))}` : " · no end date"}
                      {d.note ? ` · ${d.note}` : ""}
                    </p>
                    <p className="text-xs text-muted">
                      Admin access: {modGrants.filter((g) => g.user_id === d.user_id && liveMod(g)).map((g) => `${labelOf(g.module_id)} (${actionText(g)})`).join(", ") || "none yet"}
                    </p>
                  </div>
                  <NominationButtons id={d.id} name={nameOf.get(d.user_id) ?? "this person"} status={d.status === "suspended" ? "suspended" : "active"} />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">Nobody yet.</p>
          )}
          <NominateForm managers={nominatable} />
        </Card>
      ) : null}


      {!admin && !myLimits.length ? (
        <Card className="p-5 sm:p-6">
          <h2 className="heading-sm">Nothing to pass on yet</h2>
          <p className="text-sm text-muted">The system admin hasn&apos;t allowed you to pass on any admin work. When they do, you&apos;ll choose a staff admin here and turn on what they can do.</p>
        </Card>
      ) : null}

      {admin || myLimits.length ? (
        <Card className="flex flex-col gap-4 p-5 sm:p-6">
          <div>
            <h2 className="heading-sm">{admin ? "Give or change access" : "Pass on access"}</h2>
            <p className="text-sm text-muted">
              {admin
                ? "Choose a person, turn on what they can use (modules, and staff records under HR & workforce) and check it before saving."
                : "Choose a staff admin and turn on parts of what you were allowed to pass on."}
            </p>
          </div>
          <ModuleAccessEditor
            admin={admin}
            nodes={nodes}
            people={editorPeople}
            teams={(teams ?? []).map((t) => ({ id: t.id, name: t.name }))}
            scopePeople={scopePeople}
            existing={existing}
            limits={myLimits}
            legacyOn={legacyOn}
          />
        </Card>
      ) : null}

      {!admin && passedOn.length ? (
        <Card className="flex flex-col gap-3 p-5 sm:p-6">
          <div>
            <h2 className="heading-sm">What you&apos;ve passed on</h2>
            <p className="text-sm text-muted">To change or remove it, choose the person above.</p>
          </div>
          <ul className="divide-y divide-line rounded-lg border border-line text-sm">
            {passedOn.map((p) => (
              <li key={p.id} className="px-4 py-2">
                <strong>{p.name}</strong> · {p.what.join(", ")}
              </li>
            ))}
          </ul>
        </Card>
      ) : null}

      {admin ? <SettingsAreas people={(people ?? []).filter((p) => p.active && (p.role === "manager" || p.role === "staff_admin"))} /> : null}

      {admin ? (
      <>
      <h2 className="heading-sm mt-2">Staff records access</h2>

      {myGrants.length && !admin ? (
        <Card className="flex flex-col gap-2 p-5">
          <h2 className="heading-sm">Your access</h2>
          <ul className="flex flex-col gap-1 text-sm">
            {myGrants.map((g) => (
              <li key={g.id}>
                <strong>{ACCESS_LABEL[g.area]}</strong> · {scopeText(g)}
                {g.expires_at ? ` · until ${day.format(new Date(g.expires_at))}` : ""}
                {g.can_pass_on ? " · you may pass it on to staff admins" : ""}
              </li>
            ))}
          </ul>
        </Card>
      ) : null}

      {ACCESS_AREAS.map((area) => {
        const rows = current.filter((g) => g.area === area);
        return (
          <Card key={area} className="overflow-hidden">
            <div className="border-b border-line px-5 py-3">
              <h2 className="heading-sm">{ACCESS_LABEL[area]}</h2>
              <p className="text-sm text-muted">{ACCESS_HINT[area]}</p>
            </div>
            {rows.length === 0 ? (
              <p className="px-5 py-4 text-sm text-muted">{admin ? "Nobody but you." : "Nobody you gave it to."}</p>
            ) : (
              <ul className="divide-y divide-line">
                {rows.map((g) => {
                  const expired = Boolean(g.expires_at && new Date(g.expires_at).getTime() <= now);
                  const passed = grants.filter((c) => c.parent_id === g.id && !c.revoked_at).length;
                  return (
                    <li key={g.id} className="flex flex-wrap items-start justify-between gap-3 px-5 py-3">
                      <div className="min-w-0 flex-1 basis-64 text-sm">
                        <p className="flex flex-wrap items-center gap-2 font-semibold">
                          {nameOf.get(g.user_id) ?? "Someone"}
                          {expired ? <Badge tone="warn">Ended</Badge> : null}
                          {g.can_pass_on ? <Badge tone="grey">May pass on</Badge> : null}
                          {g.can_reveal_tfn ? <Badge tone="grey">Can reveal TFNs</Badge> : null}
                        </p>
                        <p className="text-muted">
                          {scopeText(g)}
                          {g.expires_at ? ` · ${expired ? "ended" : "until"} ${day.format(new Date(g.expires_at))}` : " · no end date"}
                        </p>
                        <p className="text-xs text-muted">
                          Given by {g.granted_by ? (nameOf.get(g.granted_by) ?? "the system admin") : "the system"} on {day.format(new Date(g.created_at))}
                          {g.parent_id ? " (passed on)" : ""}
                          {g.note ? ` · ${g.note}` : ""}
                          {passed ? ` · passed on to ${passed}` : ""}
                        </p>
                      </div>
                      {admin || g.granted_by === profile.id ? (
                        <RemoveAccessButton id={g.id} name={nameOf.get(g.user_id) ?? "this person"} what={ACCESS_LABEL[area]} passedOn={passed} />
                      ) : null}
                    </li>
                  );
                })}
              </ul>
            )}
          </Card>
        );
      })}

      </>
      ) : null}

      {admin ? <KeepingRecords /> : null}

      <AccessHistory
        items={[
          // cmeprojects: a Manager Administrator sees only what they passed on.
          ...designations.filter(() => admin).flatMap((d) => [
            { at: d.created_at, text: `${nameOf.get(d.granted_by ?? "") ?? "The system admin"} nominated ${nameOf.get(d.user_id) ?? "someone"} as a Manager Administrator` },
            ...(d.changed_at ? [{ at: d.changed_at, text: `${nameOf.get(d.changed_by ?? "") ?? "The system admin"} ${d.status === "ended" ? "ended" : d.status === "suspended" ? "suspended" : "changed"} ${nameOf.get(d.user_id) ?? "someone"}'s nomination` }] : []),
          ]),
          ...modGrants
            .filter((g) => admin || g.granted_by === profile.id)
            .flatMap((g) => [
              { at: g.created_at, text: `${nameOf.get(g.granted_by ?? "") ?? (g.parent_id ? "Someone" : "The system admin")} gave ${nameOf.get(g.user_id) ?? "someone"} ${labelOf(g.module_id)} (${actionText(g)})${g.parent_id ? ", passed on" : ""}` },
              ...(g.revoked_at ? [{ at: g.revoked_at, text: `${g.revoked_by ? (nameOf.get(g.revoked_by) ?? "Someone") : "The system"} removed ${nameOf.get(g.user_id) ?? "someone"}'s ${labelOf(g.module_id)} access` }] : []),
            ]),
        ]}
        day={day}
        title={admin ? "History: admin access" : "History: what you passed on"}
      />

      {history.length ? (
        <details className="rounded-xl border border-line bg-surface">
          <summary className="cursor-pointer px-5 py-3 text-sm font-semibold">History: removed access ({history.length})</summary>
          <ul className="divide-y divide-line border-t border-line text-sm">
            {history.map((g) => (
              <li key={g.id} className="px-5 py-2">
                <strong>{nameOf.get(g.user_id) ?? "Someone"}</strong> · {ACCESS_LABEL[g.area]} · {scopeText(g)} · given {day.format(new Date(g.created_at))} by{" "}
                {g.granted_by ? (nameOf.get(g.granted_by) ?? "the system admin") : "the system"} · removed {day.format(new Date(g.revoked_at as string))}
                {g.revoked_by ? ` by ${nameOf.get(g.revoked_by) ?? "the system admin"}` : " (with the access it came from)"}
              </li>
            ))}
          </ul>
        </details>
      ) : null}
    </>
  );
}

// cmeprojects: who looks after each settings area (moved here from the
// Delegation tab in System settings). Saved as drafts, live on Deploy.
async function SettingsAreas({ people }: { people: { id: string; full_name: string | null; email: string; role: string }[] }) {
  const supabase = await createClient();
  const [{ data: rules, error }, drafts, { data: vehicles }] = await Promise.all([
    supabase.from("delegation_rules").select("area, mode, people"),
    getDrafts(),
    supabase.from("features").select("enabled, included").eq("key", "vehicles").maybeSingle(),
  ]);
  if (error) return null;
  const choices: PersonChoice[] = people.map((p) => ({ id: p.id, name: p.full_name || p.email, role: isRole(p.role) ? ROLE_LABELS[p.role] : p.role }));
  const value = (area: Area): { value: DelegationValue; pending: boolean } => {
    const d = drafts.find((x) => x.kind === "delegation" && x.key === area);
    const live = (rules ?? []).find((r) => r.area === area) as { mode: DelegationValue["mode"]; people: string[] } | undefined;
    const v = (d?.value ?? live ?? { mode: "admin", people: [] }) as DelegationValue;
    return { value: { mode: v.mode ?? "admin", people: v.people ?? [] }, pending: Boolean(d) };
  };
  const carsOn = Boolean(vehicles?.enabled && vehicles.included !== false);
  return (
    <Card id="settings-areas" className="flex flex-col gap-1 px-5 py-4 sm:px-6">
      <h2 className="heading-sm">Settings areas</h2>
      <p className="text-sm text-muted">
        Who looks after each area besides you: all managers, or the managers and staff admins you choose. Security, Features, Notifications, Demo data and General always stay with you, and so
        does making system admins. Changes here are saved as drafts and go live when you Deploy.
      </p>
      <div className="mt-2 flex flex-col divide-y divide-line">
        {AREAS.filter((a) => a !== "vehicles" || carsOn).map((a) => (
          <div key={a} className="py-4">
            <DelegationPicker area={a} label={AREA_LABELS[a]} hint={AREA_HINTS[a]} {...value(a)} choices={choices} />
          </div>
        ))}
      </div>
    </Card>
  );
}

// cmeprojects: admin access history, newest first (nominations and module access).
function AccessHistory({ items, day, title = "History: admin access" }: { items: { at: string; text: string }[]; day: Intl.DateTimeFormat; title?: string }) {
  if (!items.length) return null;
  const sorted = [...items].sort((a, b) => b.at.localeCompare(a.at));
  return (
    <details className="rounded-xl border border-line bg-surface">
      <summary className="cursor-pointer px-5 py-3 text-sm font-semibold">{title} ({sorted.length})</summary>
      <ul className="divide-y divide-line border-t border-line text-sm">
        {sorted.slice(0, 300).map((i, n) => (
          <li key={n} className="flex flex-wrap justify-between gap-2 px-5 py-2">
            <span>{i.text}</span>
            <span className="text-muted">{day.format(new Date(i.at))}</span>
          </li>
        ))}
      </ul>
    </details>
  );
}

// cmeprojects: how long private records are kept after someone leaves, and the
// leavers past that time whose records can now be deleted (by hand).
async function KeepingRecords() {
  const supabase = await createClient();
  const [{ data: setting }, { data: leavers }] = await Promise.all([
    supabase.from("app_settings").select("key, label, description, value").eq("key", "records.private_retention_years").maybeSingle(),
    supabase.from("profiles").select("id, full_name, email, deactivated_at").eq("active", false).not("deactivated_at", "is", null),
  ]);
  if (!setting) return null;
  const [withDraft] = await withSettingDrafts([setting]);
  const years = Number(setting.value) || 5;
  const cutoff = new Date(nowMs() - years * 365.25 * 86_400_000);
  const ids = (leavers ?? []).map((l) => l.id);
  const held = new Set<string>();
  if (ids.length) {
    const tables = ["staff_bank", "staff_super", "staff_work_rights", "staff_tax"] as const;
    const found = await Promise.all(tables.map((t) => supabase.from(t).select("user_id").in("user_id", ids)));
    for (const f of found) for (const r of (f.data ?? []) as { user_id: string }[]) held.add(r.user_id);
  }
  const rows = (leavers ?? []).filter((l) => held.has(l.id));
  const due = rows.filter((l) => new Date(l.deactivated_at as string) <= cutoff);
  const fmt = (d: string) => new Date(d).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });
  return (
    <Card className="flex flex-col gap-4 p-5 sm:p-6">
      <div>
        <h2 className="heading-sm">Keeping private records</h2>
        <p className="text-sm text-muted">Bank, super, work rights and TFN declarations of people who have left. Nothing is deleted automatically: you delete them here, and each deletion is recorded.</p>
      </div>
      <div className="max-w-xl">
        <SettingForm setting={withDraft} />
      </div>
      <div className="flex flex-col gap-2">
        <p className="text-sm font-semibold">Past {years} years since leaving · {due.length}</p>
        {due.length === 0 ? <p className="text-sm text-muted">Nobody yet.</p> : null}
        {(rows.length ? rows : []).map((l) => (
          <div key={l.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-line px-4 py-2 text-sm">
            <span>
              <strong>{l.full_name || l.email}</strong> · left {fmt(l.deactivated_at as string)}
              {new Date(l.deactivated_at as string) <= cutoff ? <span className="ml-2 font-semibold text-warn">Past the keeping period</span> : null}
            </span>
            <DeleteRecordsButton subject={l.id} name={l.full_name || l.email} />
          </div>
        ))}
      </div>
    </Card>
  );
}
