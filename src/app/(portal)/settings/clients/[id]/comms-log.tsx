// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import { Mail, MessageSquare, Phone, Users, Video, FileText, MoreHorizontal, ArrowDownLeft, ArrowUpRight } from "lucide-react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addCommunication, setFollowUpDone } from "./actions";

export type CommEntry = {
  id: string;
  happened_at: string;
  method: string;
  direction: string;
  with_whom: string;
  summary: string;
  follow_up: string;
  follow_up_by: string | null;
  follow_up_done_at: string | null;
  author: string;
};
export const METHOD_WORDS: Record<string, string> = { phone: "Phone call", sms: "Text message", email: "Email", meeting: "Meeting", video: "Video call", letter: "Letter", other: "Other" };
const ICONS: Record<string, typeof Phone> = { phone: Phone, sms: MessageSquare, email: Mail, meeting: Users, video: Video, letter: FileText, other: MoreHorizontal };
const lab = "text-xs font-semibold text-ink";
const nowLocal = () => new Date().toLocaleString("sv-SE", { timeZone: "Australia/Sydney" }).slice(0, 16).replace(" ", "T");
const day = (d: string) => new Date(`${d}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });

// cmeprojects (update 147): add a call, text, email, meeting or letter to the client's log.
export function CommsLogForm({ clientId, onDone }: { clientId: string; onDone?: () => void }) {
  const [state, action, pending] = useActionState(async (prev: Awaited<ReturnType<typeof addCommunication>>, f: FormData) => {
    const r = await addCommunication(prev, f);
    if (r?.message) onDone?.();
    return r;
  }, null);
  const [follow, setFollow] = useState(false);
  return (
    <form action={action} className="flex flex-col gap-3" key={state?.message ?? "form"}>
      <input type="hidden" name="client_id" value={clientId} />
      <div className="grid gap-3 sm:grid-cols-3">
        <label className="flex flex-col gap-1">
          <span className={lab}>How</span>
          <select name="method" defaultValue="phone" className={inputClass}>
            {Object.entries(METHOD_WORDS).map(([k, l]) => (
              <option key={k} value={k}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>Which way</span>
          <select name="direction" defaultValue="out" className={inputClass}>
            <option value="out">We contacted them</option>
            <option value="in">They contacted us</option>
          </select>
        </label>
        <label className="flex flex-col gap-1">
          <span className={lab}>When</span>
          <input type="datetime-local" name="happened_at" defaultValue={nowLocal()} max={nowLocal()} className={inputClass} />
        </label>
      </div>
      <label className="flex flex-col gap-1">
        <span className={lab}>With</span>
        <input name="with_whom" maxLength={120} placeholder="e.g. Client, Mother (Jane), Support coordinator" className={inputClass} />
      </label>
      <label className="flex flex-col gap-1">
        <span className={lab}>Summary</span>
        <textarea name="summary" required maxLength={2000} rows={3} className={`${inputClass} h-auto py-2`} />
      </label>
      <label className="inline-flex items-center gap-2 text-sm">
        <input type="checkbox" checked={follow} onChange={(e) => setFollow(e.target.checked)} className="size-4" /> Needs a follow-up
      </label>
      {follow ? (
        <div className="grid gap-3 sm:grid-cols-[1fr_12rem]">
          <label className="flex flex-col gap-1">
            <span className={lab}>Follow-up</span>
            <input name="follow_up" maxLength={500} placeholder="e.g. Ask the roster team about mornings" className={inputClass} />
          </label>
          <label className="flex flex-col gap-1">
            <span className={lab}>By</span>
            <input type="date" name="follow_up_by" className={inputClass} />
          </label>
        </div>
      ) : null}
      <div className="flex items-center gap-2">
        <Button size="sm" disabled={pending}>
          {pending ? "Adding…" : "Add to the log"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}

export function CommsLogList({ clientId, entries, canWrite }: { clientId: string; entries: CommEntry[]; canWrite: boolean }) {
  const today = new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
  if (!entries.length) return <p className="text-sm text-muted">Nothing logged yet.</p>;
  return (
    <ul className="flex flex-col gap-2">
      {entries.map((e) => {
        const Icon = ICONS[e.method] ?? MoreHorizontal;
        const late = e.follow_up_by && !e.follow_up_done_at && e.follow_up_by < today;
        return (
          <li key={e.id} className="rounded-lg border border-line p-3 text-sm">
            <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
              <Icon aria-hidden="true" className="size-3.5 text-brand" />
              <span className="font-semibold text-ink">{METHOD_WORDS[e.method] ?? e.method}</span>
              {e.direction === "in" ? <ArrowDownLeft aria-label="They contacted us" className="size-3.5" /> : <ArrowUpRight aria-label="We contacted them" className="size-3.5" />}
              {e.with_whom ? <span>with {e.with_whom}</span> : null}
              <span>· {new Date(e.happened_at).toLocaleString("en-AU", { timeZone: "Australia/Sydney", day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" })}</span>
              <span>· {e.author}</span>
            </p>
            <p className="mt-1 whitespace-pre-wrap">{e.summary}</p>
            {e.follow_up || e.follow_up_by ? (
              <div className={`mt-2 flex flex-wrap items-center gap-2 rounded-md px-2 py-1 text-xs ${e.follow_up_done_at ? "bg-page text-muted line-through" : late ? "bg-danger-soft text-danger" : "bg-warn-soft"}`}>
                <span className="flex-1">
                  Follow-up{e.follow_up ? `: ${e.follow_up}` : ""}
                  {e.follow_up_by ? ` (by ${day(e.follow_up_by)}${late ? ", overdue" : ""})` : ""}
                </span>
                {canWrite ? (
                  <form action={setFollowUpDone}>
                    <input type="hidden" name="id" value={e.id} />
                    <input type="hidden" name="client_id" value={clientId} />
                    <input type="hidden" name="done" value={e.follow_up_done_at ? "0" : "1"} />
                    <button className="font-semibold underline">{e.follow_up_done_at ? "Not done" : "Mark done"}</button>
                  </form>
                ) : null}
              </div>
            ) : null}
          </li>
        );
      })}
    </ul>
  );
}
