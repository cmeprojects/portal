// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { FileUpload } from "@/components/file-upload";
import type { FormState } from "@/lib/form";
import type { Status } from "@/lib/tasks";
import { addAttachment, addComment, changeStatus, escalateTask, reassignTask } from "../actions";

function Result({ state }: { state: FormState }) {
  if (state?.error) return <Notice tone="error">{state.error}</Notice>;
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return null;
}

export type Can = {
  start: boolean;
  complete: boolean;
  // Completing goes to a manager first.
  completeNeedsApproval: boolean;
  // A manager's own task in an approval register: no approval, just confirm.
  managerOwn: boolean;
  approve: boolean;
  close: boolean;
  reopen: boolean;
  resolveEscalation: boolean;
  escalate: boolean;
  reassign: boolean;
  takeOver: boolean;
};

// One button that changes the status, with an optional or required note.
function StatusButton({
  taskId,
  status,
  label,
  variant = "primary",
  note,
  confirmText,
}: {
  taskId: string;
  status: Status;
  label: string;
  variant?: "primary" | "outline" | "danger";
  note?: { label: string; required: boolean; placeholder?: string };
  confirmText?: string;
}) {
  const [state, action, pending] = useActionState(changeStatus, null);
  const [open, setOpen] = useState(false);
  if (note && !open) {
    return (
      <Button type="button" variant={variant} className="w-full" onClick={() => setOpen(true)}>
        {label}
      </Button>
    );
  }
  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (confirmText && !confirm(confirmText)) e.preventDefault();
      }}
      className="flex flex-col gap-2"
    >
      <Result state={state} />
      <input type="hidden" name="task_id" value={taskId} />
      <input type="hidden" name="status" value={status} />
      {confirmText ? <p className="text-sm text-muted">{confirmText}</p> : null}
      {note ? (
        <Field label={note.label} htmlFor={`note-${status}`}>
          <textarea id={`note-${status}`} name="note" rows={2} required={note.required} placeholder={note.placeholder} className={`${inputClass} min-h-20 py-3`} />
        </Field>
      ) : null}
      <Button variant={variant} className="w-full" disabled={pending}>
        {pending ? "Saving…" : label}
      </Button>
    </form>
  );
}

function ReasonForm({
  taskId,
  label,
  reasonLabel,
  action: run,
  people,
  takeOver,
  variant = "outline",
}: {
  taskId: string;
  label: string;
  reasonLabel: string;
  action: typeof escalateTask;
  people?: { id: string; name: string }[];
  takeOver?: boolean;
  variant?: "primary" | "outline" | "danger";
}) {
  const [state, action, pending] = useActionState(run, null);
  const [open, setOpen] = useState(false);
  if (!open) {
    return (
      <Button type="button" variant={variant} className="w-full" onClick={() => setOpen(true)}>
        {label}
      </Button>
    );
  }
  return (
    <form action={action} className="flex flex-col gap-2 rounded-md border border-line p-3">
      <Result state={state} />
      <input type="hidden" name="task_id" value={taskId} />
      {takeOver ? <input type="hidden" name="take_over" value="1" /> : null}
      {people ? (
        <Field label="Who should look after it?" htmlFor={`to-${taskId}`}>
          <select id={`to-${taskId}`} name="to" required defaultValue="" className={inputClass}>
            <option value="" disabled>
              Choose a person
            </option>
            {people.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </Field>
      ) : null}
      <Field label={reasonLabel} htmlFor={`reason-${label}`}>
        <textarea id={`reason-${label}`} name="reason" required rows={2} className={`${inputClass} min-h-20 py-3`} />
      </Field>
      <div className="flex gap-2">
        <Button variant={variant === "danger" ? "danger" : "primary"} className="flex-1" disabled={pending}>
          {pending ? "Saving…" : label}
        </Button>
        <Button type="button" variant="outline" onClick={() => setOpen(false)}>
          Cancel
        </Button>
      </div>
    </form>
  );
}

export function TaskActions({ taskId, can, people }: { taskId: string; can: Can; people: { id: string; name: string }[] }) {
  const any = Object.entries(can).some(([k, v]) => k !== "completeNeedsApproval" && k !== "managerOwn" && v);
  if (!any) return null;
  return (
    <div className="flex flex-col gap-2">
      {can.approve ? (
        <>
          <p className="text-sm font-semibold">This task is waiting for your approval.</p>
          <StatusButton taskId={taskId} status="completed" label="Approve and complete" />
          <StatusButton
            taskId={taskId}
            status="in_progress"
            label="Send back"
            variant="outline"
            note={{ label: "What still needs doing?", required: true }}
          />
        </>
      ) : null}
      {can.start ? <StatusButton taskId={taskId} status="in_progress" label="Start working on it" variant="outline" /> : null}
      {can.complete ? (
        <StatusButton
          taskId={taskId}
          status="completed"
          label={can.completeNeedsApproval ? "Finished: send for approval" : "Mark as completed"}
          note={{ label: "Note (optional)", required: false, placeholder: "What was done" }}
          confirmText={can.managerOwn ? "You're completing this as a manager, so no approval is needed." : undefined}
        />
      ) : null}
      {can.resolveEscalation ? <StatusButton taskId={taskId} status="in_progress" label="Escalation dealt with" variant="outline" /> : null}
      {can.close ? <StatusButton taskId={taskId} status="closed" label="Close the task" variant="outline" /> : null}
      {can.reopen ? (
        <StatusButton taskId={taskId} status="in_progress" label="Reopen" variant="outline" note={{ label: "Why is it being reopened?", required: true }} />
      ) : null}
      {can.takeOver ? <ReasonForm taskId={taskId} label="Take it over" reasonLabel="Reason" action={reassignTask} takeOver /> : null}
      {can.reassign ? <ReasonForm taskId={taskId} label="Reassign" reasonLabel="Reason" action={reassignTask} people={people} /> : null}
      {can.escalate ? (
        <ReasonForm taskId={taskId} label="Escalate" reasonLabel="Why does it need escalating?" action={escalateTask} variant="danger" />
      ) : null}
    </div>
  );
}

export function CommentForm({ taskId }: { taskId: string }) {
  const [state, action, pending] = useActionState(addComment, null);
  const [key, setKey] = useState(0);
  return (
    <form
      action={async (form) => {
        await action(form);
        setKey((k) => k + 1);
      }}
      className="flex flex-col gap-2"
    >
      <Result state={state} />
      <input type="hidden" name="task_id" value={taskId} />
      <label htmlFor="comment" className="sr-only">
        Add a comment
      </label>
      <textarea key={key} id="comment" name="body" required rows={3} placeholder="Add a comment or an update" className={`${inputClass} min-h-24 py-3`} />
      <Button className="self-start" disabled={pending}>
        {pending ? "Posting…" : "Post comment"}
      </Button>
    </form>
  );
}

export function AttachmentForm({ taskId }: { taskId: string }) {
  const [state, action, pending] = useActionState(addAttachment, null);
  const [ready, setReady] = useState(false);
  const [key, setKey] = useState(0);
  return (
    <form
      action={async (form) => {
        await action(form);
        setKey((k) => k + 1);
        setReady(false);
      }}
      className="flex flex-col gap-2"
    >
      <Result state={state} />
      <input type="hidden" name="task_id" value={taskId} />
      <Field label="Add a photo or document" htmlFor={`file-${taskId}`}>
        <FileUpload key={key} id={`file-${taskId}`} bucket="task-files" folder={taskId} name="file" onReady={setReady} />
      </Field>
      <Button variant="outline" className="self-start" disabled={pending || !ready}>
        {pending ? "Adding…" : "Add file"}
      </Button>
    </form>
  );
}
