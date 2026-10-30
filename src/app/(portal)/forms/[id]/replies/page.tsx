// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formsOn, loadForm } from "@/lib/forms";
import { buildFormReport } from "@/lib/form-report";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import { Card, PageHeader, buttonClass } from "@/components/ui";
import { DataTable } from "@/components/data-table";
import { PrintButton } from "@/components/print-button";
import { PrintHeader } from "@/components/print-header";
import { PrintLandscape } from "@/components/print-landscape";
import { LiveRefresh } from "@/components/live-refresh";
import { RemindButton } from "./remind";

export async function generateMetadata({ params }: PageProps<"/forms/[id]/replies">): Promise<Metadata> {
  const def = await loadForm((await params).id);
  return { title: def ? `${def.form.title}: replies` : "Replies" };
}

// cmeprojects: a form's replies, for the person who made it and anyone it's shared with.
export default async function FormRepliesPage({ params }: PageProps<"/forms/[id]/replies">) {
  const { features } = await requireSession();
  if (!formsOn(features)) notFound();
  const def = await loadForm((await params).id);
  if (!def) notFound();
  const supabase = await createClient();
  const { data: canManage } = await supabase.rpc("can_manage_form", { p_form: def.form.id });
  if (!canManage) notFound();
  const { form, questions } = def;
  const [timeZone, brand] = await Promise.all([getTimeZone(), getBranding()]);
  const report = await buildFormReport(form, questions, timeZone);
  const fileLinks = await Promise.all(
    report.files.map(async (f) => ({ ...f, url: (await supabase.storage.from("form-files").createSignedUrl(f.path, 3600)).data?.signedUrl ?? "" })),
  );
  const printedAt = new Intl.DateTimeFormat("en-AU", { dateStyle: "medium", timeStyle: "short", timeZone }).format(new Date());
  const subtitle = `${report.totals.replies} ${report.totals.replies === 1 ? "reply" : "replies"}`;

  return (
    <>
      <LiveRefresh tables={["form_responses", "form_completions"]} />
      <PrintLandscape />
      <PrintHeader brand={brand} title={form.title} subtitle={subtitle} printedAt={printedAt} />
      <div className="print:hidden">
        <p className="text-xs text-muted">
          <Link href={`/forms?open=${form.id}`} className="underline">
            Forms
          </Link>{" "}
          › {form.title}
        </p>
        <PageHeader
          title={`${form.title}: replies`}
          intro={
            form.anonymous
              ? "Every reply, with who sent it and when. People could choose to answer anonymously: those replies show Anonymous."
              : "Every reply, with who sent it and when."
          }
          action={
            <div className="flex flex-wrap gap-2">
              <a href={`/forms/${form.id}/replies/export`} className={buttonClass("primary")}>
                Download Excel
              </a>
              <PrintButton label="Print or save as PDF" />
            </div>
          }
        />
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4 print:flex print:flex-wrap print:gap-2">
        {[
          { label: "Replies", n: report.totals.replies, tone: "text-brand" },
          { label: "Sent to", n: report.totals.sent, tone: "text-brand" },
          { label: "Done", n: report.totals.done, tone: "text-good" },
          { label: "Still to do", n: report.totals.toDo, tone: report.totals.toDo ? "text-warn" : "text-muted" },
        ].map((s) => (
          <Card key={s.label} className="p-4 print:flex print:items-baseline print:gap-1.5 print:rounded-md print:px-2.5 print:py-1">
            <p className={`heading tabular-nums ${s.tone} print:text-base`}>{s.n}</p>
            <p className="text-sm text-muted print:text-xs">{s.label}</p>
          </Card>
        ))}
      </div>

      {report.people.length ? (
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-line px-5 py-3">
            <h2 className="heading-sm">Who&apos;s done it</h2>
            {report.totals.toDo ? <RemindButton formId={form.id} /> : null}
          </div>
          <ul className="grid gap-x-6 px-5 py-3 text-sm sm:grid-cols-2 lg:grid-cols-3">
            {report.people.map((p) => (
              <li key={p.name} className="flex justify-between gap-3 border-b border-line py-1.5 last:border-b-0">
                <span>{p.name}</span>
                <span className={p.done ? "text-good" : "text-warn"}>{p.done ? `Done ${p.done}` : "Still to do"}</span>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}

      {report.counts.length ? (
        <div className="grid gap-4 md:grid-cols-2">
          {report.counts.map((c) => (
            <Card key={c.question} className="flex break-inside-avoid flex-col gap-2 p-5">
              <h2 className="font-semibold">{c.question}</h2>
              <p className="text-xs text-muted">{c.total} answered</p>
              {c.options.map((o) => {
                const pct = c.total ? Math.round((o.n / c.total) * 100) : 0;
                return (
                  <div key={o.label} className="flex items-center gap-2 text-sm">
                    <span className="w-32 truncate">{o.label}</span>
                    <span className="h-2.5 flex-1 overflow-hidden rounded-full bg-page">
                      <span className="block h-full rounded-full bg-brand" style={{ width: `${pct}%` }} />
                    </span>
                    <span className="w-16 text-right tabular-nums text-muted">
                      {o.n} · {pct}%
                    </span>
                  </div>
                );
              })}
            </Card>
          ))}
        </div>
      ) : null}

      <Card className="overflow-hidden">
        <div className="border-b border-line px-5 py-3">
          <h2 className="heading-sm">Every reply</h2>
        </div>
        <DataTable table={report.table} empty="No replies yet." />
      </Card>

      {fileLinks.length ? (
        <Card className="p-5 print:hidden">
          <h2 className="heading-sm">Files and photos</h2>
          <ul className="mt-2 flex flex-col gap-1 text-sm">
            {fileLinks.map((f) => (
              <li key={f.path}>
                {f.url ? (
                  <a href={f.url} target="_blank" rel="noopener noreferrer" className="font-semibold text-brand underline">
                    {f.question}
                  </a>
                ) : (
                  f.question
                )}{" "}
                <span className="text-muted">· {f.reply}</span>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  );
}
