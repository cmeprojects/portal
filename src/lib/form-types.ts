// Staff Portal · © cmeproject. All rights reserved.

// Forms (cmeprojects): shared by the form editor, the form staff fill in and the replies report.

export type QType = "text" | "long" | "choice" | "multi" | "yesno" | "date" | "number" | "file" | "signature";

export const QTYPES: Record<QType, string> = {
  text: "Short answer",
  long: "Long answer",
  choice: "Pick one",
  multi: "Tick boxes",
  yesno: "Yes / no",
  date: "Date",
  number: "Number",
  file: "Photo or file",
  signature: "Signature (typed name)",
};

export type FormQuestion = {
  id: string;
  label: string;
  type: QType;
  required: boolean;
  help: string;
  options: string[];
  sort_order: number;
  archived: boolean;
};

export type FormInfo = {
  id: string;
  title: string;
  intro: string;
  status: "draft" | "published";
  enabled: boolean;
  repeatable: boolean;
  anonymous: boolean;
  show_header: boolean;
  show_contact: boolean;
  notify_creator: boolean;
  due_date: string | null;
  closes_on: string | null;
  created_by: string;
  created_at: string;
  published_at: string | null;
};

export type FormAnswers = Record<string, string | string[]>;

export const newQuestionId = () => `new-${Math.random().toString(36).slice(2, 10)}`;

export function blankQuestion(sort: number): FormQuestion {
  return { id: newQuestionId(), label: "", type: "text", required: false, help: "", options: [], sort_order: sort, archived: false };
}

export const hasOptions = (t: QType) => t === "choice" || t === "multi";

// An answer as text, for lists, the report and Excel.
export function answerText(q: Pick<FormQuestion, "type">, v: unknown): string {
  if (v == null || v === "") return "";
  if (Array.isArray(v)) return v.join(", ");
  if (q.type === "file") return "File attached";
  if (q.type === "signature") return `Signed: ${String(v)}`;
  return String(v);
}
