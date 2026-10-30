// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useMemo, useState, useTransition } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Badge, Button, Field, Notice, inputClass } from "@/components/ui";
import { FormFiller } from "@/components/form-filler";
import { QTYPES, blankQuestion, hasOptions, type FormInfo, type FormQuestion, type QType } from "@/lib/form-types";
import { publishForm, saveForm } from "../../actions";

const tick = "h-5 w-5 shrink-0 accent-[var(--brand-primary)]";

// cmeprojects: making a form. One page: a name, a note, questions one under
// another, a few options, and Try it to fill it in as staff will.
export function FormEditor({
  form: initialForm,
  questions: initialQuestions,
  brand,
  me,
  userId,
  replies,
}: {
  form: FormInfo;
  questions: FormQuestion[];
  brand: { companyName: string; logoUrl: string };
  me: { name: string; email: string };
  userId: string;
  replies: number;
}) {
  const router = useRouter();
  const [form, setForm] = useState(initialForm);
  const [questions, setQuestions] = useState(initialQuestions.filter((q) => !q.archived));
  const [baseline, setBaseline] = useState(() => JSON.stringify({ f: initialForm, q: initialQuestions.filter((q) => !q.archived) }));
  const [trying, setTrying] = useState(false);
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const dirty = useMemo(() => JSON.stringify({ f: form, q: questions }) !== baseline, [form, questions, baseline]);
  const set = <K extends keyof FormInfo>(k: K, v: FormInfo[K]) => setForm((f) => ({ ...f, [k]: v }));
  const setQ = (id: string, patch: Partial<FormQuestion>) => setQuestions((list) => list.map((q) => (q.id === id ? { ...q, ...patch } : q)));
  const move = (i: number, by: number) =>
    setQuestions((list) => {
      const next = [...list];
      [next[i], next[i + by]] = [next[i + by], next[i]];
      return next.map((q, n) => ({ ...q, sort_order: n + 1 }));
    });

  const save = (then?: () => Promise<{ error?: string; message?: string }>) =>
    start(async () => {
      const r = await saveForm(form.id, { form, questions });
      if (r.error) return setResult(r);
      const ids = r.ids ?? {};
      const saved = questions.map((q, n) => ({ ...q, id: ids[q.id] ?? q.id, sort_order: n + 1 }));
      setQuestions(saved);
      setBaseline(JSON.stringify({ f: form, q: saved }));
      if (then) {
        const t = await then();
        setResult(t);
        if (!t.error) setForm((f) => ({ ...f, status: "published", enabled: true }));
      } else setResult(r);
      router.refresh();
    });

  return (
    <div className="flex w-full max-w-3xl flex-col gap-4">
      <div className="sticky top-0 z-20 -mx-4 flex flex-wrap items-center gap-2 border-b border-line bg-page/95 px-4 py-3 backdrop-blur md:-mx-8 md:px-8">
        <div className="min-w-0 flex-1">
          <Link href="/forms" className="text-xs text-muted underline">
            Forms
          </Link>
          <div className="flex flex-wrap items-center gap-2">
            <h1 className="heading-sm truncate">{form.title || "New form"}</h1>
            {form.status === "published" ? <Badge tone="good">Published</Badge> : <Badge tone="grey">Draft</Badge>}
            {dirty ? <Badge tone="warn">Unsaved changes</Badge> : null}
          </div>
        </div>
        <Button type="button" variant="outline" onClick={() => setTrying((t) => !t)}>
          {trying ? "Back to editing" : "Try it"}
        </Button>
        <Button type="button" variant="outline" disabled={pending || !dirty} onClick={() => save()}>
          {pending ? "Saving…" : "Save"}
        </Button>
        {form.status === "draft" ? (
          <Button type="button" disabled={pending} onClick={() => save(() => publishForm(form.id))}>
            Publish
          </Button>
        ) : null}
      </div>
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message ? <Notice tone="success">{result.message}</Notice> : null}
      {form.status === "published" && !dirty ? (
        <p className="text-sm">
          <Link href={`/forms?open=${form.id}`} className="font-semibold text-brand underline">
            Send it, put it in Compliance, or get its link and QR code →
          </Link>
        </p>
      ) : null}

      {trying ? (
        <div className="rounded-lg border-2 border-dashed border-brand/40 bg-surface p-5 sm:p-7">
          <p className="mb-4 text-xs font-semibold tracking-wider text-brand uppercase">Try it: as staff will see it. Nothing is saved.</p>
          <FormFiller form={form} questions={questions} brand={brand} contact={me} userId={userId} mode="preview" />
        </div>
      ) : (
        <>
          <div className="flex flex-col gap-3 rounded-lg border border-line bg-surface p-5">
            <Field label="Name of the form" htmlFor="fm-title">
              <input id="fm-title" value={form.title} maxLength={120} onChange={(e) => set("title", e.target.value)} className={inputClass} />
            </Field>
            <Field label="A note at the top (optional)" htmlFor="fm-intro" hint="What it's for and how long it takes.">
              <textarea id="fm-intro" rows={2} maxLength={2000} value={form.intro} onChange={(e) => set("intro", e.target.value)} className={`${inputClass} min-h-16 py-3`} />
            </Field>
          </div>

          <ol className="flex flex-col gap-3">
            {questions.map((q, i) => (
              <li key={q.id} className="flex flex-col gap-3 rounded-lg border border-line bg-surface p-4">
                <div className="flex items-start gap-2">
                  <span className="mt-3 w-6 shrink-0 text-sm font-semibold text-muted">{i + 1}.</span>
                  <div className="grid min-w-0 flex-1 gap-2 sm:grid-cols-[1fr_12rem]">
                    <label htmlFor={`q-${q.id}`} className="sr-only">
                      Question {i + 1}
                    </label>
                    <input
                      id={`q-${q.id}`}
                      value={q.label}
                      maxLength={300}
                      placeholder="Type the question"
                      onChange={(e) => setQ(q.id, { label: e.target.value })}
                      className={inputClass}
                    />
                    <label htmlFor={`t-${q.id}`} className="sr-only">
                      Kind of answer
                    </label>
                    <select
                      id={`t-${q.id}`}
                      value={q.type}
                      onChange={(e) => {
                        const type = e.target.value as QType;
                        setQ(q.id, { type, options: hasOptions(type) && q.options.length === 0 ? ["", ""] : q.options });
                      }}
                      className={inputClass}
                    >
                      {(Object.keys(QTYPES) as QType[]).map((t) => (
                        <option key={t} value={t}>
                          {QTYPES[t]}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
                {hasOptions(q.type) ? (
                  <div className="flex flex-col gap-2 pl-8">
                    {q.options.map((o, n) => (
                      <div key={n} className="flex items-center gap-2">
                        <span aria-hidden="true" className={`size-4 shrink-0 border-2 border-muted ${q.type === "choice" ? "rounded-full" : "rounded"}`} />
                        <label htmlFor={`o-${q.id}-${n}`} className="sr-only">
                          Choice {n + 1}
                        </label>
                        <input
                          id={`o-${q.id}-${n}`}
                          value={o}
                          maxLength={100}
                          placeholder={`Choice ${n + 1}`}
                          onChange={(e) => setQ(q.id, { options: q.options.map((x, m) => (m === n ? e.target.value : x)) })}
                          className={`${inputClass} h-10 min-w-0 flex-1`}
                        />
                        <button type="button" aria-label={`Remove choice ${n + 1}`} onClick={() => setQ(q.id, { options: q.options.filter((_, m) => m !== n) })} className="size-9 rounded-full text-muted hover:bg-page">
                          ×
                        </button>
                      </div>
                    ))}
                    <button type="button" onClick={() => setQ(q.id, { options: [...q.options, ""] })} className="self-start text-sm font-semibold text-brand">
                      + Add a choice
                    </button>
                  </div>
                ) : null}
                <div className="flex flex-wrap items-center gap-x-5 gap-y-2 pl-8">
                  <label className="flex items-center gap-2 text-sm">
                    <input type="checkbox" checked={q.required} onChange={(e) => setQ(q.id, { required: e.target.checked })} className={tick} />
                    Must be answered
                  </label>
                  <label htmlFor={`h-${q.id}`} className="sr-only">
                    Help text
                  </label>
                  <input
                    id={`h-${q.id}`}
                    value={q.help}
                    maxLength={300}
                    placeholder="A tip under the question (optional)"
                    onChange={(e) => setQ(q.id, { help: e.target.value })}
                    className={`${inputClass} h-10 min-w-48 flex-1`}
                  />
                  <span className="ml-auto flex gap-1">
                    <button type="button" aria-label="Move up" disabled={i === 0} onClick={() => move(i, -1)} className="size-9 rounded-md border border-line text-muted disabled:opacity-30">
                      ↑
                    </button>
                    <button type="button" aria-label="Move down" disabled={i === questions.length - 1} onClick={() => move(i, 1)} className="size-9 rounded-md border border-line text-muted disabled:opacity-30">
                      ↓
                    </button>
                    <button type="button" aria-label="Remove question" onClick={() => setQuestions((list) => list.filter((x) => x.id !== q.id))} className="h-9 rounded-md border border-line px-3 text-sm text-danger">
                      Remove
                    </button>
                  </span>
                </div>
              </li>
            ))}
          </ol>
          <Button type="button" variant="outline" className="self-start" onClick={() => setQuestions((list) => [...list, blankQuestion(list.length + 1)])}>
            + Add a question
          </Button>
          {replies ? <p className="text-xs text-muted">{replies} {replies === 1 ? "reply" : "replies"} so far. Removing a question hides it; answers already given are kept.</p> : null}

          <fieldset className="flex flex-col gap-3 rounded-lg border border-line bg-surface p-5">
            <legend className="px-1 text-sm font-semibold">Options</legend>
            <div className="flex flex-wrap gap-x-6 gap-y-2 text-sm">
              <label className="flex items-center gap-2">
                <input type="radio" name="fm-repeat" checked={!form.repeatable} onChange={() => set("repeatable", false)} className={tick} />
                Each person fills it in once
              </label>
              <label className="flex items-center gap-2">
                <input type="radio" name="fm-repeat" checked={form.repeatable} onChange={() => set("repeatable", true)} className={tick} />
                As many times as needed (e.g. an incident form)
              </label>
            </div>
            <label className="flex items-start gap-2 text-sm">
              <input type="checkbox" checked={form.show_header} onChange={(e) => set("show_header", e.target.checked)} className={`${tick} mt-0.5`} />
              <span>Company header at the top ({brand.companyName} and logo)</span>
            </label>
            <label className="flex items-start gap-2 text-sm">
              <input type="checkbox" checked={form.show_contact} onChange={(e) => set("show_contact", e.target.checked)} className={`${tick} mt-0.5`} />
              <span>
                &quot;Questions? Contact {me.name}&quot; at the bottom, with {me.email} under it
              </span>
            </label>
            <label className="flex items-start gap-2 text-sm">
              <input type="checkbox" checked={form.anonymous} onChange={(e) => set("anonymous", e.target.checked)} className={`${tick} mt-0.5`} />
              <span>
                Anonymous replies
                <span className="block text-xs text-muted">You see the answers and who has done it, but not who wrote which answers.</span>
              </span>
            </label>
            <label className="flex items-start gap-2 text-sm">
              <input type="checkbox" checked={form.notify_creator} onChange={(e) => set("notify_creator", e.target.checked)} className={`${tick} mt-0.5`} />
              <span>Tell me in the bell each time someone sends a reply</span>
            </label>
            <div className="grid gap-3 sm:grid-cols-2">
              <Field label="Due date (optional)" htmlFor="fm-due" hint="Shown on the form and in the email.">
                <input id="fm-due" type="date" value={form.due_date ?? ""} onChange={(e) => set("due_date", e.target.value || null)} className={inputClass} />
              </Field>
              <Field label="Stop taking replies after (optional)" htmlFor="fm-close">
                <input id="fm-close" type="date" value={form.closes_on ?? ""} onChange={(e) => set("closes_on", e.target.value || null)} className={inputClass} />
              </Field>
            </div>
          </fieldset>
        </>
      )}
    </div>
  );
}
