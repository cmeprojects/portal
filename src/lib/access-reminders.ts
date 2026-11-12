// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import type { createAdminClient } from "@/lib/supabase/admin";
import { ACCESS_LABEL, isAccessArea } from "@/lib/access";

// cmeprojects: a week before a Manager Administrator nomination or any access
// ends, the person and whoever gave it (and system admins, for nominations)
// get one reminder (bell and email). Called by the hourly job; each reminder
// is sent once (its link is unique, so a sent one is found and skipped).
export async function remindAccessEnding(admin: ReturnType<typeof createAdminClient>): Promise<number> {
  const now = new Date();
  const soon = new Date(now.getTime() + 7 * 86_400_000).toISOString();
  const [{ data: noms, error: nomError }, { data: grants }, { data: mods }, { data: admins }, { data: people }] = await Promise.all([
    admin.from("admin_designations").select("id, user_id, granted_by, expires_at").eq("status", "active").gt("expires_at", now.toISOString()).lte("expires_at", soon),
    admin.from("access_grants").select("id, user_id, granted_by, area, module_id, expires_at").is("revoked_at", null).gt("expires_at", now.toISOString()).lte("expires_at", soon),
    admin.from("app_modules").select("id, label"),
    admin.from("profiles").select("id").eq("role", "system_admin").eq("active", true),
    admin.from("profiles").select("id, full_name, email"),
  ]);
  if (nomError) return 0; // before live update 73
  const name = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));
  const label = new Map((mods ?? []).map((m) => [m.id, m.label]));
  const day = (iso: string) => new Date(iso).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" });

  type Notice = { href: string; to: string[]; title: string; body: string };
  const notices: Notice[] = [];
  for (const d of noms ?? []) {
    const who = name.get(d.user_id) ?? "Someone";
    notices.push({
      href: `/settings/access?ending=n-${d.id}`,
      to: [...new Set([d.user_id, d.granted_by, ...(admins ?? []).map((a) => a.id)].filter(Boolean) as string[])],
      title: "A Manager Administrator nomination ends soon",
      body: `${who}'s Manager Administrator nomination ends on ${day(d.expires_at as string)}. Their admin access stops then. Change the end date on Access if they should keep it.`,
    });
  }
  for (const g of grants ?? []) {
    const what = g.area ? (isAccessArea(g.area) ? ACCESS_LABEL[g.area] : g.area) : (label.get(g.module_id ?? "") ?? "some access");
    notices.push({
      href: `/settings/access?ending=g-${g.id}`,
      to: [...new Set([g.user_id, g.granted_by].filter(Boolean) as string[])],
      title: "Access ends soon",
      body: `${name.get(g.user_id) ?? "Someone"}'s ${what} access ends on ${day(g.expires_at as string)}.`,
    });
  }
  if (!notices.length) return 0;
  const { data: sent } = await admin.from("notifications").select("href").in("href", notices.map((n) => n.href));
  const done = new Set((sent ?? []).map((s) => s.href));
  let count = 0;
  for (const n of notices.filter((x) => !done.has(x.href))) {
    for (const user of n.to) {
      await admin.rpc("notify", { p_user: user, p_kind: "access", p_title: n.title, p_body: n.body, p_href: n.href, p_email: true });
    }
    count++;
  }
  return count;
}
