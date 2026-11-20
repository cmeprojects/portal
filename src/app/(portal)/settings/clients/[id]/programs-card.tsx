// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useActionState, useEffect, useState, useTransition } from "react";
import { ChevronDown, Layers, Pause, Play, Plus, Star, StopCircle, X } from "lucide-react";
import { Button, Notice, buttonClass, inputClass } from "@/components/ui";
import { DateInput } from "@/components/date-input";
import { IdInput } from "@/components/id-input";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { addEnrolment, endEnrolment, enrolmentOpenItems, makeMainEnrolment, pauseEnrolment, resumeEnrolment, shiftsInPause, type OpenItem } from "./actions";

export type Enrolment = {
  id: string;
  program: string;
  scheme: string;
  schemeLabel: string;
  status: "active" | "paused" | "ended";
  startsOn: string;
  pausedFrom: string | null;
  pausedUntil: string | null;
  pauseReason: string;
  endsOn: string | null;
  endReason: string;
  isMain: boolean;
};
export type AddableProgram = { id: string; name: string; scheme: string; schemeLabel: string };

const day = (v: string | null) => (v ? v.split("-").reverse().join("/") : "");
const today = () => new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" });
const lab = "flex flex-col gap-1 text-xs font-medium";

// cmeprojects (update 158): a client's programs. One row per program, with its
// status and dates; the main one decides "Funded by" and the page wording.
// Only people who can change the client see the actions; the database checks too.
export function ProgramsCard({ clientId, enrolments, addable, canEdit, hasNdis, hasMac }: { clientId: string; enrolments: Enrolment[]; addable: AddableProgram[]; canEdit: boolean; hasNdis: boolean; hasMac: boolean }) {
  const [dialog, setDialog] = useState<{ kind: "add" } | { kind: "pause" | "end"; e: Enrolment } | null>(null);
  const [showEnded, setShowEnded] = useState(false);
  const [busy, start] = useTransition();
  const open = enrolments.filter((e) => e.status !== "ended");
  const ended = enrolments.filter((e) => e.status === "ended");

  // Ask first (outside the transition, so the question can show), then save.
  const quick = async (e: Enrolment, what: "resume" | "main") => {
    const ok = await askConfirm(what === "resume" ? `Resume ${e.program}? New services and shifts can be added again.` : `Make ${e.program} the main program? "Funded by" and the page wording follow it.`, { action: what === "resume" ? "Resume" : "Make main" });
    if (!ok) return;
    start(async () => {
      const r = what === "resume" ? await resumeEnrolment(e.id) : await makeMainEnrolment(e.id);
      if (r?.error) toast(r.error, "error");
      else if (r?.message) toast(r.message);
    });
  };

  return (
    <section id="programs" className="shadow-card scroll-mt-28 rounded-xl border border-line bg-surface p-4">
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <Layers aria-hidden="true" className="size-5 text-brand" />
        <h2 className="heading-sm flex-1">Programs</h2>
        {canEdit && addable.length ? (
          <Button size="sm" variant="outline" icon={Plus} onClick={() => setDialog({ kind: "add" })}>
            Add program
          </Button>
        ) : null}
      </div>
      {open.length === 0 ? (
        <p className="rounded-lg bg-warn-soft px-3 py-2 text-sm font-semibold text-warn">No active program{canEdit && addable.length ? ". Add one to add services and roster shifts." : "."}</p>
      ) : (
        <ul className="divide-y divide-line rounded-lg border border-line">
          {open.map((e) => (
            <li key={e.id} className="flex flex-wrap items-center gap-x-3 gap-y-1 px-3 py-2.5 text-sm">
              <span className={`size-2.5 shrink-0 rounded-full ${e.status === "paused" ? "bg-warn" : "bg-good"}`} aria-hidden="true" />
              <span className="min-w-40 flex-1">
                <span className="font-semibold">{e.program}</span>
                {e.program !== e.schemeLabel ? <span className="text-muted"> · {e.schemeLabel}</span> : null}
                {e.isMain ? <span className="ml-2 rounded-full bg-brand-soft px-2 py-0.5 text-xs font-semibold text-brand">Main</span> : null}
                <span className="block text-xs text-muted">
                  {e.status === "paused"
                    ? `Paused from ${day(e.pausedFrom)}${e.pausedUntil ? ` until ${day(e.pausedUntil)}` : ""}${e.pauseReason ? ` · ${e.pauseReason}` : ""}`
                    : `Active since ${day(e.startsOn)}`}
                </span>
              </span>
              {canEdit ? (
                <span className="flex flex-wrap gap-1.5">
                  {!e.isMain ? (
                    <Button size="sm" variant="outline" icon={Star} disabled={busy} onClick={() => quick(e, "main")}>
                      Make main
                    </Button>
                  ) : null}
                  {e.status === "paused" ? (
                    <Button size="sm" variant="outline" icon={Play} disabled={busy} onClick={() => quick(e, "resume")}>
                      Resume
                    </Button>
                  ) : (
                    <Button size="sm" variant="outline" icon={Pause} onClick={() => setDialog({ kind: "pause", e })}>
                      Pause
                    </Button>
                  )}
                  <Button size="sm" variant="danger" icon={StopCircle} onClick={() => setDialog({ kind: "end", e })}>
                    End
                  </Button>
                </span>
              ) : null}
            </li>
          ))}
        </ul>
      )}
      {ended.length ? (
        <div className="mt-2">
          <button type="button" onClick={() => setShowEnded((s) => !s)} aria-expanded={showEnded} className="inline-flex items-center gap-1 text-xs font-semibold text-muted hover:text-ink">
            <ChevronDown aria-hidden="true" className={`size-3.5 transition-transform ${showEnded ? "rotate-180" : ""}`} /> Ended ({ended.length})
          </button>
          {showEnded ? (
            <ul className="mt-1 divide-y divide-line rounded-lg border border-line text-sm">
              {ended.map((e) => (
                <li key={e.id} className="px-3 py-2 text-muted">
                  <span className="font-semibold text-ink">{e.program}</span>
                  {e.program !== e.schemeLabel ? ` · ${e.schemeLabel}` : ""} · {day(e.startsOn)} to {day(e.endsOn)}
                  {e.endReason ? ` · ${e.endReason}` : ""}
                </li>
              ))}
            </ul>
          ) : null}
        </div>
      ) : null}

      {dialog ? (
        <Dialog title={dialog.kind === "add" ? "Add a program" : dialog.kind === "pause" ? `Pause ${dialog.e.program}` : `End ${dialog.e.program}`} onClose={() => setDialog(null)}>
          {dialog.kind === "add" ? (
            <AddForm clientId={clientId} addable={addable} hasNdis={hasNdis} hasMac={hasMac} onDone={() => setDialog(null)} />
          ) : dialog.kind === "pause" ? (
            <PauseForm e={dialog.e} onDone={() => setDialog(null)} />
          ) : (
            <EndForm e={dialog.e} onDone={() => setDialog(null)} />
          )}
        </Dialog>
      ) : null}
    </section>
  );
}

function Dialog({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", esc);
    return () => window.removeEventListener("keydown", esc);
  }, [onClose]);
  return (
    <>
      <button type="button" aria-label="Close" onClick={onClose} className="fixed inset-0 z-40 bg-black/30" />
      <div role="dialog" aria-modal="true" aria-label={title} className="fixed inset-x-4 top-[10vh] z-50 mx-auto flex max-h-[80vh] max-w-lg flex-col overflow-hidden rounded-xl bg-surface shadow-2xl">
        <div className="flex items-center gap-2 border-b border-line px-4 py-3">
          <h2 className="heading-sm flex-1">{title}</h2>
          <button type="button" onClick={onClose} aria-label="Close" className="rounded-md p-1 text-muted hover:bg-page hover:text-ink">
            <X aria-hidden="true" className="size-5" />
          </button>
        </div>
        <div className="thin-scroll overflow-y-auto p-4">{children}</div>
      </div>
    </>
  );
}

function useDone(state: { message?: string; error?: string } | null, onDone: () => void) {
  useEffect(() => {
    if (state?.message && !state.error) {
      toast(state.message);
      onDone();
    }
  }, [state, onDone]);
}

function AddForm({ clientId, addable, hasNdis, hasMac, onDone }: { clientId: string; addable: AddableProgram[]; hasNdis: boolean; hasMac: boolean; onDone: () => void }) {
  const [state, action, pending] = useActionState(addEnrolment, null);
  const [programId, setProgramId] = useState(addable[0]?.id ?? "");
  useDone(state, onDone);
  const scheme = addable.find((p) => p.id === programId)?.scheme ?? "";
  const schemes = [...new Set(addable.map((p) => p.schemeLabel))];
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="client_id" value={clientId} />
      <label className={lab}>
        Program
        <select name="program_id" value={programId} onChange={(e) => setProgramId(e.target.value)} className={inputClass} required>
          {schemes.map((s) => (
            <optgroup key={s} label={s}>
              {addable
                .filter((p) => p.schemeLabel === s)
                .map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
            </optgroup>
          ))}
        </select>
      </label>
      <label className={lab}>
        Start date
        <DateInput name="starts_on" defaultValue={today()} required />
      </label>
      {scheme === "ndis" && !hasNdis ? (
        <label className={lab}>
          NDIS number (needed before NDIS services can be rostered)
          <IdInput kind="ndis" name="ndis_number" placeholder="9 digits" />
        </label>
      ) : null}
      {["support_at_home", "chsp"].includes(scheme) && !hasMac ? (
        <label className={lab}>
          My Aged Care ID (needed before services can be rostered)
          <IdInput kind="mac" name="aged_care_id" placeholder="AC12345678" />
        </label>
      ) : null}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={onDone}>
          Cancel
        </Button>
        <Button disabled={pending}>{pending ? "Adding…" : "Add program"}</Button>
      </div>
    </form>
  );
}

function PauseForm({ e, onDone }: { e: Enrolment; onDone: () => void }) {
  const [state, action, pending] = useActionState(pauseEnrolment, null);
  const [from, setFrom] = useState(today());
  const [until, setUntil] = useState("");
  const [shifts, setShifts] = useState<{ count: number; first?: string } | null>(null);
  useDone(state, onDone);
  useEffect(() => {
    let live = true;
    void shiftsInPause(e.id, from, until).then((r) => live && setShifts(r));
    return () => {
      live = false;
    };
  }, [e.id, from, until]);
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={e.id} />
      <p className="text-sm text-muted">While paused, no new services or shifts can be added in the pause. Everything already recorded stays as it is.</p>
      <div className="grid gap-3 sm:grid-cols-2">
        <label className={lab}>
          Pause from
          <DateInput name="paused_from" value={from} onChange={(ev) => setFrom(ev.target.value)} min={e.startsOn} required />
        </label>
        <label className={lab}>
          Expected return (optional)
          <DateInput name="paused_until" value={until} onChange={(ev) => setUntil(ev.target.value)} min={from} />
        </label>
      </div>
      <label className={lab}>
        Reason (optional)
        <input name="pause_reason" maxLength={300} placeholder="For example: in hospital, on holiday" className={inputClass} />
      </label>
      {shifts?.count ? (
        <Notice tone="info">
          {shifts.count} shift{shifts.count === 1 ? " is" : "s are"} already rostered in this pause (from {shifts.first}). They stay as they are: cancel them on the{" "}
          <Link href="/roster" className="font-semibold underline">
            roster
          </Link>{" "}
          if they won&apos;t go ahead.
        </Notice>
      ) : null}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={onDone}>
          Cancel
        </Button>
        <Button disabled={pending}>{pending ? "Pausing…" : "Pause program"}</Button>
      </div>
    </form>
  );
}

function EndForm({ e, onDone }: { e: Enrolment; onDone: () => void }) {
  const [state, action, pending] = useActionState(endEnrolment, null);
  const [endsOn, setEndsOn] = useState(today() < e.startsOn ? e.startsOn : today());
  const [items, setItems] = useState<OpenItem[] | null>(null);
  useDone(state, onDone);
  useEffect(() => {
    let live = true;
    void enrolmentOpenItems(e.id, endsOn).then((r) => live && setItems(r.items));
    return () => {
      live = false;
    };
  }, [e.id, endsOn]);
  const blocking = (items ?? []).filter((i) => i.kind !== "review");
  const reviews = (items ?? []).filter((i) => i.kind === "review");
  return (
    <form action={action} className="flex flex-col gap-3">
      <input type="hidden" name="id" value={e.id} />
      <label className={lab}>
        End date
        <DateInput name="ends_on" value={endsOn} onChange={(ev) => setEndsOn(ev.target.value)} min={e.startsOn} required />
      </label>
      <label className={lab}>
        Why is it ending?
        <input name="end_reason" required maxLength={300} placeholder="For example: moved to Support at Home, plan ended" className={inputClass} />
      </label>
      {e.isMain ? <p className="text-xs text-muted">This is the main program. Another open program becomes main; with none, they show &ldquo;No active program&rdquo;.</p> : null}
      {items === null ? (
        <p className="text-sm text-muted">Checking what&apos;s still open…</p>
      ) : blocking.length ? (
        <div className="rounded-lg border border-warn/40 bg-warn-soft p-3 text-sm">
          <p className="font-semibold text-warn">Close or end these first:</p>
          <ul className="mt-1 list-disc pl-5">
            {blocking.map((i, n) => (
              <li key={n}>
                <Link href={i.href} className="underline">
                  {i.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {reviews.length ? (
        <div className="rounded-lg border border-line bg-page p-3 text-sm">
          <p className="font-semibold">Open reviews (they don&apos;t stop it ending):</p>
          <ul className="mt-1 list-disc pl-5">
            {reviews.map((i, n) => (
              <li key={n}>
                <Link href={i.href} className="underline">
                  {i.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={onDone}>
          Cancel
        </Button>
        {blocking.length ? null : (
          <button type="submit" disabled={pending || items === null} className={buttonClass("danger")}>
            {pending ? "Ending…" : "End program"}
          </button>
        )}
      </div>
    </form>
  );
}
