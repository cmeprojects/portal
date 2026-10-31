// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { AUD_PER_USD, AUDIENCE_LABELS, AUDIENCES, DEFAULT_SETTINGS, type AssistantSettings } from "@/lib/assistant-shared";
import { Badge, Button, Card, Notice, PageHeader, inputClass } from "@/components/ui";
import { AddDocumentForm, SettingsForm } from "./forms";
import { deleteDocument, setDocumentAudience } from "./actions";

export const metadata: Metadata = { title: "Website settings" };

const when = (iso: string) => new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "Australia/Sydney" }).format(new Date(iso));

// cmeprojects: the system admin's side of the website's Assistant: the
// documents it answers from, its wording and limits, and what people asked.
export default async function AssistantPage() {
  const { features } = await requireRole(["system_admin"]);
  const supabase = await createClient();
  const [{ data: settings }, { data: docs }, { data: questions }, { data: spent }, { data: front }] = await Promise.all([
    supabase.from("assistant_settings").select("*").maybeSingle(),
    supabase.from("assistant_documents").select("id, title, audience, created_at").order("created_at", { ascending: false }),
    supabase.from("assistant_questions").select("id, question, answered, sources, created_at").order("created_at", { ascending: false }).limit(100),
    supabase.from("assistant_questions").select("cost_usd").gte("created_at", new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
    supabase.from("app_settings").select("value").eq("key", "website.front_page").maybeSingle(),
  ]);
  const s: AssistantSettings = { ...DEFAULT_SETTINGS, ...(settings ?? {}), monthly_limit_aud: Number(settings?.monthly_limit_aud ?? DEFAULT_SETTINGS.monthly_limit_aud) };
  const usedAud = (spent ?? []).reduce((n, r) => n + Number(r.cost_usd), 0) * AUD_PER_USD;
  const unanswered = (questions ?? []).filter((q) => !q.answered);
  const log = [...unanswered, ...(questions ?? []).filter((q) => q.answered)].slice(0, 30);
  const setUp = Boolean(settings);

  return (
    <>
      <PageHeader
        eyebrow="System settings"
        title="Website settings"
        intro="The public website and its Assistant: how the landing page looks, where it looks for answers, and the documents it answers from."
        action={
          <Link href="/ask" className="inline-flex min-h-11 items-center rounded-md border border-line px-4 text-sm font-semibold hover:bg-brand-soft">
            Open website
          </Link>
        }
      />
      {!features.assistant ? <Notice>The website is switched off. Turn on &quot;Website and Assistant&quot; in System settings → Features when you&apos;re ready.</Notice> : null}
      {!setUp ? <Notice tone="error">The Assistant isn&apos;t set up in the database yet. Run live update 36, then refresh.</Notice> : null}
      {!process.env.ANTHROPIC_API_KEY ? (
        <Notice>
          No AI key is set, so the website shows what your documents say instead of a written answer. To switch on written answers, add ANTHROPIC_API_KEY in Vercel → Settings → Environment Variables.
        </Notice>
      ) : null}

      <section className="flex flex-col gap-2">
        <h2 className="heading-sm">Documents</h2>
        <Card className="p-4">
          <p className="mb-4 text-sm text-muted">
            Upload NDIS rules, company policies or public policies. Choose who can get answers from each one: the public, staff, or managers only. Scanned PDFs and photos of pages are read by the AI (a few cents each).
          </p>
          <AddDocumentForm />
        </Card>
        {(docs ?? []).length === 0 ? (
          <p className="rounded-lg border border-line bg-surface px-4 py-3 text-sm text-muted">No documents yet. The assistant can&apos;t answer anything until you add some.</p>
        ) : (
          <ul className="divide-y divide-line rounded-lg border border-line bg-surface">
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

      <section className="flex flex-col gap-2">
        <h2 className="heading-sm">Look, answers and limits</h2>
        <Card className="p-4">
          <p className="mb-4 text-sm text-muted">
            Spent this month: <strong className="text-ink">A${usedAud.toFixed(2)}</strong> of A${s.monthly_limit_aud.toFixed(0)}.
          </p>
          <SettingsForm s={s} frontPage={front?.value === true} />
        </Card>
      </section>

      <section className="flex flex-col gap-2">
        <h2 className="heading-sm">Questions people asked</h2>
        <p className="text-sm text-muted">
          A record that fills in by itself as people use the website (no names), so it can&apos;t be edited. Questions it couldn&apos;t answer show first: upload a document that covers them and it will answer next time.
        </p>
        {log.length === 0 ? (
          <p className="rounded-lg border border-line bg-surface px-4 py-3 text-sm text-muted">No questions yet.</p>
        ) : (
          <ul className="divide-y divide-line rounded-lg border border-line bg-surface">
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
