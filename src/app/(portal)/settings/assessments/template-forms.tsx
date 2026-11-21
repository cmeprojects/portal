// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useEffect, useState, useTransition } from "react";
import { ArrowDown, ArrowUp, Eye, Plus, Trash2, X } from "lucide-react";
import { Button, Card, Notice, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { AssessmentSteps } from "@/components/assessment-form";
import { ATYPES, FINDING_KINDS, OPS, keyFrom, kindLabel, type AQuestion, type ASection, type Answers, type Condition, type Mapping, type Op, type Rule } from "@/lib/assessment-rules";
import { createTemplate, deleteDraftPart, moveQuestion, newVersion, publishVersion, retireVersion, saveQuestion, saveSection, saveTemplateDetails } from "./actions";

const lab = "flex flex-col gap-1 text-xs font-medium";
const today = () => new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });

function SchemeTicks({ schemes, chosen }: { schemes: [string, string][]; chosen: string[] }) {
  return (
    <fieldset className="flex flex-wrap items-center gap-x-4 gap-y-1">
      <legend className="mb-1 text-xs font-medium">For which programs? (none ticked = all programs)</legend>
      {schemes.map(([k, l]) => (
        <label key={k} className="inline-flex min-h-9 items-center gap-2 text-sm">
          <input type="checkbox" name="schemes" value={k} defaultChecked={chosen.includes(k)} className="size-4 accent-[var(--brand-primary)]" />
          {l}
        </label>
      ))}
    </fieldset>
  );
}

export function NewTemplateForm({ schemes }: { schemes: [string, string][] }) {
  const [state, action, pending] = useActionState(createTemplate, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <div className="grid gap-3 sm:grid-cols-2">
        <label className={lab}>
          Name
          <input name="name" required maxLength={120} placeholder="For example: Home support assessment" className={inputClass} />
        </label>
        <label className={lab}>
          Description (optional)
          <input name="description" maxLength={1000} className={inputClass} />
        </label>
      </div>
      <SchemeTicks schemes={schemes} chosen={[]} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button className="self-start" disabled={pending}>
        {pending ? "Making…" : "Make template"}
      </Button>
    </form>
  );
}

export function TemplateDetailsForm({ template, schemes }: { template: { id: string; name: string; description: string; schemes: string[]; active: boolean }; schemes: [string, string][] }) {
  const [state, action, pending] = useActionState(saveTemplateDetails, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={template.id} />
      <div className="grid gap-3 sm:grid-cols-2">
        <label className={lab}>
          Name
          <input name="name" required maxLength={120} defaultValue={template.name} className={inputClass} />
        </label>
        <label className={lab}>
          Description
          <input name="description" maxLength={1000} defaultValue={template.description} className={inputClass} />
        </label>
      </div>
      <SchemeTicks schemes={schemes} chosen={template.schemes} />
      <label className="inline-flex items-center gap-2 text-sm">
        <input type="checkbox" name="active" defaultChecked={template.active} className="size-4 accent-[var(--brand-primary)]" /> In use (can be chosen for new assessments)
      </label>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending}>
        {pending ? "Saving…" : "Save details"}
      </Button>
    </form>
  );
}

export function VersionActions({ templateId, hasDraft, published }: { templateId: string; hasDraft: boolean; published: string | null }) {
  const [pending, start] = useTransition();
  const make = async () => {
    if (!(await askConfirm("Make a new draft version from the latest one? The published version keeps working until the new one is published.", { action: "Make new version" }))) return;
    start(async () => {
      const r = await newVersion(templateId);
      toast(r?.error ?? r?.message ?? "", r?.error ? "error" : "success");
    });
  };
  const retire = async () => {
    if (!published) return;
    if (!(await askConfirm("Retire the published version? It can't be used for new assessments. Completed assessments keep it.", { action: "Retire", danger: true }))) return;
    start(async () => {
      const r = await retireVersion(published, templateId);
      toast(r?.error ?? r?.message ?? "", r?.error ? "error" : "success");
    });
  };
  return (
    <span className="flex flex-wrap gap-2">
      {!hasDraft ? (
        <Button size="sm" variant="outline" icon={Plus} disabled={pending} onClick={make}>
          New version
        </Button>
      ) : null}
      {published ? (
        <Button size="sm" variant="danger" disabled={pending} onClick={retire}>
          Retire published version
        </Button>
      ) : null}
    </span>
  );
}

// Who, which test, what value: one condition. The question is chosen from earlier ones.
function ConditionRow({ c, earlier, onChange, onRemove, fixedQuestion }: { c: Condition; earlier: AQuestion[]; onChange: (c: Condition) => void; onRemove?: () => void; fixedQuestion?: AQuestion }) {
  const q = fixedQuestion ?? earlier.find((x) => x.key === c.q);
  const needsValue = !["answered", "not_answered"].includes(c.op);
  const listed = q && (q.type === "choice" || q.type === "multi" || q.type === "yesno");
  const opts = q?.type === "yesno" ? ["Yes", "No"] : (q?.options ?? []);
  return (
    <div className="flex flex-wrap items-center gap-2">
      {fixedQuestion ? (
        <span className="text-xs text-muted">When the answer</span>
      ) : (
        <select aria-label="Question" value={c.q ?? ""} onChange={(e) => onChange({ ...c, q: e.target.value })} className={`${inputClass} h-9 max-w-56 text-sm`}>
          <option value="">Choose a question</option>
          {earlier.map((x) => (
            <option key={x.key} value={x.key}>
              {x.label}
            </option>
          ))}
        </select>
      )}
      <select aria-label="Test" value={c.op} onChange={(e) => onChange({ ...c, op: e.target.value as Op, value: e.target.value === "in" ? [] : "" })} className={`${inputClass} h-9 w-36 text-sm`}>
        {OPS.map(([o, l]) => (
          <option key={o} value={o}>
            {l}
          </option>
        ))}
      </select>
      {needsValue ? (
        c.op === "in" && listed ? (
          <span className="flex flex-wrap gap-2">
            {opts.map((o) => (
              <label key={o} className="inline-flex items-center gap-1 text-xs">
                <input
                  type="checkbox"
                  checked={Array.isArray(c.value) && c.value.includes(o)}
                  onChange={(e) => {
                    const now = Array.isArray(c.value) ? c.value : [];
                    onChange({ ...c, value: e.target.checked ? [...now, o] : now.filter((x) => x !== o) });
                  }}
                />
                {o}
              </label>
            ))}
          </span>
        ) : listed && (c.op === "is" || c.op === "is_not") ? (
          <select aria-label="Value" value={String(c.value ?? "")} onChange={(e) => onChange({ ...c, value: e.target.value })} className={`${inputClass} h-9 max-w-48 text-sm`}>
            <option value="">Choose</option>
            {opts.map((o) => (
              <option key={o}>{o}</option>
            ))}
          </select>
        ) : (
          <input aria-label="Value" value={Array.isArray(c.value) ? c.value.join(", ") : String(c.value ?? "")} onChange={(e) => onChange({ ...c, value: c.op === "in" ? e.target.value.split(",").map((x) => x.trim()) : e.target.value })} className={`${inputClass} h-9 max-w-40 text-sm`} />
        )
      ) : null}
      {onRemove ? (
        <button type="button" onClick={onRemove} aria-label="Remove condition" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
          <X aria-hidden="true" className="size-4" />
        </button>
      ) : null}
    </div>
  );
}

function RuleEditor({ rule, setRule, earlier }: { rule: Rule; setRule: (r: Rule) => void; earlier: AQuestion[] }) {
  const when = rule?.when ?? [];
  if (!earlier.length) return <p className="text-xs text-muted">Always shown (there are no earlier questions to depend on).</p>;
  return (
    <div className="flex flex-col gap-2 rounded-lg border border-line p-2">
      <div className="flex flex-wrap items-center gap-2 text-xs">
        <span className="font-semibold">Show only when</span>
        {when.length > 1 ? (
          <select aria-label="All or any" value={rule?.match ?? "all"} onChange={(e) => setRule({ match: e.target.value === "any" ? "any" : "all", when })} className={`${inputClass} h-8 w-40 text-xs`}>
            <option value="all">all of these are true</option>
            <option value="any">any of these is true</option>
          </select>
        ) : null}
        {!when.length ? <span className="text-muted">(always shown)</span> : null}
      </div>
      {when.map((c, i) => (
        <ConditionRow
          key={i}
          c={c}
          earlier={earlier}
          onChange={(nc) => setRule({ match: rule?.match ?? "all", when: when.map((x, j) => (j === i ? nc : x)) })}
          onRemove={() => setRule(when.length > 1 ? { match: rule?.match ?? "all", when: when.filter((_, j) => j !== i) } : null)}
        />
      ))}
      <button type="button" onClick={() => setRule({ match: rule?.match ?? "all", when: [...when, { q: earlier[earlier.length - 1].key, op: "is", value: "" }] })} className="self-start text-xs font-semibold text-brand hover:underline">
        + Add a condition
      </button>
    </div>
  );
}

function MappingsEditor({ q, mappings, setMappings }: { q: AQuestion; mappings: Mapping[]; setMappings: (m: Mapping[]) => void }) {
  return (
    <div className="flex flex-col gap-2 rounded-lg border border-line p-2">
      <p className="text-xs font-semibold">Findings this answer makes</p>
      {mappings.map((m, i) => (
        <div key={i} className="flex flex-col gap-1.5 rounded-md bg-page p-2">
          <ConditionRow c={m.when ?? { op: "answered" }} earlier={[]} fixedQuestion={q} onChange={(c) => setMappings(mappings.map((x, j) => (j === i ? { ...x, when: c } : x)))} />
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs text-muted">it&apos;s a</span>
            <select aria-label="Kind of finding" value={m.kind} onChange={(e) => setMappings(mappings.map((x, j) => (j === i ? { ...x, kind: e.target.value as Mapping["kind"] } : x)))} className={`${inputClass} h-9 w-56 text-sm`}>
              {FINDING_KINDS.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
            <input aria-label="Wording" value={m.text} maxLength={500} placeholder="Wording; {answer} puts in the answer" onChange={(e) => setMappings(mappings.map((x, j) => (j === i ? { ...x, text: e.target.value } : x)))} className={`${inputClass} h-9 min-w-48 flex-1 text-sm`} />
            <button type="button" onClick={() => setMappings(mappings.filter((_, j) => j !== i))} aria-label="Remove finding" className="rounded-md p-1 text-muted hover:bg-surface hover:text-ink">
              <X aria-hidden="true" className="size-4" />
            </button>
          </div>
        </div>
      ))}
      <button type="button" onClick={() => setMappings([...mappings, { when: { op: "answered" }, kind: "need", text: "" }])} className="self-start text-xs font-semibold text-brand hover:underline">
        + Add a finding
      </button>
    </div>
  );
}

function useToastResult(state: { message?: string; error?: string } | null) {
  useEffect(() => {
    if (state?.message && !state.error) toast(state.message);
  }, [state]);
}

function QuestionForm({ q, templateId, versionId, sectionId, earlier, takenKeys, sort, onClose }: { q: AQuestion | null; templateId: string; versionId: string; sectionId: string; earlier: AQuestion[]; takenKeys: string[]; sort: number; onClose: () => void }) {
  const [state, action, pending] = useActionState(saveQuestion, null);
  useToastResult(state);
  useEffect(() => {
    if (state?.message && !state.error) onClose();
  }, [state, onClose]);
  const [label, setLabel] = useState(q?.label ?? "");
  const [type, setType] = useState(q?.type ?? "text");
  const [options, setOptions] = useState((q?.options ?? []).join("\n"));
  const [rule, setRule] = useState<Rule>(q?.rule ?? null);
  const [mappings, setMappings] = useState<Mapping[]>(q?.mappings ?? []);
  const key = q?.key ?? keyFrom(label, takenKeys);
  const draftQ: AQuestion = { ...(q ?? { id: "new", section_id: sectionId, key, help: "", required: false, validation: {}, rule: null, mappings: [], sort_order: sort }), label, type, options: options.split("\n").map((o) => o.trim()).filter(Boolean) };
  return (
    <form action={action} className="flex flex-col gap-3 rounded-lg border border-brand/30 bg-surface p-3">
      <input type="hidden" name="id" value={q?.id ?? ""} />
      <input type="hidden" name="template_id" value={templateId} />
      <input type="hidden" name="version_id" value={versionId} />
      <input type="hidden" name="section_id" value={sectionId} />
      <input type="hidden" name="sort_order" value={q?.sort_order ?? sort} />
      <input type="hidden" name="key" value={key} />
      <input type="hidden" name="rule" value={JSON.stringify(rule)} />
      <input type="hidden" name="mappings" value={JSON.stringify(mappings)} />
      <div className="grid gap-3 sm:grid-cols-[1fr_12rem]">
        <label className={lab}>
          Question
          <input name="label" required maxLength={300} value={label} onChange={(e) => setLabel(e.target.value)} className={inputClass} />
          <span className="font-normal text-muted">Key: {key} {q ? "(fixed, so answers can be reused)" : ""}</span>
        </label>
        <label className={lab}>
          Kind of answer
          <select name="type" value={type} onChange={(e) => setType(e.target.value as AQuestion["type"])} className={inputClass}>
            {ATYPES.map(([t, l]) => (
              <option key={t} value={t}>
                {l}
              </option>
            ))}
          </select>
        </label>
      </div>
      <label className={lab}>
        Help (optional)
        <input name="help" maxLength={300} defaultValue={q?.help ?? ""} className={inputClass} />
      </label>
      {type === "choice" || type === "multi" ? (
        <label className={lab}>
          Options (one per line)
          <textarea name="options" rows={4} value={options} onChange={(e) => setOptions(e.target.value)} className={`${inputClass} min-h-24 py-2`} />
        </label>
      ) : null}
      {type === "number" ? (
        <div className="grid max-w-sm grid-cols-2 gap-3">
          <label className={lab}>
            Lowest (optional)
            <input name="min" inputMode="decimal" defaultValue={q?.validation?.min ?? ""} className={inputClass} />
          </label>
          <label className={lab}>
            Highest (optional)
            <input name="max" inputMode="decimal" defaultValue={q?.validation?.max ?? ""} className={inputClass} />
          </label>
        </div>
      ) : null}
      <label className="inline-flex items-center gap-2 text-sm">
        <input type="checkbox" name="required" defaultChecked={q?.required ?? false} className="size-4 accent-[var(--brand-primary)]" /> Must be answered (when it shows)
      </label>
      <RuleEditor rule={rule} setRule={setRule} earlier={earlier} />
      <MappingsEditor q={draftQ} mappings={mappings} setMappings={setMappings} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex flex-wrap gap-2">
        <Button disabled={pending}>{pending ? "Saving…" : "Save question"}</Button>
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
      </div>
    </form>
  );
}

function SectionForm({ s, templateId, versionId, earlier, sort, onClose }: { s: ASection | null; templateId: string; versionId: string; earlier: AQuestion[]; sort: number; onClose: () => void }) {
  const [state, action, pending] = useActionState(saveSection, null);
  useToastResult(state);
  useEffect(() => {
    if (state?.message && !state.error) onClose();
  }, [state, onClose]);
  const [rule, setRule] = useState<Rule>(s?.rule ?? null);
  return (
    <form action={action} className="flex flex-col gap-3 rounded-lg border border-brand/30 bg-surface p-3">
      <input type="hidden" name="id" value={s?.id ?? ""} />
      <input type="hidden" name="template_id" value={templateId} />
      <input type="hidden" name="version_id" value={versionId} />
      <input type="hidden" name="sort_order" value={s?.sort_order ?? sort} />
      <input type="hidden" name="rule" value={JSON.stringify(rule)} />
      <label className={lab}>
        Section title
        <input name="title" required maxLength={120} defaultValue={s?.title ?? ""} className={inputClass} />
      </label>
      <label className="inline-flex items-center gap-2 text-sm">
        <input type="checkbox" name="enabled" defaultChecked={s?.enabled ?? true} className="size-4 accent-[var(--brand-primary)]" /> Section switched on
      </label>
      <RuleEditor rule={rule} setRule={setRule} earlier={earlier} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex flex-wrap gap-2">
        <Button disabled={pending}>{pending ? "Saving…" : "Save section"}</Button>
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
      </div>
    </form>
  );
}

function PublishForm({ templateId, versionId }: { templateId: string; versionId: string }) {
  const [state, action, pending] = useActionState(publishVersion, null);
  useToastResult(state);
  return (
    <form
      action={action}
      onSubmit={async (e) => {
        if (!(e.currentTarget as HTMLFormElement).dataset.ok) {
          e.preventDefault();
          const form = e.currentTarget as HTMLFormElement;
          if (await askConfirm("Publish this version? Published versions can't be changed. New assessments use it from the date you chose.", { action: "Publish" })) {
            form.dataset.ok = "1";
            form.requestSubmit();
          }
        }
      }}
      className="flex flex-wrap items-end gap-3"
    >
      <input type="hidden" name="template_id" value={templateId} />
      <input type="hidden" name="version_id" value={versionId} />
      <label className={lab}>
        Takes effect from
        <DateInput name="effective_from" defaultValue={today()} required />
      </label>
      <Button disabled={pending}>{pending ? "Publishing…" : "Publish this version"}</Button>
      {state?.error ? <div className="basis-full"><Notice tone="error">{state.error}</Notice></div> : null}
    </form>
  );
}

export function TemplateEditor({ templateId, version, sections, questions }: { templateId: string; version: { id: string; version: number; status: "draft" | "published" | "retired" }; sections: ASection[]; questions: AQuestion[] }) {
  const draft = version.status === "draft";
  const [editing, setEditing] = useState<string | null>(null); // "q:<id>", "q-new:<section>", "s:<id>", "s-new"
  const [trying, setTrying] = useState(false);
  const [tryAnswers, setTryAnswers] = useState<Answers>({});
  const [busy, start] = useTransition();
  const ordered = [...sections].sort((a, b) => a.sort_order - b.sort_order);
  const allQs = ordered.flatMap((s) => questions.filter((q) => q.section_id === s.id).sort((a, b) => a.sort_order - b.sort_order));
  const earlierThan = (s: ASection, q?: AQuestion) => allQs.filter((x) => {
    const xs = ordered.find((y) => y.id === x.section_id);
    if (!xs) return false;
    if (xs.sort_order !== s.sort_order) return xs.sort_order < s.sort_order;
    return q ? x.sort_order < q.sort_order : true;
  });
  const remove = async (table: "assessment_sections" | "assessment_questions", id: string, what: string) => {
    if (!(await askConfirm(`Remove ${what} from this draft?`, { action: "Remove", danger: true }))) return;
    start(async () => {
      const r = await deleteDraftPart(table, id, templateId);
      toast(r?.error ?? r?.message ?? "", r?.error ? "error" : "success");
    });
  };
  const move = (a: AQuestion, b: AQuestion | undefined) => b && start(async () => {
    const r = await moveQuestion(a.id, b.id, templateId);
    if (r?.error) toast(r.error, "error");
  });
  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap items-center gap-2">
        <p className="flex-1 text-sm text-muted">
          {draft ? "Draft: change anything, then publish. " : version.status === "published" ? "Published: this version can't be changed. Make a new version to change it. " : "Retired: kept for the assessments that used it. "}
          {allQs.length} question{allQs.length === 1 ? "" : "s"} in {ordered.length} section{ordered.length === 1 ? "" : "s"}.
        </p>
        <Button size="sm" variant="outline" icon={Eye} onClick={() => setTrying((t) => !t)}>
          {trying ? "Close Try it" : "Try it"}
        </Button>
      </div>
      {trying ? (
        <Card className="border-brand/40 p-4">
          <p className="mb-3 text-xs font-semibold text-brand">Try it: nothing is saved. Questions with a rule appear as you answer.</p>
          <AssessmentSteps sections={ordered} questions={allQs} answers={tryAnswers} setAnswer={(k, v) => setTryAnswers((a) => ({ ...a, [k]: v }))} />
        </Card>
      ) : null}
      {ordered.map((s, si) => {
        const qs = questions.filter((q) => q.section_id === s.id).sort((a, b) => a.sort_order - b.sort_order);
        return (
          <Card key={s.id} className="p-4">
            {editing === `s:${s.id}` ? (
              <SectionForm s={s} templateId={templateId} versionId={version.id} earlier={allQs.filter((x) => (ordered.find((y) => y.id === x.section_id)?.sort_order ?? 0) < s.sort_order)} sort={s.sort_order} onClose={() => setEditing(null)} />
            ) : (
              <div className="mb-2 flex flex-wrap items-center gap-2">
                <h3 className="heading-sm flex-1">
                  {si + 1}. {s.title}
                  {!s.enabled ? <span className="ml-2 text-xs font-normal text-muted">(switched off)</span> : null}
                  {s.rule?.when?.length ? <span className="ml-2 rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Shows only when…</span> : null}
                </h3>
                {draft ? (
                  <>
                    <Button size="sm" variant="outline" onClick={() => setEditing(`s:${s.id}`)}>
                      Edit section
                    </Button>
                    {!qs.length ? (
                      <Button size="sm" variant="danger" icon={Trash2} disabled={busy} onClick={() => remove("assessment_sections", s.id, `the section "${s.title}"`)}>
                        Remove
                      </Button>
                    ) : null}
                  </>
                ) : null}
              </div>
            )}
            <ol className="flex flex-col gap-2">
              {qs.map((q, qi) => (
                <li key={q.id}>
                  {editing === `q:${q.id}` ? (
                    <QuestionForm q={q} templateId={templateId} versionId={version.id} sectionId={s.id} earlier={earlierThan(s, q)} takenKeys={questions.map((x) => x.key)} sort={q.sort_order} onClose={() => setEditing(null)} />
                  ) : (
                    <div className="flex flex-wrap items-start gap-2 rounded-lg border border-line px-3 py-2 text-sm">
                      <span className="min-w-48 flex-1">
                        <span className="font-semibold">{q.label}</span>
                        {q.required ? <span className="ml-1 text-danger">*</span> : null}
                        <span className="block text-xs text-muted">
                          {ATYPES.find(([t]) => t === q.type)?.[1]} · key {q.key}
                          {q.options.length ? ` · ${q.options.join(", ")}` : ""}
                          {q.rule?.when?.length ? " · shows only when…" : ""}
                        </span>
                        {q.mappings.length ? (
                          <span className="mt-1 flex flex-wrap gap-1">
                            {q.mappings.map((m, i) => (
                              <span key={i} className="rounded-full bg-page px-2 py-0.5 text-xs ring-1 ring-line">
                                {kindLabel(m.kind)}: {m.text}
                              </span>
                            ))}
                          </span>
                        ) : null}
                      </span>
                      {draft ? (
                        <span className="flex gap-1">
                          <button type="button" aria-label="Move up" disabled={busy || qi === 0} onClick={() => move(q, qs[qi - 1])} className="rounded-md p-1 text-muted hover:bg-page disabled:opacity-30">
                            <ArrowUp aria-hidden="true" className="size-4" />
                          </button>
                          <button type="button" aria-label="Move down" disabled={busy || qi === qs.length - 1} onClick={() => move(q, qs[qi + 1])} className="rounded-md p-1 text-muted hover:bg-page disabled:opacity-30">
                            <ArrowDown aria-hidden="true" className="size-4" />
                          </button>
                          <Button size="sm" variant="outline" onClick={() => setEditing(`q:${q.id}`)}>
                            Edit
                          </Button>
                          <button type="button" aria-label={`Remove ${q.label}`} disabled={busy} onClick={() => remove("assessment_questions", q.id, `"${q.label}"`)} className="rounded-md p-1 text-muted hover:bg-danger-soft hover:text-danger">
                            <Trash2 aria-hidden="true" className="size-4" />
                          </button>
                        </span>
                      ) : null}
                    </div>
                  )}
                </li>
              ))}
            </ol>
            {draft ? (
              editing === `q-new:${s.id}` ? (
                <div className="mt-2">
                  <QuestionForm q={null} templateId={templateId} versionId={version.id} sectionId={s.id} earlier={earlierThan(s)} takenKeys={questions.map((x) => x.key)} sort={(qs[qs.length - 1]?.sort_order ?? 0) + 1} onClose={() => setEditing(null)} />
                </div>
              ) : (
                <button type="button" onClick={() => setEditing(`q-new:${s.id}`)} className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-brand hover:underline">
                  <Plus aria-hidden="true" className="size-4" /> Add a question
                </button>
              )
            ) : null}
          </Card>
        );
      })}
      {draft ? (
        <>
          {editing === "s-new" ? (
            <SectionForm s={null} templateId={templateId} versionId={version.id} earlier={allQs} sort={(ordered[ordered.length - 1]?.sort_order ?? 0) + 1} onClose={() => setEditing(null)} />
          ) : (
            <Button variant="outline" icon={Plus} className="self-start" onClick={() => setEditing("s-new")}>
              Add a section
            </Button>
          )}
          <Card className="p-4">
            <h3 className="heading-sm mb-2">Publish</h3>
            <PublishForm templateId={templateId} versionId={version.id} />
          </Card>
        </>
      ) : null}
    </div>
  );
}
