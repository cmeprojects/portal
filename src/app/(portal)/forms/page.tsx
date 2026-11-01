// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import QRCode from "qrcode";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { canMakeForms, formUrl, formsOn } from "@/lib/forms";
import { getPeople } from "@/lib/register-data";
import { getTimeZone } from "@/lib/settings";
import { env } from "@/lib/env";
import type { FormInfo } from "@/lib/form-types";
import { Card, PageHeader } from "@/components/ui";
import { LiveRefresh } from "@/components/live-refresh";
import { FormsList, NewFormForm, type ManagedForm } from "./list";

export const metadata: Metadata = { title: "Forms" };

const qr = (url: string) => QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } });

// cmeprojects: Forms. Everyone sees the forms sent to them; makers (and people
// a form is shared with) see their forms, each expanding to a snapshot.
export default async function FormsPage({ searchParams }: PageProps<"/forms">) {
  const { profile, features } = await requireSession();
  if (!formsOn(features)) notFound();
  const supabase = await createClient();
  const [canMake, timeZone, people, { open }] = await Promise.all([canMakeForms(), getTimeZone(), getPeople(), searchParams]);
  // Forms to fill in are in My onboarding; this page is for the people who make them.
  const admin = profile.role === "system_admin";

  const [{ data: forms }, { data: shared }] = await Promise.all([
    supabase.from("forms").select("*").order("updated_at", { ascending: false }),
    supabase.from("form_collaborators").select("form_id, user_id"),
  ]);
  const all = (forms ?? []) as FormInfo[];
  const sharedWith = (id: string) => (shared ?? []).filter((s) => s.form_id === id).map((s) => s.user_id);
  const managed = all.filter((f) => admin || f.created_by === profile.id || sharedWith(f.id).includes(profile.id));
  const ids = managed.map((f) => f.id);

  const [{ data: recipients }, { data: completions }, { data: replies }, { data: items }, { data: teams }] = await Promise.all([
    ids.length ? supabase.from("form_recipients").select("form_id, user_id").in("form_id", ids) : Promise.resolve({ data: [] }),
    ids.length ? supabase.from("form_completions").select("form_id, user_id").in("form_id", ids) : Promise.resolve({ data: [] }),
    ids.length ? supabase.from("form_responses").select("form_id").eq("status", "submitted").in("form_id", ids) : Promise.resolve({ data: [] }),
    ids.length ? supabase.from("compliance_items").select("form_id, active, applies_roles, applies_teams").in("form_id", ids) : Promise.resolve({ data: [] }),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
  ]);
  const nameOf = new Map(people.map((p) => [p.id, p.name]));
  const day = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone });
  const svgs = await Promise.all(managed.map((f) => qr(formUrl(env.siteUrl, f.id))));

  const rows: ManagedForm[] = managed.map((f, i) => {
    const sent = (recipients ?? []).filter((r) => r.form_id === f.id).map((r) => r.user_id);
    const done = new Set((completions ?? []).filter((c) => c.form_id === f.id).map((c) => c.user_id));
    const item = (items ?? []).find((x) => x.form_id === f.id && x.active);
    return {
      id: f.id,
      title: f.title,
      status: f.status,
      enabled: f.enabled,
      repeatable: f.repeatable,
      anonymous: f.anonymous,
      dueDate: f.due_date ? day.format(new Date(`${f.due_date}T12:00:00Z`)) : "",
      dueIso: f.due_date ?? "",
      published: f.published_at ? day.format(new Date(f.published_at)) : "",
      maker: nameOf.get(f.created_by) ?? "Someone",
      mine: f.created_by === profile.id || admin,
      sharedWith: sharedWith(f.id).map((u) => ({ id: u, name: nameOf.get(u) ?? "Someone" })),
      sentCount: sent.length,
      doneOfSent: sent.filter((u) => done.has(u)).length,
      stillToDo: sent.filter((u) => !done.has(u)).map((u) => nameOf.get(u) ?? "Someone"),
      replies: (replies ?? []).filter((r) => r.form_id === f.id).length,
      compliance: item ? { roles: item.applies_roles as string[], teams: item.applies_teams as string[] } : null,
      url: formUrl(env.siteUrl, f.id),
      qrSvg: svgs[i],
    };
  });

  // Nothing to manage here: their forms are in My onboarding.
  if (!canMake && !rows.length) redirect("/onboarding");

  return (
    <>
      <LiveRefresh tables={["forms", "form_completions", "form_responses"]} />
      <PageHeader title="Forms" intro="The forms you make and send. Forms for you to fill in are in My onboarding." />

      {canMake || rows.length ? (
        <section className="flex flex-col gap-3">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <h2 className="heading-sm">Your forms</h2>
          </div>
          {canMake ? (
            <Card className="p-4">
              <NewFormForm />
            </Card>
          ) : null}
          <FormsList
            rows={rows}
            open={typeof open === "string" ? open : ""}
            people={people.filter((p) => p.active && p.role !== "system_admin" && p.role !== "new_starter").map((p) => ({ id: p.id, name: p.name }))}
            sharers={people.filter((p) => p.active && p.id !== profile.id && (p.role === "manager" || p.role === "staff_admin")).map((p) => ({ id: p.id, name: p.name }))}
            teams={teams ?? []}
            complianceOn={features.compliance !== false}
          />
        </section>
      ) : null}
    </>
  );
}
