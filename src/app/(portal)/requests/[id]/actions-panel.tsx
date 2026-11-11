// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { useRouter } from "next/navigation";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { useAfterSuccess } from "@/components/use-after-success";
import { actOnRequest } from "../actions";

type Choice = { action: string; label: string; variant?: "primary" | "outline" | "danger"; needs?: string };

// cmeprojects: a plain confirmation for each step, shown before it's saved.
const CONFIRM: Record<string, string> = {
  approve: "Approve this request? The person (and the next approver, if there is one) will be told.",
  decline: "Reject this request? The person will be told, with your reason.",
  info: "Send this request back for more information? It waits until they reply.",
  withdraw: "Cancel your request? Approvers will be told it's no longer needed.",
  partner_accept: "Accept this shift swap? It then goes for approval.",
  partner_decline: "Decline this shift swap? Your colleague will be told.",
};

// cmeprojects: what this person can do with the request, with a note where
// one is needed (declining, asking for more information).
export function RequestActions({ requestId, choices }: { requestId: string; choices: Choice[] }) {
  const router = useRouter();
  const [state, run, pending] = useActionState(actOnRequest, null);
  const [open, setOpen] = useState<Choice | null>(null);
  useAfterSuccess(state, () => {
    setOpen(null);
    router.refresh();
  });
  if (!choices.length) return null;
  return (
    <div className="flex flex-col gap-3">
      {open ? (
        <form action={run} className="flex flex-col gap-3 rounded-lg border border-line p-4">
          <input type="hidden" name="request_id" value={requestId} />
          <input type="hidden" name="action" value={open.action} />
          {CONFIRM[open.action] ? <p className="text-sm font-medium">{CONFIRM[open.action]}</p> : null}
          <Field label={open.needs ?? "Note (optional)"} htmlFor="rq-note">
            <textarea id="rq-note" name="comment" rows={3} required={Boolean(open.needs)} className={`${inputClass} h-auto py-3`} />
          </Field>
          {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
          <div className="flex flex-wrap gap-2">
            <Button variant={open.variant ?? "primary"} disabled={pending}>
              {pending ? "Saving…" : open.label}
            </Button>
            <Button type="button" variant="outline" onClick={() => setOpen(null)} disabled={pending}>
              Go back
            </Button>
          </div>
        </form>
      ) : (
        <div className="flex flex-wrap gap-2">
          {choices.map((c) => (
            <Button key={c.action} type="button" variant={c.variant ?? "outline"} onClick={() => setOpen(c)}>
              {c.label}
            </Button>
          ))}
        </div>
      )}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </div>
  );
}

export function CommentBox({ requestId }: { requestId: string }) {
  const router = useRouter();
  const [state, run, pending] = useActionState(actOnRequest, null);
  const [text, setText] = useState("");
  useAfterSuccess(state, () => {
    setText("");
    router.refresh();
  });
  return (
    <form action={run} className="flex flex-col gap-2">
      <input type="hidden" name="request_id" value={requestId} />
      <input type="hidden" name="action" value="comment" />
      <label htmlFor="rq-comment" className="sr-only">
        Add a comment
      </label>
      <textarea id="rq-comment" name="comment" rows={3} value={text} onChange={(e) => setText(e.target.value)} placeholder="Add a comment or reply" className={`${inputClass} h-auto py-3`} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending || !text.trim()}>
        {pending ? "Posting…" : "Post comment"}
      </Button>
    </form>
  );
}
