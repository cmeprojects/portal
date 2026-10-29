// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { ROLE_LABELS, isRole } from "@/lib/roles";
import { Card, PageHeader } from "@/components/ui";

export const metadata: Metadata = { title: "Change log" };

const WHEN = new Intl.DateTimeFormat("en-AU", {
  dateStyle: "medium",
  timeStyle: "short",
  timeZone: "Australia/Melbourne",
});

function describe(action: string, details: Record<string, unknown>, entityId: string | null, names: Map<string, string>): string {
  const who = entityId ? names.get(entityId) ?? entityId : "";
  const roleName = (v: unknown) => (isRole(v) ? ROLE_LABELS[v] : String(v));
  switch (action) {
    case "role_changed":
      return `Changed ${who}'s role from ${roleName(details.from)} to ${roleName(details.to)}`;
    case "deactivated":
      return `Deactivated ${who}`;
    case "reactivated":
      return `Reactivated ${who}`;
    case "team_changed":
      return `Moved ${who} to another team`;
    case "invited":
      return `Invited ${entityId} as ${roleName(details.role)}`;
    case "invite_resent":
      return `Resent the invite to ${who}`;
    case "mfa_reset":
      return `Reset ${who}'s two-factor login`;
    case "feature_on":
      return `Switched on: ${entityId}`;
    case "feature_off":
      return `Switched off: ${entityId}`;
    case "setting_changed":
      return `Changed setting ${entityId} to ${JSON.stringify(details.to)}`;
    default:
      return `${action} ${entityId ?? ""}`;
  }
}

export default async function AuditPage() {
  const { profile } = await requireSession();
  if (!(await getMyAdminAreas(profile.role)).includes("audit")) redirect("/");
  const supabase = await createClient();
  const [{ data: rows }, { data: people }] = await Promise.all([
    supabase.from("audit_log").select("id, actor_id, action, entity_id, details, created_at").order("created_at", { ascending: false }).limit(300),
    supabase.from("profiles").select("id, full_name, email"),
  ]);
  const names = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));

  return (
    <>
      <SectionTabs section="settings" current="/system/audit" />
      <PageHeader
        eyebrow="System"
        title="Change log"
        intro="Every change to people, roles and settings, newest first. This log can't be edited or deleted."
      />
      <Card className="overflow-hidden">
        {(rows ?? []).length === 0 ? (
          <p className="p-5 text-muted">Nothing has changed yet.</p>
        ) : (
          <ol>
            {(rows ?? []).map((r) => (
              <li key={r.id} className="flex flex-wrap justify-between gap-x-6 gap-y-1 border-t border-line px-5 py-3 first:border-t-0">
                <span className="text-sm">
                  <span className="font-semibold">{r.actor_id ? names.get(r.actor_id) ?? "Someone" : "System"}</span>{" "}
                  {describe(r.action, r.details ?? {}, r.entity_id, names).replace(/^./, (c) => c.toLowerCase())}
                </span>
                <time dateTime={r.created_at} className="text-sm text-muted">
                  {WHEN.format(new Date(r.created_at))}
                </time>
              </li>
            ))}
          </ol>
        )}
      </Card>
    </>
  );
}
