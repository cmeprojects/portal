// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import type { createAdminClient } from "@/lib/supabase/admin";

// cmeprojects (audit Stage B): bank details, super, the TFN form and a checked
// right to work can be finished after someone is cleared to work, within 7
// days. Once the 7 days have passed, the person and whoever cleared them get
// one reminder (bell and email). Clearance is never removed for this.
// Called by the hourly job; each reminder is sent once (its link is unique).
export async function remindOnboardingDeadline(admin: ReturnType<typeof createAdminClient>): Promise<number> {
  const { data: feature } = await admin.from("features").select("enabled").eq("key", "compliance").maybeSingle();
  if (feature && feature.enabled === false) return 0;
  const weekAgo = new Date(Date.now() - 7 * 86_400_000).toISOString();
  // Only people cleared in the last 90 days: older clearances came before this rule.
  const since = new Date(Date.now() - 90 * 86_400_000).toISOString();
  const { data: people } = await admin
    .from("profiles")
    .select("id, full_name, email, role, cleared_at, cleared_by")
    .eq("active", true)
    .not("role", "in", "(system_admin,external)")
    .lte("cleared_at", weekAgo)
    .gte("cleared_at", since);
  if (!people?.length) return 0;
  const ids = people.map((p) => p.id);
  const [bank, sup, tax, rights, sent] = await Promise.all([
    admin.from("staff_bank").select("user_id, account_number").in("user_id", ids),
    admin.from("staff_super").select("user_id, fund_name").in("user_id", ids),
    admin.from("staff_tax").select("user_id, form_path").in("user_id", ids),
    admin.from("staff_work_rights").select("user_id, verified_at").in("user_id", ids),
    admin.from("notifications").select("href").in("href", ids.map((id) => `/onboarding?finish=${id}`)),
  ]);
  if (bank.error || sup.error || tax.error || rights.error) return 0; // before the records update
  const has = (rows: Record<string, unknown>[] | null, id: string, col: string) => (rows ?? []).some((r) => r.user_id === id && Boolean(r[col]));
  const done = new Set((sent.data ?? []).map((n) => n.href));
  let count = 0;
  for (const p of people) {
    const href = `/onboarding?finish=${p.id}`;
    if (done.has(href)) continue;
    const missing = [
      has(bank.data, p.id, "account_number") ? "" : "bank account",
      has(sup.data, p.id, "fund_name") ? "" : "superannuation",
      has(tax.data, p.id, "form_path") ? "" : "TFN declaration",
      has(rights.data, p.id, "verified_at") ? "" : "right to work (checked)",
    ].filter(Boolean);
    if (!missing.length) continue;
    const name = p.full_name || p.email;
    await admin.rpc("notify", {
      p_user: p.id,
      p_kind: "onboarding_item",
      p_title: "Please finish your onboarding",
      p_body: `It's been 7 days since you were cleared to work. Still to finish: ${missing.join(", ")}.`,
      p_href: href,
      p_email: true,
    });
    if (p.cleared_by) {
      await admin.rpc("notify", {
        p_user: p.cleared_by,
        p_kind: "onboarding_item",
        p_title: `${name} hasn't finished onboarding`,
        p_body: `7 days after clearance, still to finish: ${missing.join(", ")}. Their clearance stays as it is.`,
        p_href: `/compliance/people/${p.id}`,
        p_email: true,
      });
    }
    count++;
  }
  return count;
}
