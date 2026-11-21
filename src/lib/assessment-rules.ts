// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects (update 159): assessment questions, "show only when" rules and
// finding mappings. The same rules run in the database (assessment_rule_ok,
// assessment_condition_ok); this copy decides what shows on screen.

export type AType = "text" | "long" | "choice" | "multi" | "yesno" | "date" | "number";
export type Op = "is" | "is_not" | "in" | "answered" | "not_answered" | "gt" | "lt";
export type Condition = { q?: string; op: Op; value?: string | number | string[] };
export type Rule = { match: "all" | "any"; when: Condition[] } | null;
export type Mapping = { when?: Condition; kind: FindingKind; text: string };
export type FindingKind = "need" | "goal" | "risk" | "limitation" | "support" | "intervention" | "frequency" | "equipment" | "preference";
export type Answer = string | string[];
export type Answers = Record<string, Answer>;
export type ASection = { id: string; title: string; sort_order: number; enabled: boolean; rule: Rule };
export type AQuestion = { id: string; section_id: string; key: string; label: string; type: AType; required: boolean; help: string; options: string[]; validation: { min?: number; max?: number; pattern?: string; pattern_hint?: string }; rule: Rule; mappings: Mapping[]; sort_order: number };

export const ATYPES: [AType, string][] = [
  ["text", "Short answer"],
  ["long", "Long answer"],
  ["choice", "Pick one"],
  ["multi", "Tick boxes"],
  ["yesno", "Yes / no"],
  ["date", "Date"],
  ["number", "Number"],
];
export const OPS: [Op, string][] = [
  ["is", "is"],
  ["is_not", "is not"],
  ["in", "is one of"],
  ["answered", "is answered"],
  ["not_answered", "isn't answered"],
  ["gt", "is more than"],
  ["lt", "is less than"],
];
export const FINDING_KINDS: [FindingKind, string][] = [
  ["need", "Need"],
  ["goal", "Goal"],
  ["risk", "Risk or safety"],
  ["limitation", "Functional limitation"],
  ["support", "Support needed"],
  ["intervention", "Recommended intervention"],
  ["frequency", "Frequency"],
  ["equipment", "Equipment or assistance"],
  ["preference", "Preference or instruction"],
];
export const kindLabel = (k: string) => FINDING_KINDS.find(([x]) => x === k)?.[1] ?? k;

const answered = (a: Answer | undefined) => a !== undefined && a !== "" && !(Array.isArray(a) && a.length === 0);

export function conditionOk(c: Condition, a: Answer | undefined): boolean {
  if (c.op === "answered") return answered(a);
  if (c.op === "not_answered") return !answered(a);
  if (!answered(a)) return false;
  const val = c.value;
  if (c.op === "is" || c.op === "is_not") {
    const hit = Array.isArray(a) ? a.includes(String(val)) : String(a) === String(val);
    return c.op === "is" ? hit : !hit;
  }
  if (c.op === "in") {
    if (!Array.isArray(val)) return false;
    return Array.isArray(a) ? a.some((x) => val.includes(x)) : val.includes(String(a));
  }
  if (c.op === "gt" || c.op === "lt") {
    const n = Number(a);
    const m = Number(val);
    if (!Number.isFinite(n) || !Number.isFinite(m) || Array.isArray(a)) return false;
    return c.op === "gt" ? n > m : n < m;
  }
  return false;
}

export function ruleOk(rule: Rule, answers: Answers): boolean {
  if (!rule || !rule.when?.length) return true;
  const each = rule.when.map((c) => conditionOk(c, c.q ? answers[c.q] : undefined));
  return rule.match === "any" ? each.some(Boolean) : each.every(Boolean);
}

export function visibleQuestions(sections: ASection[], questions: AQuestion[], answers: Answers): Set<string> {
  const on = new Set<string>();
  for (const s of sections) {
    if (!s.enabled || !ruleOk(s.rule, answers)) continue;
    for (const q of questions) if (q.section_id === s.id && ruleOk(q.rule, answers)) on.add(q.id);
  }
  return on;
}

export function answerText(a: Answer | undefined): string {
  if (a === undefined) return "";
  return Array.isArray(a) ? a.join(", ") : String(a);
}

// A question key from its label: "Do they live alone?" -> "do_they_live_alone".
export function keyFrom(label: string, taken: string[]): string {
  const base = (label.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "").replace(/^(\d)/, "q_$1") || "question").slice(0, 50);
  let k = base;
  let n = 2;
  while (taken.includes(k)) k = `${base}_${n++}`;
  return k;
}
