// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { ArrowLeft, ArrowRight, CheckCircle2, RotateCcw } from "lucide-react";
import { QuestionInput } from "@/components/question-input";
import { Req } from "@/components/required";
import { answerText, ruleOk, visibleQuestions, type AQuestion, type ASection, type Answer, type Answers } from "@/lib/assessment-rules";

export type Reused = Record<string, { from: string; confirmed: boolean }>;

// cmeprojects (update 159): an assessment, one section at a time. Questions
// with a "show only when" rule appear and disappear as answers change; the
// database applies the same rules. Used by "Try it" and by client assessments.
export function AssessmentSteps({
  sections,
  questions,
  answers,
  setAnswer,
  reused = {},
  reusedFrom = {},
  confirm,
  readOnly = false,
}: {
  sections: ASection[];
  questions: AQuestion[];
  answers: Answers;
  setAnswer?: (key: string, v: Answer) => void;
  reused?: Reused;
  reusedFrom?: Record<string, string>;
  confirm?: (key: string) => void;
  readOnly?: boolean;
}) {
  const shownSections = sections.filter((s) => s.enabled && ruleOk(s.rule, answers)).sort((a, b) => a.sort_order - b.sort_order);
  const visible = visibleQuestions(sections, questions, answers);
  const [step, setStep] = useState(0);
  const at = Math.min(step, Math.max(shownSections.length - 1, 0));
  const section = shownSections[at];
  if (!section) return <p className="text-sm text-muted">No questions yet.</p>;
  const qs = questions.filter((q) => q.section_id === section.id && visible.has(q.id)).sort((a, b) => a.sort_order - b.sort_order);
  const answeredIn = (s: ASection) => questions.filter((q) => q.section_id === s.id && visible.has(q.id) && q.required).every((q) => answerText(answers[q.key]) !== "");
  return (
    <div className="flex flex-col gap-4">
      <ol className="flex flex-wrap gap-1.5" aria-label="Sections">
        {shownSections.map((s, i) => (
          <li key={s.id}>
            <button
              type="button"
              onClick={() => setStep(i)}
              aria-current={i === at ? "step" : undefined}
              className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold ring-1 ${i === at ? "bg-brand text-brand-fg ring-brand" : "bg-surface text-muted ring-line hover:text-ink"}`}
            >
              {answeredIn(s) ? <CheckCircle2 aria-hidden="true" className="size-3.5" /> : null}
              {i + 1}. {s.title}
            </button>
          </li>
        ))}
      </ol>
      <div className="h-1.5 overflow-hidden rounded-full bg-page" aria-hidden="true">
        <div className="h-full rounded-full bg-brand transition-[width]" style={{ width: `${((at + 1) / shownSections.length) * 100}%` }} />
      </div>
      <section aria-labelledby={`sec-${section.id}`} className="flex flex-col gap-5">
        <h2 id={`sec-${section.id}`} className="heading-sm">
          {section.title}
        </h2>
        {qs.length === 0 ? <p className="text-sm text-muted">Nothing to answer in this section for now.</p> : null}
        {qs.map((q) => {
          const r = reused[q.key];
          return (
            <div key={q.id} className="flex flex-col gap-1.5">
              {/* Option buttons are labelled as a group, so each keeps its own name (Yes, No, …). */}
              {["choice", "multi", "yesno"].includes(q.type) || readOnly ? (
                <p id={`lbl-${q.id}`} className="text-sm font-semibold">
                  {q.label}
                  {q.required ? <Req /> : null}
                </p>
              ) : (
                <label htmlFor={`aq-${q.id}`} className="text-sm font-semibold">
                  {q.label}
                  {q.required ? <Req /> : null}
                </label>
              )}
              {q.help ? <p className="text-xs text-muted">{q.help}</p> : null}
              {readOnly ? (
                <p aria-labelledby={`lbl-${q.id}`} className="rounded-lg bg-page px-3 py-2 text-sm whitespace-pre-wrap">{answerText(answers[q.key]) || <span className="text-muted">Not answered</span>}</p>
              ) : ["choice", "multi", "yesno"].includes(q.type) ? (
                <div role="group" aria-labelledby={`lbl-${q.id}`}>
                  <QuestionInput id={`aq-${q.id}`} type={q.type} options={q.options} value={answers[q.key]} set={(v) => setAnswer?.(q.key, v)} />
                </div>
              ) : (
                <QuestionInput id={`aq-${q.id}`} type={q.type} options={q.options} value={answers[q.key]} set={(v) => setAnswer?.(q.key, v)} />
              )}
              {r ? (
                <p className={`flex flex-wrap items-center gap-2 text-xs ${r.confirmed ? "text-muted" : "font-semibold text-warn"}`}>
                  <RotateCcw aria-hidden="true" className="size-3.5" />
                  From {reusedFrom[r.from] ?? "an earlier assessment"}
                  {r.confirmed ? " · confirmed" : ""}
                  {!r.confirmed && !readOnly && confirm ? (
                    <button type="button" onClick={() => confirm(q.key)} className="rounded-md border border-warn/50 px-2 py-0.5 font-semibold hover:bg-warn-soft">
                      Confirm
                    </button>
                  ) : null}
                </p>
              ) : null}
            </div>
          );
        })}
      </section>
      <div className="flex flex-wrap justify-between gap-2 border-t border-line pt-3">
        <button type="button" disabled={at === 0} onClick={() => setStep(at - 1)} className="inline-flex min-h-10 items-center gap-1 rounded-lg border border-line px-3 text-sm font-semibold hover:bg-page disabled:opacity-40">
          <ArrowLeft aria-hidden="true" className="size-4" /> Previous
        </button>
        <button
          type="button"
          disabled={at >= shownSections.length - 1}
          onClick={() => setStep(at + 1)}
          className="inline-flex min-h-10 items-center gap-1 rounded-lg border border-line px-3 text-sm font-semibold hover:bg-page disabled:opacity-40"
        >
          Next <ArrowRight aria-hidden="true" className="size-4" />
        </button>
      </div>
    </div>
  );
}
