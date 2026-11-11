// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getTimeZone } from "@/lib/settings";
import { SectionTabs } from "@/components/section-tabs";
import { Badge, Card, PageHeader } from "@/components/ui";
import { ACCESS_AREAS, ACCESS_HINT, ACCESS_LABEL, nowMs, type AccessArea, type Grant } from "@/lib/access";
import { GiveAccessForm, RemoveAccessButton } from "./forms";
import { DeleteRecordsButton } from "../../people/tax-forms";
import { SettingForm } from "../../system/forms";
import { withSettingDrafts } from "@/lib/drafts";

export const metadata: Metadata = { title: "Staff access" };

// cmeprojects Phase 2: who can see and change staff records. The system admin
// gives access to managers (and staff admins for Staff details); a manager
// allowed to pass it on gives the same, never wider, to staff admins. Removing
// access is immediate and also removes what was passed on. Nothing is deleted:
// removed access stays in the history.
export default async function AccessPage() {
  const { profile } = await requireRole(["system_admin", "manager"]);
  const admin = profile.role === "system_admin";
  const supabase = await createClient();
  const [{ data: grantRows, error }, { data: people }, { data: teams }, timeZone] = await Promise.all([
    supabase.from("access_grants").select("*").order("created_at", { ascending: false }).limit(500),
    supabase.from("profiles").select("id, full_name, email, role, active").order("full_name"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    getTimeZone(),
  ]);
  if (error) notFound(); // before the database update
  const grants = (grantRows ?? []) as Grant[];
  const now = nowMs();
  const live = (g: Grant) => !g.revoked_at && (!g.expires_at || new Date(g.expires_at).getTime() > now);
  // What this manager may pass on.
  const passOn = admin ? [...ACCESS_AREAS] : grants.filter((g) => g.user_id === profile.id && g.can_pass_on && live(g)).map((g) => g.area);
  const myGrants = grants.filter((g) => g.user_id === profile.id && live(g));
  if (!admin && !passOn.length && !myGrants.length) notFound();

  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const teamOf = new Map((teams ?? []).map((t) => [t.id, t.name]));
  const day = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone });
  const active = (role: string) => (people ?? []).filter((p) => p.active && p.role === role).map((p) => ({ id: p.id, name: p.full_name || p.email }));
  const myTfn = grants.some((g) => g.user_id === profile.id && g.area === "payroll_tax" && g.can_reveal_tfn && live(g));
  // A manager's choices stay inside their own grant's scope (the database checks too).
  const myScope = (area: AccessArea) => grants.find((g) => g.user_id === profile.id && g.area === area && live(g));
  const scopeText = (g: Grant) =>
    g.scope === "all"
      ? "All staff"
      : g.scope === "teams"
        ? `Teams: ${g.scope_ids.map((t) => teamOf.get(t) ?? "a team").join(", ")}`
        : `People: ${g.scope_ids.map((p) => nameOf.get(p) ?? "someone").join(", ")}`;

  const current = grants.filter((g) => !g.revoked_at && g.user_id !== profile.id);
  const history = grants.filter((g) => g.revoked_at);

  return (
    <>
      <SectionTabs section="settings" current="/settings/access" />
      <PageHeader
        title="Staff access"
        intro="Who can change staff details, and (from the next update) see payroll, tax and identity records. Access works straight away; removing it stops it straight away."
      />

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

      {passOn.length ? (
        <Card className="flex flex-col gap-4 p-5 sm:p-6">
          <h2 className="heading-sm">Give access</h2>
          <GiveAccessForm
            admin={admin}
            areas={passOn}
            managers={active("manager")}
            staffAdmins={active("staff_admin")}
            teams={(teams ?? [])
              .filter((t) => admin || passOn.some((a) => myScope(a)?.scope === "all" || myScope(a)?.scope_ids.includes(t.id)))
              .map((t) => ({ id: t.id, name: t.name }))}
            people={(people ?? []).filter((p) => p.active && p.role !== "system_admin").map((p) => ({ id: p.id, name: p.full_name || p.email }))}
            tfnOk={admin || myTfn}
          />
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

      {admin ? <KeepingRecords /> : null}

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
