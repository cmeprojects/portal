// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import { ROLE_LABELS, isRole } from "@/lib/roles";
import { AREA_LABELS, isArea } from "@/lib/delegation";

// cmeprojects: turns change-log rows into plain sentences that say exactly
// what happened, to whom and to what (for example "accepted Sam Worker's
// First Aid certificate"), with a link to open it. Names are looked up in
// batches (one query per kind of thing), only for what the viewer may see.

export type AuditRow = { id: number; actor_id: string | null; action: string; entity: string; entity_id: string | null; details: Record<string, unknown> | null; created_at: string };
export type Described = { id: number; at: string; actor: string; actorId: string | null; text: string; note?: string; href?: string; kind: Kind; subjectId?: string };
export type Kind = "people" | "onboarding" | "access" | "settings" | "tasks" | "cars" | "forms" | "system";

export const KIND_LABEL: Record<Kind, string> = {
  people: "People and roles",
  onboarding: "Onboarding and documents",
  access: "Access and delegation",
  settings: "Settings and features",
  tasks: "Registers and tasks",
  cars: "Cars",
  forms: "Forms",
  system: "Sign-ins and security",
};

const KIND_OF: Record<string, Kind> = {
  role_changed: "people", deactivated: "people", reactivated: "people", team_changed: "people", invited: "people", invite_resent: "people",
  name_changed: "people", profile_updated: "people", photo_removed: "people", unstarted_person_deleted: "people", job_title_changed: "people", conditional_role_given: "people",
  upload_accepted: "onboarding", upload_rejected: "onboarding", upload_replacement_requested: "onboarding", uploaded_for_someone: "onboarding", agreement_signed: "onboarding",
  cleared_to_work: "onboarding", clearance_removed: "onboarding", work_override_given: "onboarding", work_override_ended: "onboarding",
  admin_nominated: "access", admin_suspended: "access", admin_resumed: "access", admin_ended: "access", module_access_changed: "access", access_given: "access", access_removed: "access",
  delegation_changed: "access", area_shared: "access", area_unshared: "access", mfa_exempted: "access", mfa_required_again: "access",
  setting_changed: "settings", settings_deployed: "settings", feature_on: "settings", feature_off: "settings", website_settings_changed: "settings",
  registry_created: "tasks", register_added_from_template: "tasks", register_deleted: "tasks", custom_entry_fixed: "tasks", custom_entry_undone: "tasks", custom_targets_set: "tasks",
  car_return_undone: "cars", car_returned_for_someone: "cars", car_start_undone: "cars", car_trip_corrected: "cars",
  form_sent: "forms",
  signed_out_everyone: "system", signed_out_everywhere: "system", signed_out_other_devices: "system", mfa_reset: "system",
};

const s = (v: unknown) => (v === null || v === undefined ? "" : String(v));
const day = (v: unknown) => {
  const t = s(v);
  if (!/^\d{4}-\d{2}-\d{2}/.test(t)) return t;
  return new Date(`${t.slice(0, 10)}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });
};
const role = (v: unknown) => (isRole(v) ? ROLE_LABELS[v] : s(v));
const show = (v: unknown) =>
  typeof v === "boolean"
    ? v ? "on" : "off"
    : Array.isArray(v)
      ? v.join(", ") || "none"
      : typeof v === "object" && v
        ? "updated"
        : /^[\w-]+\/[^\s]+\.\w{2,5}$/.test(s(v))
          ? "a file"
          : s(v) || "blank";

export async function describeAudit(rows: AuditRow[]): Promise<Described[]> {
  const supabase = await createClient();
  const ids = (entity: string) => [...new Set(rows.filter((r) => r.entity === entity && r.entity_id).map((r) => r.entity_id as string))];
  const people = [...new Set([...rows.map((r) => r.actor_id), ...ids("profile")].filter(Boolean) as string[])];
  const recordIds = ids("compliance_record").filter((x) => /^\d+$/.test(x)).map(Number);
  const [pp, recs, items, regs, settings, feats, titles, teams] = await Promise.all([
    people.length ? supabase.from("profiles").select("id, full_name, email").in("id", people) : Promise.resolve({ data: [] }),
    recordIds.length ? supabase.from("compliance_records").select("id, user_id, item_id, expires_on, file_name").in("id", recordIds) : Promise.resolve({ data: [] }),
    supabase.from("compliance_items").select("id, title"),
    ids("registry").length ? supabase.from("registries").select("id, name").in("id", ids("registry")) : Promise.resolve({ data: [] }),
    ids("setting").length ? supabase.from("app_settings").select("key, label").in("key", ids("setting")) : Promise.resolve({ data: [] }),
    ids("feature").length ? supabase.from("features").select("key, label").in("key", ids("feature")) : Promise.resolve({ data: [] }),
    ids("job_title").length ? supabase.from("job_titles").select("id, name").in("id", ids("job_title")) : Promise.resolve({ data: [] }),
    supabase.from("teams").select("id, name"),
  ]);
  // People named in compliance records too.
  const recRows = (recs.data ?? []) as { id: number; user_id: string; item_id: string; expires_on: string | null; file_name: string | null }[];
  const extra = recRows.map((r) => r.user_id).filter((u) => !people.includes(u));
  const { data: more } = extra.length ? await supabase.from("profiles").select("id, full_name, email").in("id", extra) : { data: [] };
  const name = new Map([...(pp.data ?? []), ...(more ?? [])].map((p: { id: string; full_name: string; email: string }) => [p.id, p.full_name || p.email]));
  const rec = new Map(recRows.map((r) => [String(r.id), r]));
  const item = new Map(((items.data ?? []) as { id: string; title: string }[]).map((i) => [i.id, i.title]));
  const reg = new Map(((regs.data ?? []) as { id: string; name: string }[]).map((r) => [r.id, r.name]));
  const setting = new Map(((settings.data ?? []) as { key: string; label: string }[]).map((r) => [r.key, r.label]));
  const feat = new Map(((feats.data ?? []) as { key: string; label: string }[]).map((r) => [r.key, r.label]));
  const title = new Map(((titles.data ?? []) as { id: string; name: string }[]).map((r) => [r.id, r.name]));
  const team = new Map(((teams.data ?? []) as { id: string; name: string }[]).map((r) => [r.id, r.name]));
  const who = (id: string | null | undefined) => (id ? (name.get(id) ?? "someone who has since been removed") : "");
  const poss = (n: string) => (n ? `${n}'s` : "their");

  return rows.map((r) => {
    const d = r.details ?? {};
    const e = r.entity_id;
    let text = `${r.action.replace(/_/g, " ")}${e ? ` (${e})` : ""}`;
    let href: string | undefined;
    let subjectId: string | undefined;
    const note = s(d.note || d.reason) || undefined;
    const person = r.entity === "profile" ? who(e) : "";
    if (r.entity === "profile" && e) {
      href = `/people?p=${e}`;
      subjectId = e;
    }
    // Compliance records: whose document, which one, and its expiry.
    const cr = r.entity === "compliance_record" && e ? rec.get(e) : undefined;
    const doc = cr ? (item.get(cr.item_id) ?? s(d.item)) : s(d.item);
    const owner = cr ? who(cr.user_id) : "";
    if (cr) {
      href = `/compliance/people/${cr.user_id}`;
      subjectId = cr.user_id;
    }
    switch (r.action) {
      case "role_changed": text = `changed ${poss(person)} role from ${role(d.from)} to ${role(d.to)}`; break;
      case "deactivated": text = `turned off ${poss(person)} account`; break;
      case "reactivated": text = `turned ${poss(person)} account back on`; break;
      case "team_changed":
        text = r.entity === "team" ? `changed the members of ${team.get(e ?? "") ?? "a team"}` : `moved ${person} from ${team.get(s(d.from)) ?? "no team"} to ${team.get(s(d.to)) ?? "no team"}`;
        break;
      case "invited": text = `invited ${e} as ${role(d.role)}`; break;
      case "invite_resent": text = `resent ${poss(person)} invite`; break;
      case "name_changed": text = `changed a name from "${s(d.from)}" to "${s(d.to)}"`; break;
      case "profile_updated": text = `updated ${poss(person)} staff details`; break;
      case "photo_removed": text = `removed ${poss(person)} photo`; break;
      case "unstarted_person_deleted": text = `deleted ${s(d.name) || s(d.email)} (${s(d.email)}), who never finished setting up`; href = undefined; break;
      case "job_title_changed": text = `changed the job title ${title.get(e ?? "") ?? s(d.name)}`; break;
      case "conditional_role_given": text = `gave ${person} the ${role(d.role)} role while onboarding finishes${d.deadline ? ` (by ${day(d.deadline)})` : ""}`; break;
      case "upload_accepted": text = `accepted ${poss(owner)} ${doc}${cr?.expires_on ? ` (expires ${day(cr.expires_on)})` : ""}`; break;
      case "upload_rejected": text = `rejected ${poss(owner)} ${doc}`; break;
      case "upload_replacement_requested": text = `asked ${owner || "them"} for a new copy of their ${doc}`; break;
      case "uploaded_for_someone": text = `uploaded ${s(d.item) || "a document"} for ${person}`; break;
      case "agreement_signed": text = `signed ${s(d.item) || "an agreement"}${d.version ? ` (version ${s(d.version)})` : ""}`; href = undefined; break;
      case "cleared_to_work": {
        const left = Array.isArray(d.still_to_do) ? (d.still_to_do as string[]) : [];
        text = `cleared ${person} to work${left.length ? `, with still to do: ${left.join(", ")}` : ""}`;
        break;
      }
      case "clearance_removed": text = `removed ${poss(person)} clearance to work`; break;
      case "work_override_given": text = `let ${person} work before being cleared${d.until ? `, until ${day(d.until)}` : ""}`; break;
      case "work_override_ended": text = `ended ${poss(person)} permission to work before being cleared`; break;
      case "delegation_changed":
        text =
          r.entity === "area"
            ? `changed who looks after ${isArea(e) ? AREA_LABELS[e].split(" (")[0].toLowerCase() : e}: ${s(d.mode) === "managers" ? "all managers" : s(d.mode) === "selected" ? "selected people" : "only the system admin"}`
            : `changed the settings areas ${person} looks after`;
        break;
      case "area_shared": text = `shared ${isArea(s(d.area)) ? AREA_LABELS[s(d.area) as keyof typeof AREA_LABELS].split(" (")[0].toLowerCase() : s(d.area)} with ${person}`; break;
      case "area_unshared": text = `stopped sharing ${isArea(s(d.area)) ? AREA_LABELS[s(d.area) as keyof typeof AREA_LABELS].split(" (")[0].toLowerCase() : s(d.area)} with ${person}`; break;
      case "mfa_exempted": text = `let ${person} sign in without two-factor`; break;
      case "mfa_required_again": text = `made two-factor required again for ${person}`; break;
      case "mfa_reset": text = `reset ${poss(person)} two-factor login`; break;
      case "setting_changed": {
        const label = setting.get(e ?? "") ?? e;
        text = !("to" in d) ? `changed "${label}"` : show(d.to) === "a file" ? `uploaded a new file for "${label}"` : `changed "${label}" from ${show(d.from)} to ${show(d.to)}`;
        href = "/settings";
        break;
      }
      case "settings_deployed": text = `deployed ${s(d.changes)} settings change${s(d.changes) === "1" ? "" : "s"}`; break;
      case "feature_on": text = `switched on ${feat.get(e ?? "") ?? e}`; break;
      case "feature_off": text = `switched off ${feat.get(e ?? "") ?? e}`; break;
      case "website_settings_changed": text = `changed the website settings (${e})`; href = "/assistant"; break;
      case "registry_created": text = `created the register "${s(d.name) || reg.get(e ?? "")}"`; href = e ? `/registers/${e}` : undefined; break;
      case "register_added_from_template": text = `added the register "${s(d.name) || reg.get(e ?? "")}" from a template`; href = e ? `/registers/${e}` : undefined; break;
      case "register_deleted": text = `deleted the register "${s(d.name)}"`; break;
      case "custom_entry_fixed": text = `corrected an entry in ${s(d.feature) || "a built app"}`; break;
      case "custom_entry_undone": text = `undid an entry in ${s(d.feature) || "a built app"}`; break;
      case "custom_targets_set": text = `changed who uses ${s(d.feature) || "a built app"}`; break;
      case "car_return_undone": text = `undid a car return${d.car ? ` (${s(d.car)})` : ""}`; break;
      case "car_returned_for_someone": text = `returned a car for someone${d.car ? ` (${s(d.car)})` : ""}`; break;
      case "car_start_undone": text = `undid a car booking start${d.car ? ` (${s(d.car)})` : ""}`; break;
      case "car_trip_corrected": text = `corrected a car trip${d.car ? ` (${s(d.car)})` : ""}`; break;
      case "form_sent": text = `sent the form "${s(d.title)}"${d.count ? ` to ${s(d.count)} people` : ""}`; href = e ? `/forms?open=${e}` : undefined; break;
      case "signed_out_everywhere": text = `signed ${person} out of all devices`; break;
      case "signed_out_other_devices": text = `signed out of their other devices`; break;
      case "admin_nominated": text = `nominated ${person} as a Manager Administrator${d.until ? ` (until ${day(d.until)})` : ""}`; href = "/settings/access"; break;
      case "admin_suspended": text = `suspended ${person} as a Manager Administrator`; href = "/settings/access"; break;
      case "admin_resumed": text = `resumed ${person} as a Manager Administrator`; href = "/settings/access"; break;
      case "admin_ended": text = `ended ${poss(person)} Manager Administrator nomination (their admin access was removed)`; href = "/settings/access"; break;
      case "module_access_changed": {
        const given = Array.isArray(d.given) ? (d.given as string[]) : [];
        const removed = Array.isArray(d.removed) ? (d.removed as string[]) : [];
        text = [given.length ? `gave ${person} ${given.join("; ")}` : "", removed.length ? `${given.length ? "and removed" : `removed ${poss(person)}`} ${removed.join("; ")}` : ""].filter(Boolean).join(" ") || `changed ${poss(person)} admin access`;
        if (d.until) text += ` (until ${day(d.until)})`;
        href = "/settings/access";
        break;
      }
      case "access_given": text = `gave ${person} ${s(d.what)} access (${s(d.scope) || "all staff"})${d.until ? ` until ${day(d.until)}` : ""}`; href = "/settings/access"; break;
      case "access_removed": text = `removed ${poss(person)} ${s(d.what)} access`; href = "/settings/access"; break;
      case "signed_out_everyone": text = `signed everyone out of all devices`; break;
    }
    return { id: r.id, at: r.created_at, actor: r.actor_id ? who(r.actor_id) : "The system", actorId: r.actor_id, text, note, href, kind: KIND_OF[r.action] ?? "system", subjectId };
  });
}
