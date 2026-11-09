// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { photoLinks, type PhotoOwner } from "@/lib/avatars";
import { Avatar } from "@/components/avatar";
import { Card, Notice } from "@/components/ui";
import { EVENT_LABEL, LEAVE_LABEL, REQUEST_STATUS, TYPE_LABEL, refOf, type RequestStatus } from "@/lib/requests-shared";
import { DAYS, SHIFTS } from "@/lib/profiles-shared";
import { CommentBox, RequestActions } from "./actions-panel";

export const metadata: Metadata = { title: "Request" };

const day = (d: string | null) => (d ? new Date(`${d}T00:00:00`).toLocaleDateString("en-AU", { weekday: "short", day: "numeric", month: "short", year: "numeric" }) : "");

// cmeprojects: one request: details, status, who's approving, actions,
// comments and the full history.
export default async function RequestPage({ params, searchParams }: PageProps<"/requests/[id]">) {
  const { profile, live } = await requireSession();
  if (live.hr_requests === false) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const supabase = await createClient();
  const { data: r } = await supabase.from("requests").select("*").eq("id", id).maybeSingle();
  if (!r) notFound();
  const status = r.status as RequestStatus;
  const [{ data: events }, { data: approvers }, { data: canAct }] = await Promise.all([
    supabase.from("request_events").select("id, actor, type, comment, created_at").eq("request_id", id).order("id"),
    supabase.rpc("request_approvers", { p_request: id }),
    supabase.rpc("can_act_on_request", { p_request: id }),
  ]);
  const ids = [...new Set([r.requester, r.swap_with, ...(events ?? []).map((e) => e.actor), ...((approvers ?? []) as string[])].filter(Boolean))] as string[];
  const { data: people } = await supabase.from("profiles").select("id, full_name, email, avatar_ref").in("id", ids);
  const nameOf = new Map((people ?? []).map((p) => [p.id as string, (p.full_name || p.email) as string]));
  const photos = await photoLinks((people ?? []) as PhotoOwner[]);
  const open = status === "pending" || status === "info_needed";
  const mine = r.requester === profile.id;
  const partner = r.swap_with === profile.id;
  const d = (r.details ?? {}) as Record<string, unknown>;

  const choices: { action: string; label: string; variant?: "primary" | "outline" | "danger"; needs?: string }[] = [];
  if (open && partner && r.partner_ok === null) {
    choices.push({ action: "partner_accept", label: "Accept the swap", variant: "primary" }, { action: "partner_decline", label: "Decline the swap", variant: "danger" });
  }
  if (open && canAct && !mine && (r.type !== "swap" || r.partner_ok === true)) {
    choices.push(
      { action: "approve", label: r.stage === 1 ? "Approve" : "Give final approval", variant: "primary" },
      { action: "info", label: "Ask for more information", needs: "What do you need to know?" },
      { action: "decline", label: "Decline", variant: "danger", needs: "Reason for declining" },
    );
  }
  if (open && mine) choices.push({ action: "withdraw", label: "Withdraw request" });

  const rows: [string, React.ReactNode][] = [];
  if (r.type === "leave") {
    rows.push(["Type of leave", LEAVE_LABEL[String(d.leave_type)] ?? "Leave"], ["Dates", r.end_date && r.end_date !== r.start_date ? `${day(r.start_date)} to ${day(r.end_date)}` : day(r.start_date)]);
    if (d.part_day) rows.push(["Part day", "Yes"]);
  } else if (r.type === "swap") {
    rows.push(["Shift", `${day(r.start_date)} · ${String(d.my_shift ?? "")}`], ["Swapping with", nameOf.get(r.swap_with) ?? ""], ["Colleague", r.partner_ok === null ? "Not answered yet" : r.partner_ok ? "Accepted" : "Declined"]);
  } else if (r.type === "shift") {
    rows.push(["Date", day(r.start_date)], ["Current shift", String(d.current_shift ?? "")], ["Requested", String(d.new_shift ?? "")]);
  } else if (r.type === "availability") {
    rows.push(["Starting from", day(r.start_date)]);
    const a = (d.availability ?? {}) as Record<string, string[]>;
    rows.push([
      "New availability",
      DAYS.map(([k, l]) => `${l}: ${(a[k] ?? []).map((s) => SHIFTS.find(([v]) => v === s)?.[1]).filter(Boolean).join(", ") || "—"}`).join(" · "),
    ]);
  } else if (r.type === "timesheet") {
    rows.push(["Date worked", day(String(d.date ?? ""))], ["What's wrong", String(d.wrong ?? "")], ["Correct times", String(d.correct ?? "")]);
  } else {
    rows.push(["Details", <span key="m" className="whitespace-pre-line">{String(d.message ?? "")}</span>]);
  }
  if (d.reason) rows.push(["Reason", String(d.reason)]);

  return (
    <>
      <p className="text-sm">
        <Link href={mine || partner ? "/requests" : "/people/requests"} className="text-brand underline">
          {mine || partner ? "← My requests" : "← Staff requests"}
        </Link>
      </p>
      {(await searchParams).sent ? <Notice tone="success">Request sent.</Notice> : null}
      <div className="flex flex-wrap items-start gap-3">
        <div className="min-w-0 flex-1">
          <p className="text-sm text-muted">
            {refOf(r.ref_number)} · {TYPE_LABEL[r.type] ?? r.type}
          </p>
          <h1 className="heading">{r.subject || TYPE_LABEL[r.type]}</h1>
        </div>
        <span className={`rounded-full px-3 py-1 text-sm font-semibold ${REQUEST_STATUS[status].cls}`}>{REQUEST_STATUS[status].label}</span>
      </div>
      <div className="grid gap-4 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
        <div className="flex flex-col gap-4">
          <Card className="p-5">
            <h2 className="heading-sm mb-3">Details</h2>
            <dl className="grid gap-x-4 gap-y-2 text-sm sm:grid-cols-[10rem_1fr]">
              <dt className="text-muted">Requested by</dt>
              <dd className="font-medium">{nameOf.get(r.requester)}</dd>
              <dt className="text-muted">Sent</dt>
              <dd>{new Date(r.created_at).toLocaleString("en-AU", { dateStyle: "medium", timeStyle: "short" })}</dd>
              {rows.map(([k, v]) => (
                <div key={k} className="contents">
                  <dt className="text-muted">{k}</dt>
                  <dd>{v}</dd>
                </div>
              ))}
            </dl>
          </Card>
          <Card className="p-5">
            <h2 className="heading-sm mb-3">History and comments</h2>
            <ol className="flex flex-col gap-4">
              {(events ?? []).map((e) => (
                <li key={e.id} className="flex gap-3">
                  <Avatar name={e.actor ? (nameOf.get(e.actor) ?? "") : "System"} src={e.actor ? photos[e.actor] : undefined} size={28} className="mt-0.5 bg-brand-soft text-brand" />
                  <div className="min-w-0">
                    <p className="text-sm">
                      {e.actor ? <strong>{nameOf.get(e.actor)} </strong> : null}
                      {EVENT_LABEL[e.type] ?? e.type}
                    </p>
                    {e.comment ? <p className={`mt-1 text-sm whitespace-pre-line ${e.type === "comment" ? "rounded-md bg-page px-3 py-2" : "text-muted"}`}>{e.comment}</p> : null}
                    <time dateTime={e.created_at} className="text-xs text-muted">
                      {new Date(e.created_at).toLocaleString("en-AU", { dateStyle: "medium", timeStyle: "short" })}
                    </time>
                  </div>
                </li>
              ))}
            </ol>
            <div className="mt-4 border-t border-line pt-4">
              <CommentBox requestId={id} />
            </div>
          </Card>
        </div>
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-3 p-5">
            <h2 className="heading-sm">What&apos;s next</h2>
            {open ? (
              <p className="text-sm text-muted">
                {r.type === "swap" && r.partner_ok === null
                  ? `Waiting for ${nameOf.get(r.swap_with) ?? "your colleague"} to accept the swap.`
                  : status === "info_needed"
                    ? "Waiting for more information from the person who sent it."
                    : `Waiting for ${r.stage === 2 ? "final approval" : "approval"} from ${((approvers ?? []) as string[]).map((a) => nameOf.get(a)).filter(Boolean).join(", ") || "a manager"}.`}
              </p>
            ) : (
              <p className="text-sm text-muted">This request is {REQUEST_STATUS[status].label.toLowerCase()}.</p>
            )}
            <RequestActions requestId={id} choices={choices} />
          </Card>
        </div>
      </div>
    </>
  );
}
