// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Cell, Table } from "@/lib/register-rows";
import { answerText, type FormInfo, type FormQuestion } from "@/lib/form-types";

// A form's replies (cmeprojects): who's done it, a count for each choice,
// and every reply. Anonymous forms show answers without names.

export type FormReport = {
  table: Table;
  counts: { question: string; total: number; options: { label: string; n: number }[] }[];
  people: { name: string; done: string | null; sent: boolean }[];
  files: { reply: string; question: string; path: string }[];
  totals: { replies: number; sent: number; done: number; toDo: number };
};

export async function buildFormReport(form: FormInfo, allQuestions: FormQuestion[], timeZone: string): Promise<FormReport> {
  const supabase = await createClient();
  const [{ data: replies }, { data: people }, { data: recipients }, { data: completions }] = await Promise.all([
    supabase.from("form_responses").select("id, user_id, answers, submitted_at").eq("form_id", form.id).eq("status", "submitted").order("submitted_at", { ascending: false }).limit(10000),
    supabase.rpc("form_people", { p_form: form.id }),
    supabase.from("form_recipients").select("user_id, sent_at").eq("form_id", form.id),
    supabase.from("form_completions").select("user_id, done_at").eq("form_id", form.id),
  ]);
  const nameOf = new Map(((people ?? []) as { id: string; name: string }[]).map((p) => [p.id, p.name]));
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit", timeZone });
  const rows = (replies ?? []) as { id: number; user_id: string | null; answers: Record<string, unknown>; submitted_at: string }[];
  // Questions that are on the form, plus removed ones that still have answers.
  const questions = allQuestions.filter((q) => !q.archived || rows.some((r) => r.answers[q.id] != null)).sort((a, b) => a.sort_order - b.sort_order);

  const table: Table = {
    columns: [
      { key: "when", label: "Sent" },
      { key: "who", label: "Name" },
      ...questions.map((q) => ({ key: q.id, label: q.label, wide: q.type === "long" })),
    ],
    rows: rows.map((r) => ({
      id: String(r.id),
      href: "",
      cells: {
        when: { text: when.format(new Date(r.submitted_at)).replace(",", "") },
        who: r.user_id ? { text: nameOf.get(r.user_id) ?? "Someone" } : { text: "Anonymous", tone: "muted" },
        ...Object.fromEntries(
          questions.map((q) => [q.id, { text: answerText(q, r.answers[q.id]), num: q.type === "number" && r.answers[q.id] != null ? Number(r.answers[q.id]) : undefined } as Cell]),
        ),
      } as Record<string, Cell>,
    })),
  };

  const counts = questions
    .filter((q) => q.type === "choice" || q.type === "multi" || q.type === "yesno")
    .map((q) => {
      const labels = q.type === "yesno" ? ["Yes", "No"] : q.options;
      const tally = new Map(labels.map((l) => [l, 0]));
      let total = 0;
      for (const r of rows) {
        const v = r.answers[q.id];
        const list = Array.isArray(v) ? (v as string[]) : typeof v === "string" && v ? [v] : [];
        if (list.length) total += 1;
        for (const x of list) tally.set(x, (tally.get(x) ?? 0) + 1);
      }
      return { question: q.label, total, options: [...tally.entries()].map(([label, n]) => ({ label, n })) };
    });

  const doneAt = new Map(((completions ?? []) as { user_id: string; done_at: string }[]).map((c) => [c.user_id, c.done_at]));
  const sentTo = new Set(((recipients ?? []) as { user_id: string }[]).map((r) => r.user_id));
  const everyone = new Set([...sentTo, ...doneAt.keys()]);
  const list = [...everyone]
    .map((id) => ({ name: nameOf.get(id) ?? "Someone", done: doneAt.has(id) ? when.format(new Date(doneAt.get(id)!)) : null, sent: sentTo.has(id) }))
    .sort((a, b) => Number(Boolean(a.done)) - Number(Boolean(b.done)) || a.name.localeCompare(b.name));

  const fileQs = questions.filter((q) => q.type === "file");
  const files = rows.flatMap((r) =>
    fileQs
      .filter((q) => typeof r.answers[q.id] === "string" && r.answers[q.id])
      .map((q) => ({ reply: `${when.format(new Date(r.submitted_at))} · ${r.user_id ? nameOf.get(r.user_id) ?? "" : "Anonymous"}`, question: q.label, path: String(r.answers[q.id]) })),
  );

  return {
    table,
    counts,
    people: list,
    files,
    totals: {
      replies: rows.length,
      sent: sentTo.size,
      done: [...sentTo].filter((u) => doneAt.has(u)).length,
      toDo: [...sentTo].filter((u) => !doneAt.has(u)).length,
    },
  };
}
