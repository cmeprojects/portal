// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, Plus, Printer, RotateCcw, XCircle } from "lucide-react";
import { Button, Card, Notice, buttonClass, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { AssessmentSteps, type Reused } from "@/components/assessment-form";
import { FINDING_KINDS, answerText, kindLabel, visibleQuestions, type AQuestion, type ASection, type Answer, type Answers } from "@/lib/assessment-rules";
import { addFinding, cancelAssessment, completeAssessment, recordAssessmentPrint, saveAssessment, startAssessment, updateFinding } from "../../assessment-actions";

export type Finding = { id: string; kind: string; text: string; detail: string; origin: "manual" | "mapped"; source_key: string | null; source_answer: string | null; state: "active" | "withdrawn" | "answer_changed"; edited: boolean };

type Props = {
  id: string;
  clientId: string;
  templateId: string;
  enrolmentId: string | null;
  status: "draft" | "completed" | "superseded" | "cancelled";
  canEdit: boolean;
  sections: ASection[];
  questions: AQuestion[];
  answers: Answers;
  reused: Reused;
  reusedFrom: Record<string, string>;
  updatedAt: string;
  findings: Finding[];
};

// cmeprojects (update 159): filling in, or reading, one client assessment.
export function AssessmentFill(p: Props) {
  const router = useRouter();
  const editing = p.canEdit && p.status === "draft";
  const [answers, setAnswers] = useState<Answers>(p.answers);
  const [confirmed, setConfirmed] = useState<string[]>([]);
  // The version of the saved record this screen is working from (a ref, so Complete uses the newest).
  const updatedAt = useRef(p.updatedAt);
  const [saving, setSaving] = useState<"idle" | "saving" | "saved" | "error">("idle");
  const [problem, setProblem] = useState("");
  const [stale, setStale] = useState(false);
  const dirty = useRef(false);
  const timer = useRef<number | null>(null);
  const [, start] = useTransition();
  const reusedNow: Reused = Object.fromEntries(Object.entries(p.reused).map(([k, r]) => [k, { ...r, confirmed: r.confirmed || confirmed.includes(k) }]));

  // The latest answers and confirmations (refs, so a queued save sends the newest).
  const answersRef = useRef<Answers>(p.answers);
  const confirmedRef = useRef<string[]>([]);
  const inFlight = useRef<Promise<boolean> | null>(null);

  // Only answers to questions that show are kept (a hidden one isn't part of the assessment).
  const toSave = () => {
    const a = answersRef.current;
    const vis = visibleQuestions(p.sections, p.questions, a);
    return Object.fromEntries(p.questions.filter((q) => vis.has(q.id) && a[q.key] !== undefined && answerText(a[q.key]) !== "").map((q) => [q.key, a[q.key]]));
  };
  const runSave = async (): Promise<boolean> => {
    setSaving("saving");
    const r = await saveAssessment(p.id, toSave(), confirmedRef.current, updatedAt.current);
    if (r.error) {
      setSaving("error");
      setProblem(r.error);
      if (r.stale) setStale(true);
      return false;
    }
    if (r.updatedAt) updatedAt.current = r.updatedAt;
    setSaving("saved");
    setProblem("");
    start(() => router.refresh()); // findings follow the answers
    return true;
  };
  // One save at a time: a change made while saving waits, then saves with the new version.
  const save = async (): Promise<boolean> => {
    while (inFlight.current) await inFlight.current;
    if (!dirty.current) return true;
    dirty.current = false;
    const job = runSave();
    inFlight.current = job;
    try {
      return await job;
    } finally {
      inFlight.current = null;
    }
  };
  const later = () => {
    dirty.current = true;
    if (timer.current) window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => void save(), 1200);
  };
  useEffect(() => () => {
    if (timer.current) window.clearTimeout(timer.current);
  }, []);

  const setAnswer = (key: string, v: Answer) => {
    answersRef.current = { ...answersRef.current, [key]: v };
    setAnswers(answersRef.current);
    if (p.reused[key] && !confirmedRef.current.includes(key)) {
      confirmedRef.current = [...confirmedRef.current, key]; // changing it counts as checking it
      setConfirmed(confirmedRef.current);
    }
    later();
  };
  const confirm = (key: string) => {
    if (!confirmedRef.current.includes(key)) {
      confirmedRef.current = [...confirmedRef.current, key];
      setConfirmed(confirmedRef.current);
    }
    later();
  };
  const complete = async () => {
    if (timer.current) window.clearTimeout(timer.current);
    dirty.current = true; // make sure the latest is saved first
    if (!(await save())) return;
    if (!(await askConfirm("Complete this assessment? A completed assessment can't be changed. Corrections are made by starting a new assessment from it.", { action: "Complete assessment" }))) return;
    const r = await completeAssessment(p.id, updatedAt.current);
    if (r.error) {
      setProblem(r.error);
      if (r.stale) setStale(true);
      return;
    }
    toast("Assessment completed.");
    router.refresh();
  };
  const print = async () => {
    await recordAssessmentPrint(p.id);
    window.print();
  };

  return (
    <div className="flex flex-col gap-4 lg:flex-row lg:items-start">
      <Card className="min-w-0 flex-1 p-4 print:hidden">
        {stale ? (
          <div className="mb-3 flex flex-wrap items-center gap-2 rounded-lg border border-warn/40 bg-warn-soft p-3 text-sm">
            <span className="flex-1 font-semibold text-warn">{problem || "Changed by someone else."}</span>
            <Button size="sm" variant="outline" icon={RotateCcw} onClick={() => window.location.reload()}>
              Reload
            </Button>
          </div>
        ) : null}
        <AssessmentSteps sections={p.sections} questions={p.questions} answers={answers} setAnswer={editing ? setAnswer : undefined} reused={reusedNow} reusedFrom={p.reusedFrom} confirm={editing ? confirm : undefined} readOnly={!editing} />
        {editing ? (
          <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-line pt-3">
            <span className="flex-1 text-xs text-muted" aria-live="polite">
              {saving === "saving" ? "Saving…" : saving === "saved" ? "All changes saved" : saving === "error" && !stale ? problem : "Saved as you go"}
            </span>
            <CancelButton id={p.id} />
            <Button icon={CheckCircle2} onClick={complete}>
              Complete assessment
            </Button>
          </div>
        ) : (
          <div className="mt-4 flex flex-wrap gap-2 border-t border-line pt-3">
            <Button variant="outline" icon={Printer} onClick={print}>
              Print
            </Button>
            {p.canEdit && p.status === "completed" ? <StartFromThis clientId={p.clientId} templateId={p.templateId} enrolmentId={p.enrolmentId} fromId={p.id} /> : null}
          </div>
        )}
        {problem && !stale && saving !== "error" ? (
          <div className="mt-3">
            <Notice tone="error">{problem}</Notice>
          </div>
        ) : null}
      </Card>
      <aside className="flex w-full flex-col gap-3 lg:w-96 print:hidden">
        <Findings assessmentId={p.id} findings={p.findings} editing={editing} />
      </aside>
      <PrintCopy sections={p.sections} questions={p.questions} answers={answers} findings={p.findings} />
    </div>
  );
}

function CancelButton({ id }: { id: string }) {
  const [open, setOpen] = useState(false);
  const [state, action, pending] = useActionState(cancelAssessment, null);
  const router = useRouter();
  useEffect(() => {
    if (state?.message) {
      toast(state.message);
      router.refresh();
    }
  }, [state, router]);
  if (!open) {
    return (
      <Button variant="danger" icon={XCircle} onClick={() => setOpen(true)}>
        Cancel assessment
      </Button>
    );
  }
  return (
    <form action={action} className="flex basis-full flex-wrap items-end gap-2 rounded-lg border border-line p-2">
      <input type="hidden" name="id" value={id} />
      <label className="flex min-w-56 flex-1 flex-col gap-1 text-xs font-medium">
        Why is it cancelled? (it&apos;s kept with their records)
        <input name="cancel_reason" required maxLength={300} className={inputClass} />
      </label>
      <button type="submit" disabled={pending} className={buttonClass("danger")}>
        {pending ? "Cancelling…" : "Cancel it"}
      </button>
      <Button type="button" variant="outline" onClick={() => setOpen(false)}>
        Keep it
      </Button>
      {state?.error ? <div className="basis-full"><Notice tone="error">{state.error}</Notice></div> : null}
    </form>
  );
}

function StartFromThis({ clientId, templateId, enrolmentId, fromId }: { clientId: string; templateId: string; enrolmentId: string | null; fromId: string }) {
  const [state, action, pending] = useActionState(startAssessment, null);
  return (
    <form
      action={action}
      onSubmit={async (e) => {
        const form = e.currentTarget;
        if (!form.dataset.ok) {
          e.preventDefault();
          if (await askConfirm("Start a new assessment from this one? Answers that still fit are filled in for you to confirm. When the new one is completed, this one becomes superseded (it's kept).", { action: "Start new assessment" })) {
            form.dataset.ok = "1";
            form.requestSubmit();
          }
        }
      }}
    >
      <input type="hidden" name="client_id" value={clientId} />
      <input type="hidden" name="template_id" value={templateId} />
      <input type="hidden" name="enrolment_id" value={enrolmentId ?? ""} />
      <input type="hidden" name="from_id" value={fromId} />
      <input type="hidden" name="replaces" value="on" />
      <Button variant="outline" icon={RotateCcw} disabled={pending}>
        {pending ? "Starting…" : "Start a new assessment from this one"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
    </form>
  );
}

function Findings({ assessmentId, findings, editing }: { assessmentId: string; findings: Finding[]; editing: boolean }) {
  const [showWithdrawn, setShowWithdrawn] = useState(false);
  const [adding, setAdding] = useState(false);
  const live = findings.filter((f) => f.state !== "withdrawn");
  const withdrawn = findings.filter((f) => f.state === "withdrawn");
  return (
    <Card className="p-4">
      <div className="mb-2 flex items-center gap-2">
        <h2 className="heading-sm flex-1">Findings</h2>
        {editing ? (
          <Button size="sm" variant="outline" icon={Plus} onClick={() => setAdding((a) => !a)}>
            Add finding
          </Button>
        ) : null}
      </div>
      <p className="mb-2 text-xs text-muted">Made from the answers{editing ? "; you can edit them or add your own until the assessment is completed" : ""}. The answers themselves aren&apos;t changed.</p>
      {adding ? <FindingForm assessmentId={assessmentId} onDone={() => setAdding(false)} /> : null}
      {live.length === 0 ? <p className="text-sm text-muted">No findings yet.</p> : null}
      <ul className="flex flex-col gap-2">
        {live.map((f) => (
          <FindingRow key={f.id} f={f} editing={editing} />
        ))}
      </ul>
      {withdrawn.length ? (
        <div className="mt-2">
          <button type="button" onClick={() => setShowWithdrawn((s) => !s)} className="text-xs font-semibold text-muted hover:text-ink">
            {showWithdrawn ? "Hide" : "Show"} withdrawn ({withdrawn.length})
          </button>
          {showWithdrawn ? (
            <ul className="mt-1 flex flex-col gap-1">
              {withdrawn.map((f) => (
                <li key={f.id} className="rounded-md bg-page px-2 py-1 text-xs text-muted line-through">
                  {kindLabel(f.kind)}: {f.text}
                </li>
              ))}
            </ul>
          ) : null}
        </div>
      ) : null}
    </Card>
  );
}

function FindingRow({ f, editing }: { f: Finding; editing: boolean }) {
  const [edit, setEdit] = useState(false);
  const [kind, setKind] = useState(f.kind);
  const [text, setText] = useState(f.text);
  const [detail, setDetail] = useState(f.detail);
  const [pending, start] = useTransition();
  const router = useRouter();
  const run = (patch: Parameters<typeof updateFinding>[1]) =>
    start(async () => {
      const r = await updateFinding(f.id, patch);
      if (r?.error) toast(r.error, "error");
      else {
        setEdit(false);
        router.refresh();
      }
    });
  return (
    <li className={`rounded-lg border px-3 py-2 text-sm ${f.state === "answer_changed" ? "border-warn/50 bg-warn-soft" : "border-line"}`}>
      {edit ? (
        <div className="flex flex-col gap-2">
          <select aria-label="Kind" value={kind} onChange={(e) => setKind(e.target.value)} className={`${inputClass} h-9 text-sm`}>
            {FINDING_KINDS.map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
          <input aria-label="Finding" value={text} maxLength={1000} onChange={(e) => setText(e.target.value)} className={`${inputClass} h-9 text-sm`} />
          <textarea aria-label="Detail" value={detail} maxLength={2000} rows={2} placeholder="Detail (optional)" onChange={(e) => setDetail(e.target.value)} className={`${inputClass} min-h-16 py-2 text-sm`} />
          <div className="flex gap-2">
            <Button size="sm" disabled={pending} onClick={() => run({ kind, text, detail })}>
              Save
            </Button>
            <Button size="sm" variant="outline" onClick={() => setEdit(false)}>
              Cancel
            </Button>
          </div>
        </div>
      ) : (
        <>
          <p>
            <span className="mr-1 rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">{kindLabel(f.kind)}</span>
            {f.text}
          </p>
          {f.detail ? <p className="mt-1 text-xs text-muted whitespace-pre-wrap">{f.detail}</p> : null}
          <p className="mt-1 text-xs text-muted">
            {f.origin === "manual" ? "Added by the assessor" : `From the answer${f.source_answer ? ` "${f.source_answer}"` : ""}`}
            {f.edited ? " · edited" : ""}
          </p>
          {f.state === "answer_changed" ? <p className="mt-1 text-xs font-semibold text-warn">The answer changed since this was edited: check it, then save or withdraw.</p> : null}
          {editing ? (
            <div className="mt-1 flex gap-3 text-xs">
              <button type="button" onClick={() => setEdit(true)} className="font-semibold text-brand hover:underline">
                Edit
              </button>
              <button type="button" disabled={pending} onClick={() => run({ state: "withdrawn" })} className="font-semibold text-muted hover:text-danger">
                Withdraw
              </button>
            </div>
          ) : null}
        </>
      )}
    </li>
  );
}

function FindingForm({ assessmentId, onDone }: { assessmentId: string; onDone: () => void }) {
  const [kind, setKind] = useState("need");
  const [text, setText] = useState("");
  const [detail, setDetail] = useState("");
  const [pending, start] = useTransition();
  const router = useRouter();
  return (
    <div className="mb-2 flex flex-col gap-2 rounded-lg border border-brand/30 p-2">
      <select aria-label="Kind" value={kind} onChange={(e) => setKind(e.target.value)} className={`${inputClass} h-9 text-sm`}>
        {FINDING_KINDS.map(([k, l]) => (
          <option key={k} value={k}>
            {l}
          </option>
        ))}
      </select>
      <input aria-label="Finding" value={text} maxLength={1000} placeholder="The finding" onChange={(e) => setText(e.target.value)} className={`${inputClass} h-9 text-sm`} />
      <textarea aria-label="Detail" value={detail} maxLength={2000} rows={2} placeholder="Detail (optional)" onChange={(e) => setDetail(e.target.value)} className={`${inputClass} min-h-16 py-2 text-sm`} />
      <div className="flex gap-2">
        <Button
          size="sm"
          disabled={pending || !text.trim()}
          onClick={() =>
            start(async () => {
              const r = await addFinding(assessmentId, kind, text, detail);
              if (r?.error) toast(r.error, "error");
              else {
                onDone();
                router.refresh();
              }
            })
          }
        >
          Add
        </Button>
        <Button size="sm" variant="outline" onClick={onDone}>
          Cancel
        </Button>
      </div>
    </div>
  );
}

// The whole assessment for printing (the screen shows one section at a time).
function PrintCopy({ sections, questions, answers, findings }: { sections: ASection[]; questions: AQuestion[]; answers: Answers; findings: Finding[] }) {
  const visible = visibleQuestions(sections, questions, answers);
  return (
    <div className="hidden print:block">
      {[...sections].sort((a, b) => a.sort_order - b.sort_order).map((s) => {
        const qs = questions.filter((q) => q.section_id === s.id && visible.has(q.id)).sort((a, b) => a.sort_order - b.sort_order);
        if (!qs.length) return null;
        return (
          <section key={s.id} className="mb-4 break-inside-avoid">
            <h2 className="mb-1 text-base font-bold">{s.title}</h2>
            <dl className="text-sm">
              {qs.map((q) => (
                <div key={q.id} className="mb-1">
                  <dt className="font-semibold">{q.label}</dt>
                  <dd className="whitespace-pre-wrap">{answerText(answers[q.key]) || "Not answered"}</dd>
                </div>
              ))}
            </dl>
          </section>
        );
      })}
      <h2 className="mb-1 text-base font-bold">Findings</h2>
      <ul className="list-disc pl-5 text-sm">
        {findings.filter((f) => f.state !== "withdrawn").map((f) => (
          <li key={f.id}>
            {kindLabel(f.kind)}: {f.text}
          </li>
        ))}
      </ul>
    </div>
  );
}
