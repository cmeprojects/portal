// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useActionState, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { raiseQuestion, signOutWebsite } from "./actions";

type Person = { id: string; name: string; detail: string };

// cmeprojects: the side panel's footer for signed-in staff: who they are,
// the portal, Raise a question (a pop-up) and Sign out.
export function StaffFooter({ name, position, answerers }: { name: string; position: string; answerers: Person[] }) {
  const [open, setOpen] = useState(false);
  const link = "block rounded px-2 py-1.5 text-sm text-ink hover:bg-page";
  return (
    <div className="flex flex-col gap-1">
      <p className="px-2 text-sm font-semibold">{name}</p>
      {position ? <p className="px-2 text-xs text-muted">{position}</p> : null}
      <Link href="/" className={link}>
        Portal
      </Link>
      <button type="button" onClick={() => setOpen(true)} className={`${link} text-left`}>
        Raise a question
      </button>
      <form action={signOutWebsite} className="px-2 pt-1">
        <button className="inline-flex min-h-9 items-center rounded-md border border-line px-4 text-sm font-semibold hover:bg-page">Sign out</button>
      </form>
      {open ? <RaiseQuestionDialog answerers={answerers} onClose={() => setOpen(false)} /> : null}
    </div>
  );
}

function RaiseQuestionDialog({ answerers, onClose }: { answerers: Person[]; onClose: () => void }) {
  const [state, action, pending] = useActionState(raiseQuestion, null);
  return (
    <div role="dialog" aria-modal="true" aria-labelledby="rq-title" className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4" onClick={onClose}>
      <div className="w-full max-w-lg rounded-xl bg-surface p-5 shadow-xl" onClick={(e) => e.stopPropagation()}>
        <h2 id="rq-title" className="heading-sm mb-1">
          Raise a question
        </h2>
        <p className="mb-4 text-sm text-muted">It becomes a Staff question task. You&apos;ll see the answer in My tasks → My requests and questions.</p>
        {state?.message ? (
          <div className="flex flex-col gap-3">
            <Notice tone="success">{state.message}</Notice>
            <Button type="button" onClick={onClose} className="self-start">
              Done
            </Button>
          </div>
        ) : (
          <form action={action} className="flex flex-col gap-4">
            <Field label="Your question" htmlFor="rq-question">
              <input id="rq-question" name="title" required maxLength={160} className={inputClass} />
            </Field>
            <Field label="Details" htmlFor="rq-details" hint="Anything that helps them answer. Please leave out clients' health details.">
              <textarea id="rq-details" name="details" rows={4} maxLength={4000} className={`${inputClass} min-h-28 py-3`} />
            </Field>
            <Field label="Who should answer it?" htmlFor="rq-to">
              <select id="rq-to" name="to" required defaultValue="" className={inputClass}>
                <option value="" disabled>
                  Choose someone
                </option>
                {answerers.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} · {p.detail}
                  </option>
                ))}
              </select>
            </Field>
            {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
            <div className="flex gap-2">
              <Button disabled={pending}>{pending ? "Sending…" : "Send question"}</Button>
              <Button type="button" variant="outline" onClick={onClose}>
                Cancel
              </Button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
