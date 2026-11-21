// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Plus } from "lucide-react";
import { Button, Card, Notice, inputClass } from "@/components/ui";
import { startAssessment } from "./assessment-actions";

const lab = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (update 159): start an assessment. Only templates for the
// client's open programs (or common ones) are offered; answers that still fit
// can be reused from their latest completed assessment, to be confirmed.
export function StartAssessmentForm({ clientId, templates, enrolments, latest }: { clientId: string; templates: { id: string; name: string; schemes: string[] }[]; enrolments: { id: string; scheme: string; name: string; paused: boolean }[]; latest: { id: string; label: string; templateId: string } | null }) {
  const [state, action, pending] = useActionState(startAssessment, null);
  const [open, setOpen] = useState(false);
  const [templateId, setTemplateId] = useState(templates[0]?.id ?? "");
  const tpl = templates.find((t) => t.id === templateId);
  const fitting = tpl && tpl.schemes.length ? enrolments.filter((e) => tpl.schemes.includes(e.scheme)) : [];
  if (!templates.length) {
    return <p className="text-sm text-muted">No assessment templates fit their programs yet. A Manager Administrator sets them up in Portal settings, Assessment templates.</p>;
  }
  if (!open) {
    return (
      <Button className="self-start" icon={Plus} onClick={() => setOpen(true)}>
        Start assessment
      </Button>
    );
  }
  return (
    <Card className="p-4">
      <form action={action} className="flex flex-col gap-3">
        <input type="hidden" name="client_id" value={clientId} />
        <div className="grid gap-3 sm:grid-cols-2">
          <label className={lab}>
            Assessment
            <select name="template_id" value={templateId} onChange={(e) => setTemplateId(e.target.value)} className={inputClass}>
              {templates.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
          </label>
          {fitting.length ? (
            <label className={lab}>
              For which program?
              <select name="enrolment_id" className={inputClass}>
                {fitting.map((e) => (
                  <option key={e.id} value={e.id}>
                    {e.name}
                    {e.paused ? " (paused)" : ""}
                  </option>
                ))}
              </select>
            </label>
          ) : null}
        </div>
        {latest ? (
          <div className="flex flex-col gap-1 rounded-lg border border-line p-3 text-sm">
            <label className="inline-flex items-center gap-2">
              <input type="checkbox" name="from_id" value={latest.id} defaultChecked className="size-4 accent-[var(--brand-primary)]" />
              Reuse answers that still fit from their {latest.label} (you&apos;ll confirm each one)
            </label>
            {latest.templateId === templateId ? (
              <label className="inline-flex items-center gap-2">
                <input type="checkbox" name="replaces" defaultChecked className="size-4 accent-[var(--brand-primary)]" />
                This replaces that assessment (it becomes superseded when this one is completed; it&apos;s kept)
              </label>
            ) : null}
          </div>
        ) : null}
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        <div className="flex gap-2">
          <Button disabled={pending}>{pending ? "Starting…" : "Start"}</Button>
          <Button type="button" variant="outline" onClick={() => setOpen(false)}>
            Cancel
          </Button>
        </div>
      </form>
    </Card>
  );
}
