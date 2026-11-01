// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addComment, escalateTask } from "./tasks/actions";

// cmeprojects: a question or request someone raised, opened in place. They
// can't complete it (the person looking after it does); they can follow up
// or escalate it to the next level.
export function QuestionPanel({ taskId, canEscalate }: { taskId: string; canEscalate: boolean }) {
  const [mode, setMode] = useState<"none" | "follow" | "escalate">("none");
  const [cState, cAction, cPending] = useActionState(addComment, null);
  const [eState, eAction, ePending] = useActionState(escalateTask, null);
  const state = mode === "escalate" ? eState : cState;
  return (
    <div className="flex flex-col gap-2">
      <div className="flex flex-wrap gap-2">
        <Button type="button" size="sm" variant={mode === "follow" ? "secondary" : "outline"} onClick={() => setMode(mode === "follow" ? "none" : "follow")}>
          Follow up
        </Button>
        {canEscalate ? (
          <Button type="button" size="sm" variant={mode === "escalate" ? "secondary" : "outline"} onClick={() => setMode(mode === "escalate" ? "none" : "escalate")}>
            Escalate
          </Button>
        ) : null}
      </div>
      {mode === "follow" ? (
        <form action={cAction} className="flex flex-col gap-2">
          <input type="hidden" name="task_id" value={taskId} />
          <label htmlFor={`fu-${taskId}`} className="text-sm font-medium">
            Your follow-up (they&apos;ll be told)
          </label>
          <textarea id={`fu-${taskId}`} name="body" rows={2} maxLength={4000} required className={`${inputClass} min-h-20 py-3`} />
          <Button size="sm" disabled={cPending} className="self-start">
            {cPending ? "Sending…" : "Send follow-up"}
          </Button>
        </form>
      ) : null}
      {mode === "escalate" ? (
        <form action={eAction} className="flex flex-col gap-2">
          <input type="hidden" name="task_id" value={taskId} />
          <label className="flex flex-col gap-1 text-sm font-medium">
            Send it to
            <select name="to" defaultValue="team_leader" className={`${inputClass} max-w-xs`}>
              <option value="team_leader">My team leader</option>
              <option value="manager">The managers</option>
            </select>
          </label>
          <label htmlFor={`es-${taskId}`} className="text-sm font-medium">
            Why does it need escalating?
          </label>
          <textarea id={`es-${taskId}`} name="reason" rows={2} maxLength={1000} required className={`${inputClass} min-h-20 py-3`} />
          <Button size="sm" disabled={ePending} className="self-start">
            {ePending ? "Sending…" : "Escalate"}
          </Button>
        </form>
      ) : null}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}
