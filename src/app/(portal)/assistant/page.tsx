// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { OffForStaff } from "@/components/off-for-staff";
import { getMyAdminAreas } from "@/lib/settings";
import { assistantUsage } from "@/lib/assistant";
import { AssistantUsageCard } from "@/components/assistant-usage";
import { NotLiveBadge, SettingForm, type SettingRow } from "../system/forms";
import { getDrafts, withSettingDrafts } from "@/lib/drafts";
import { createClient } from "@/lib/supabase/server";
import { AUDIENCE_LABELS, AUDIENCES, DEFAULT_SETTINGS, type AssistantSettings } from "@/lib/assistant-shared";
import { Badge, Button, Card, Notice, PageHeader, inputClass } from "@/components/ui";
import { AddDocumentForm, AnswersForm, LandingForm, LimitsForm, TestAiButton } from "./forms";
import { deleteDocument, setDocumentAudience } from "./actions";

export const metadata: Metadata = { title: "Website settings" };

const when = (iso: string) => new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" }).format(new Date(iso));

// cmeprojects: the system admin's side of the website's Assistant: the
// documents it answers from, its wording and limits, and what people asked.
export default async function AssistantPage() {
  const session = await requireSession();
  const { profile, features } = session;
  const admin = profile.role === "system_admin";
  // The system admin, or a manager given "Website" (where it looks, and documents).
  if (!admin && !(await getMyAdminAreas(profile.role)).includes("website")) redirect("/");
  // Delegated people only while the website is on; the system admin always.
  if (!admin && !features.assistant) redirect("/");
  const supabase = await createClient();
  const [{ data: settings }, { data: docs }, { data: questions }, { data: siteRows }, usage] = await Promise.all([
    supabase.from("assistant_settings").select("*").maybeSingle(),
    supabase.from("assistant_documents").select("id, title, audience, created_at").order("created_at", { ascending: false }),
    supabase.from("assistant_questions").select("id, question, answered, sources, created_at").order("created_at", { ascending: false }).limit(100),
    supabase.from("app_settings").select("key, label, description, value").or("key.like.website.%,key.like.assistant.%").order("key"),
    admin ? assistantUsage() : Promise.resolve(null),
  ]);
  // Saved but not deployed parts are shown as they'll be (cmeprojects).
  const drafts = (await getDrafts()).filter((d) => d.kind === "website");
  const draftParts = Object.assign({}, ...drafts.map((d) => d.value as Record<string, unknown>));
  const pendingPart = (part: string) => drafts.some((d) => d.key === part);
  const s = { ...DEFAULT_SETTINGS, ...(settings ?? {}), ...draftParts, monthly_limit_aud: Number(draftParts.monthly_limit_aud ?? settings?.monthly_limit_aud ?? DEFAULT_SETTINGS.monthly_limit_aud) } as AssistantSettings & { credit_aud?: number; credit_since?: string | null };
  const unanswered = (questions ?? []).filter((q) => !q.answered);
  const log = [...unanswered, ...(questions ?? []).filter((q) => q.answered)].slice(0, 30);
  // The public website's settings, in groups.
  const GROUPS = [
    { title: "Website", keys: ["website.front_page", "website.logo_url", "website.staff_phone", "website.closed_title", "website.closed_text"] },
    { title: "About page", keys: ["website.about_intro", "website.mission", "website.vision", "website.services"] },
    { title: "Search engines (SEO)", keys: ["website.site_url", "website.seo_title", "website.seo_description"] },
    { title: "Enquiries", keys: ["assistant.enquiry_roles", "assistant.intake_roles"] },
  ];
  const settingRows = await withSettingDrafts((siteRows ?? []) as SettingRow[]);

  return (
    <>
      <OffForStaff session={session} feature="assistant" name="The Assistant" />
      <PageHeader
        title="Website settings"
        intro={admin ? "The public website and its Assistant: the landing page, where it looks for answers, its documents and what it costs." : "Where the website's Assistant looks for answers, and the documents it answers from."}
        action={
          <Link href="/ask" className="inline-flex min-h-11 items-center rounded-md border border-line px-4 text-sm font-semibold hover:bg-brand-soft">
            Open website
          </Link>
        }
      />
      {!features.assistant ? <Notice>The website is switched off. Turn on &quot;Website and Assistant&quot; in Settings → Features when you&apos;re ready.</Notice> : null}
      {!settings ? <Notice tone="error">The website isn&apos;t set up in the database yet. Run the latest live updates, then refresh.</Notice> : null}
      {usage ? <AssistantUsageCard u={usage} /> : null}

      {/* The system admin sees every group; a manager given "Website" sees the About page wording. */}
      {GROUPS.filter((g) => admin || g.title === "About page").map((g) => {
            const list = g.keys.map((k) => settingRows.find((r) => r.key === k)).filter((r): r is SettingRow => Boolean(r));
            if (!list.length) return null;
            return (
              <section key={g.title} className="flex flex-col gap-2">
                <h2 className="heading-sm">{g.title}</h2>
                <Card className="px-5 py-2">
                  {list.map((r) => (
                    <SettingForm key={r.key} setting={r} />
                  ))}
                </Card>
              </section>
            );
          })}

      {admin ? (
        <section className="flex flex-col gap-2">
          <h2 className="flex items-center gap-2 heading-sm">Landing page {pendingPart("landing") ? <NotLiveBadge /> : null}</h2>
          <Card className="p-4">
            <LandingForm s={s} />
          </Card>
        </section>
      ) : null}

      <section className="flex flex-col gap-2">
        <h2 className="flex items-center gap-2 heading-sm">Where it looks for answers {pendingPart("answers") ? <NotLiveBadge /> : null}</h2>
        <Card className="p-4">
          <AnswersForm s={s} aiReady={Boolean(process.env.ANTHROPIC_API_KEY)} />
        </Card>
      </section>

      <section className="flex flex-col gap-2">
        <h2 className="heading-sm">Documents</h2>
        <Card className="p-4">
          <p className="mb-4 text-sm text-muted">
            Upload NDIS rules, company policies or public policies, and choose who can get answers from each one. Scanned PDFs and photos of pages are read by the AI (a few cents each).
          </p>
          <AddDocumentForm />
        </Card>
        {(docs ?? []).length === 0 ? (
          <p className="shadow-card rounded-xl border border-line bg-surface px-4 py-3 text-sm text-muted">No documents yet. The Assistant can&apos;t answer anything until you add some.</p>
        ) : (
          <ul className="divide-y divide-line shadow-card rounded-xl border border-line bg-surface">
            {(docs ?? []).map((d) => (
              <li key={d.id} className="flex flex-wrap items-center justify-between gap-3 px-4 py-3">
                <div className="min-w-48 flex-1">
                  <p className="font-semibold">{d.title}</p>
                  <p className="text-xs text-muted">Added {when(d.created_at)}</p>
                </div>
                <form action={setDocumentAudience} className="flex items-center gap-2">
                  <input type="hidden" name="id" value={d.id} />
                  <label className="sr-only" htmlFor={`aud-${d.id}`}>
                    Who can use {d.title}
                  </label>
                  <select id={`aud-${d.id}`} name="audience" defaultValue={d.audience} className={`${inputClass} w-40`}>
                    {AUDIENCES.map((a) => (
                      <option key={a} value={a}>
                        {AUDIENCE_LABELS[a]}
                      </option>
                    ))}
                  </select>
                  <Button size="sm" variant="outline">
                    Change
                  </Button>
                </form>
                <form action={deleteDocument}>
                  <input type="hidden" name="id" value={d.id} />
                  <Button size="sm" variant="outline">
                    Delete
                  </Button>
                </form>
              </li>
            ))}
          </ul>
        )}
      </section>

      {admin ? (
        <section className="flex flex-col gap-2">
          <h2 className="flex items-center gap-2 heading-sm">Model, limits and credit {pendingPart("limits") ? <NotLiveBadge /> : null}</h2>
          <Card className="flex flex-col gap-4 p-4">
            <TestAiButton />
            <LimitsForm s={s} />
          </Card>
        </section>
      ) : null}

      <section className="flex flex-col gap-2">
        <h2 className="heading-sm">Questions people asked</h2>
        <p className="text-sm text-muted">
          A record that fills in by itself as people use the website (no names), so it can&apos;t be edited. Questions it couldn&apos;t answer show first: upload a document that covers them and it will answer next time.
        </p>
        {log.length === 0 ? (
          <p className="shadow-card rounded-xl border border-line bg-surface px-4 py-3 text-sm text-muted">No questions yet.</p>
        ) : (
          <ul className="divide-y divide-line shadow-card rounded-xl border border-line bg-surface">
            {log.map((q) => (
              <li key={q.id} className="flex flex-wrap items-center justify-between gap-2 px-4 py-3 text-sm">
                <span className="min-w-48 flex-1">{q.question}</span>
                <Badge tone={q.answered ? "good" : "warn"}>{q.answered ? "Answered" : "Couldn't answer"}</Badge>
                <span className="text-xs text-muted">{when(q.created_at)}</span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </>
  );
}
