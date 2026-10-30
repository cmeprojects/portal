// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState, useTransition, type ReactNode } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Badge, Button, Field, Notice, buttonClass, inputClass } from "@/components/ui";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { copyForm, createForm, deleteForm, formOutOfCompliance, formToCompliance, remindForm, sendForm, setFormOn, shareForm } from "./actions";

export type ManagedForm = {
  id: string;
  title: string;
  status: "draft" | "published";
  enabled: boolean;
  repeatable: boolean;
  anonymous: boolean;
  dueDate: string;
  dueIso: string;
  published: string;
  maker: string;
  // Made it (or the system admin): can share it.
  mine: boolean;
  sharedWith: { id: string; name: string }[];
  sentCount: number;
  doneOfSent: number;
  stillToDo: string[];
  replies: number;
  compliance: { roles: string[]; teams: string[] } | null;
  url: string;
  qrSvg: string;
};

type Option = { id: string; name: string };
const COMPLIANCE_ROLES: Role[] = ["new_starter", "support_worker", "team_leader", "staff_admin", "manager"];
const tick = "h-5 w-5 shrink-0 accent-[var(--brand-primary)]";

export function NewFormForm() {
  const [state, action, pending] = useActionState(createForm, null);
  return (
    <form action={action} className="flex flex-wrap items-end gap-3">
      <div className="min-w-56 flex-1">
        <Field label="Make a new form" htmlFor="nf-title">
          <input id="nf-title" name="title" required maxLength={120} placeholder="Name it, e.g. Staff survey, Policy sign-off" className={inputClass} />
        </Field>
      </div>
      <Button size="sm" className="mb-1.5" disabled={pending}>{pending ? "Making…" : "+ New form"}</Button>
      {state?.error ? <div className="w-full"><Notice tone="error">{state.error}</Notice></div> : null}
    </form>
  );
}

// cmeprojects: the forms you look after, stacked; tap one for a snapshot.
export function FormsList({ rows, open, people, sharers, teams }: { rows: ManagedForm[]; open: string; people: Option[]; sharers: Option[]; teams: Option[] }) {
  const [openId, setOpenId] = useState<string | null>(open || null);
  if (!rows.length) return <p className="rounded-lg border border-line bg-surface px-4 py-3 text-sm text-muted">No forms yet.</p>;
  return (
    <ul className="divide-y divide-line overflow-hidden rounded-lg border border-line bg-surface">
      {rows.map((f) => {
        const isOpen = openId === f.id;
        return (
          <li key={f.id} className={isOpen ? "bg-page" : ""}>
            <button
              type="button"
              aria-expanded={isOpen}
              onClick={() => setOpenId(isOpen ? null : f.id)}
              className="flex w-full flex-wrap items-center gap-x-3 gap-y-1 px-4 py-3 text-left hover:bg-page"
            >
              <span aria-hidden="true" className="w-3 text-muted">{isOpen ? "▾" : "▸"}</span>
              <span className="min-w-48 flex-1">
                <span className="block font-semibold">{f.title}</span>
                <span className="block text-xs text-muted">
                  {f.status === "draft" ? "Draft" : `Published ${f.published}`}
                  {f.sentCount ? ` · ${f.doneOfSent} of ${f.sentCount} done` : ""} · {f.replies} {f.replies === 1 ? "reply" : "replies"}
                  {f.mine ? "" : ` · made by ${f.maker}`}
                </span>
              </span>
              <span className="flex flex-wrap items-center gap-1.5">
                {f.status === "draft" ? <Badge tone="grey">Draft</Badge> : f.enabled ? <Badge tone="good">On</Badge> : <Badge tone="grey">Off</Badge>}
                {f.compliance ? <Badge tone="soft">In Compliance</Badge> : null}
                {f.anonymous ? <Badge tone="soft">Anonymous allowed</Badge> : null}
              </span>
            </button>
            {isOpen ? <Snapshot f={f} people={people} sharers={sharers} teams={teams} /> : null}
          </li>
        );
      })}
    </ul>
  );
}

function Snapshot({ f, people, sharers, teams }: { f: ManagedForm; people: Option[]; sharers: Option[]; teams: Option[] }) {
  const router = useRouter();
  const [panel, setPanel] = useState<"none" | "send" | "compliance" | "share" | "delete">("none");
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const [copied, setCopied] = useState(false);
  const run = (task: () => Promise<{ error?: string; message?: string }>, close = true) =>
    start(async () => {
      const r = await task();
      setResult(r);
      if (!r.error) {
        if (close) setPanel("none");
        router.refresh();
      }
    });
  const live = f.status === "published";

  return (
    <div className="flex flex-col gap-4 px-4 pb-4 sm:pl-10">
      {result?.error ? <Notice tone="error">{result.error}</Notice> : result?.message ? <Notice tone="success">{result.message}</Notice> : null}
      <div className="flex flex-wrap gap-5">
        <dl className="grid min-w-56 flex-1 grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
          <dt className="text-muted">Status</dt>
          <dd>{f.status === "draft" ? "Draft: not published yet" : f.enabled ? `Published ${f.published}, taking replies` : "Turned off"}</dd>
          <dt className="text-muted">Filled in</dt>
          <dd>{f.repeatable ? "As many times as needed" : "Once per person"}{f.anonymous ? " · people may answer anonymously" : ""}</dd>
          <dt className="text-muted">Replies</dt>
          <dd>{f.replies}</dd>
          {f.sentCount ? (
            <>
              <dt className="text-muted">Sent to</dt>
              <dd>
                {f.sentCount} {f.sentCount === 1 ? "person" : "people"}, {f.doneOfSent} done
                {f.stillToDo.length ? <span className="block text-xs text-muted">Still to do: {f.stillToDo.slice(0, 8).join(", ")}{f.stillToDo.length > 8 ? ` and ${f.stillToDo.length - 8} more` : ""}</span> : null}
              </dd>
            </>
          ) : null}
          {f.dueDate ? (
            <>
              <dt className="text-muted">Due</dt>
              <dd>{f.dueDate}</dd>
            </>
          ) : null}
          <dt className="text-muted">Compliance</dt>
          <dd>
            {f.compliance
              ? `In Compliance for ${[...f.compliance.roles.map((r) => ROLE_LABELS[r as Role] ?? r), ...f.compliance.teams.map((t) => teams.find((x) => x.id === t)?.name ?? "a team")].join(", ") || "everyone"}`
              : "Not in Compliance"}
          </dd>
          <dt className="text-muted">Shared with</dt>
          <dd>{f.sharedWith.length ? f.sharedWith.map((s) => s.name).join(", ") : "No one"} {f.mine ? "" : `(made by ${f.maker})`}</dd>
        </dl>
        {live ? (
          <div className="flex w-32 flex-col items-center gap-1 text-center">
            <div className="w-24 rounded-md border border-line bg-white p-1" dangerouslySetInnerHTML={{ __html: f.qrSvg }} />
            <button
              type="button"
              className="text-xs font-semibold text-brand underline"
              onClick={() =>
                navigator.clipboard.writeText(f.url).then(
                  () => setCopied(true),
                  () => setCopied(false),
                )
              }
            >
              {copied ? "Link copied" : "Copy link"}
            </button>
            <Link href={`/forms/${f.id}/qr?print=1`} className="text-xs font-semibold text-brand underline">
              Print QR code
            </Link>
          </div>
        ) : null}
      </div>

      {/* The main things to do, then the quieter ones as links. */}
      <div className="flex flex-col gap-2.5">
        <div className="flex flex-wrap gap-2">
          {live ? (
            <Link href={`/forms/${f.id}/replies`} className={buttonClass("primary", "", "sm")}>
              See replies
            </Link>
          ) : null}
          <Link href={`/forms/${f.id}/edit`} className={buttonClass(live ? "outline" : "primary", "", "sm")}>
            {live ? "Edit" : "Edit and publish"}
          </Link>
          {live && f.enabled ? (
            <>
              <Button type="button" size="sm" variant={panel === "send" ? "secondary" : "outline"} onClick={() => setPanel(panel === "send" ? "none" : "send")}>
                Send
              </Button>
              <Button type="button" size="sm" variant={panel === "compliance" ? "secondary" : "outline"} onClick={() => setPanel(panel === "compliance" ? "none" : "compliance")}>
                {f.compliance ? "Compliance" : "Add to Compliance"}
              </Button>
            </>
          ) : null}
        </div>
        <div className="flex flex-wrap items-center gap-x-1 text-[13px]">
          {live && f.enabled && f.stillToDo.length ? (
            <LinkButton disabled={pending} onClick={() => run(() => remindForm(f.id), false)}>
              Remind them
            </LinkButton>
          ) : null}
          {live ? (
            <LinkButton disabled={pending} onClick={() => run(() => setFormOn(f.id, !f.enabled), false)}>
              {f.enabled ? "Turn off" : "Turn on"}
            </LinkButton>
          ) : null}
          {f.mine ? <LinkButton onClick={() => setPanel(panel === "share" ? "none" : "share")}>Share</LinkButton> : null}
          <LinkButton disabled={pending} onClick={() => run(() => copyForm(f.id))}>
            Make a copy
          </LinkButton>
          <LinkButton danger onClick={() => setPanel(panel === "delete" ? "none" : "delete")}>
            Delete
          </LinkButton>
        </div>
      </div>

      {panel === "send" ? <SendPanel f={f} people={people} teams={teams} pending={pending} run={run} /> : null}
      {panel === "compliance" ? <CompliancePanel f={f} teams={teams} pending={pending} run={run} /> : null}
      {panel === "share" ? (
        <div className="flex flex-col gap-2 rounded-md border border-line bg-surface p-3 text-sm">
          <p className="font-semibold">Share with someone</p>
          <p className="text-xs text-muted">They can edit the form, send it and see the replies.</p>
          <ul className="flex flex-col gap-1">
            {sharers.map((p) => {
              const on = f.sharedWith.some((s) => s.id === p.id);
              return (
                <li key={p.id}>
                  <label className="flex min-h-9 items-center gap-2">
                    <input type="checkbox" checked={on} disabled={pending} onChange={(e) => run(() => shareForm(f.id, p.id, e.target.checked), false)} className={tick} />
                    {p.name}
                  </label>
                </li>
              );
            })}
            {sharers.length === 0 ? <li className="text-muted">No other managers or staff admins yet.</li> : null}
          </ul>
        </div>
      ) : null}
      {panel === "delete" ? (
        <div className="flex flex-wrap items-center gap-3 rounded-md border border-danger/40 bg-danger-soft/40 p-3 text-sm">
          <p className="mr-auto">
            Delete <strong>{f.title}</strong> and its {f.replies} {f.replies === 1 ? "reply" : "replies"}? This can&apos;t be undone. To stop replies but keep
            them, use Turn off instead.
          </p>
          <Button type="button" size="sm" variant="danger" disabled={pending} onClick={() => run(() => deleteForm(f.id))}>
            Yes, delete it
          </Button>
          <Button type="button" size="sm" variant="outline" onClick={() => setPanel("none")}>
            Cancel
          </Button>
        </div>
      ) : null}
    </div>
  );
}

// A small text action in the quieter row (Remind, Turn off, Share, Copy, Delete).
function LinkButton({ children, onClick, disabled, danger }: { children: ReactNode; onClick: () => void; disabled?: boolean; danger?: boolean }) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`min-h-8 rounded-md px-2 font-semibold underline-offset-2 hover:bg-surface hover:underline disabled:opacity-50 ${danger ? "text-danger" : "text-brand"}`}
    >
      {children}
    </button>
  );
}

function SendPanel({ f, people, teams, pending, run }: { f: ManagedForm; people: Option[]; teams: Option[]; pending: boolean; run: (t: () => Promise<{ error?: string; message?: string }>) => void }) {
  const [to, setTo] = useState<"people" | "team" | "everyone">("people");
  const [chosen, setChosen] = useState<string[]>([]);
  const [team, setTeam] = useState("");
  const [due, setDue] = useState(f.dueIso);
  const [find, setFind] = useState("");
  const shown = people.filter((p) => p.name.toLowerCase().includes(find.trim().toLowerCase()));
  return (
    <div className="flex flex-col gap-3 rounded-md border border-line bg-surface p-3 text-sm">
      <p className="font-semibold">Send {f.title}</p>
      <div className="flex flex-wrap gap-x-5 gap-y-1">
        {(
          [
            ["people", "Chosen people"],
            ["team", "A team"],
            ["everyone", "Everyone"],
          ] as const
        ).map(([k, label]) => (
          <label key={k} className="flex min-h-9 items-center gap-2">
            <input type="radio" name={`to-${f.id}`} checked={to === k} onChange={() => setTo(k)} className={tick} />
            {label}
          </label>
        ))}
      </div>
      {to === "people" ? (
        <div className="flex flex-col gap-2">
          <input aria-label="Find a person" placeholder="Find a person" value={find} onChange={(e) => setFind(e.target.value)} className={`${inputClass} h-10 max-w-sm`} />
          <div className="grid max-h-56 grid-cols-1 gap-x-4 overflow-y-auto sm:grid-cols-2 lg:grid-cols-3">
            {shown.map((p) => (
              <label key={p.id} className="flex min-h-9 items-center gap-2">
                <input type="checkbox" checked={chosen.includes(p.id)} onChange={(e) => setChosen((c) => (e.target.checked ? [...c, p.id] : c.filter((x) => x !== p.id)))} className={tick} />
                {p.name}
              </label>
            ))}
          </div>
        </div>
      ) : to === "team" ? (
        <select aria-label="Team" value={team} onChange={(e) => setTeam(e.target.value)} className={`${inputClass} max-w-sm`}>
          <option value="">Choose a team</option>
          {teams.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </select>
      ) : (
        <p className="text-muted">Everyone active in the portal.</p>
      )}
      <Field label="Due date (optional)" htmlFor={`due-${f.id}`}>
        <input id={`due-${f.id}`} type="date" value={due} onChange={(e) => setDue(e.target.value)} className={`${inputClass} max-w-56`} />
      </Field>
      <p className="text-xs text-muted">They get a bell note and an email with the link{due ? " and the due date" : ""}.</p>
      <Button
        type="button"
        size="sm"
        className="self-start"
        disabled={pending}
        onClick={() => run(() => sendForm(f.id, { users: to === "people" ? chosen : [], team: to === "team" ? team : "", everyone: to === "everyone", due }))}
      >
        {pending ? "Sending…" : "Send"}
      </Button>
    </div>
  );
}

function CompliancePanel({ f, teams, pending, run }: { f: ManagedForm; teams: Option[]; pending: boolean; run: (t: () => Promise<{ error?: string; message?: string }>) => void }) {
  const [roles, setRoles] = useState<string[]>(f.compliance?.roles ?? ["new_starter"]);
  const [inTeams, setInTeams] = useState<string[]>(f.compliance?.teams ?? []);
  return (
    <div className="flex flex-col gap-3 rounded-md border border-line bg-surface p-3 text-sm">
      <p className="font-semibold">{f.compliance ? "In Compliance" : "Put it in Compliance"}</p>
      <p className="text-xs text-muted">
        It shows in My onboarding for these people, and counts in the Compliance report until they&apos;ve filled it in. Tick none for everyone.
      </p>
      <fieldset className="flex flex-wrap gap-x-5">
        <legend className="mb-1 font-semibold">Roles</legend>
        {COMPLIANCE_ROLES.map((r) => (
          <label key={r} className="flex min-h-9 items-center gap-2">
            <input type="checkbox" checked={roles.includes(r)} onChange={(e) => setRoles((x) => (e.target.checked ? [...x, r] : x.filter((y) => y !== r)))} className={tick} />
            {ROLE_LABELS[r]}
          </label>
        ))}
      </fieldset>
      {teams.length ? (
        <fieldset className="flex flex-wrap gap-x-5">
          <legend className="mb-1 font-semibold">Teams</legend>
          {teams.map((t) => (
            <label key={t.id} className="flex min-h-9 items-center gap-2">
              <input type="checkbox" checked={inTeams.includes(t.id)} onChange={(e) => setInTeams((x) => (e.target.checked ? [...x, t.id] : x.filter((y) => y !== t.id)))} className={tick} />
              {t.name}
            </label>
          ))}
        </fieldset>
      ) : null}
      <div className="flex flex-wrap gap-2">
        <Button type="button" size="sm" disabled={pending} onClick={() => run(() => formToCompliance(f.id, roles, inTeams))}>
          {f.compliance ? "Save" : "Put in Compliance"}
        </Button>
        {f.compliance ? (
          <Button type="button" size="sm" variant="outline" disabled={pending} onClick={() => run(() => formOutOfCompliance(f.id))}>
            Take out of Compliance
          </Button>
        ) : null}
      </div>
    </div>
  );
}
