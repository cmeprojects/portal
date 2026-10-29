// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import { isDone, type ItemState, type StatusRow } from "@/lib/compliance";
import { ROLE_LABELS, isRole, type Role } from "@/lib/roles";
import type { ChoiceColour } from "@/lib/registers";
import type { Cell, Table } from "@/lib/register-rows";

// Compliance report (cmeprojects): where everyone is up to with onboarding
// documents, trainings and uploads, chosen and filtered by the person reading it.

// Each person's saved view (Save as my default view).
export const DEFAULT_COOKIE = "compliance_report_view";

export type ComplianceView = "people" | "grid" | "expiry";
export type ComplianceShow = "all" | "unfinished" | "expired" | "expiring" | "check" | "sendback" | "done";

export type ComplianceFilter = {
  view: ComplianceView;
  show: ComplianceShow;
  role: Role | "";
  team: string;
  items: string[]; // none chosen = every item
  within: number; // expiry list: days ahead (0 = every date)
};

const VIEWS: ComplianceView[] = ["people", "grid", "expiry"];
const SHOWS: ComplianceShow[] = ["all", "unfinished", "expired", "expiring", "check", "sendback", "done"];

export const VIEW_LABELS: Record<ComplianceView, string> = { people: "Summary by person", grid: "Every item, every person", expiry: "Expiry dates" };
export const SHOW_LABELS: Record<ComplianceShow, string> = {
  all: "Everyone",
  unfinished: "Not finished",
  expired: "Something expired",
  expiring: "Something expiring soon",
  check: "Uploads waiting to be checked",
  sendback: "Sent back (upload again)",
  done: "All done",
};

export function parseComplianceFilter(params: Record<string, string | string[] | undefined>): ComplianceFilter {
  const one = (k: string) => (typeof params[k] === "string" ? (params[k] as string) : "");
  const list = (k: string) => (Array.isArray(params[k]) ? (params[k] as string[]) : one(k) ? [one(k)] : []);
  const view = one("view") as ComplianceView;
  const show = one("show") as ComplianceShow;
  const role = one("role");
  const within = Number(one("within"));
  return {
    view: VIEWS.includes(view) ? view : "people",
    show: SHOWS.includes(show) ? show : "all",
    role: isRole(role) ? role : "",
    team: /^[0-9a-f-]{36}$/.test(one("team")) ? one("team") : "",
    items: list("item").filter((i) => /^[0-9a-f-]{36}$/.test(i)),
    within: [30, 60, 90].includes(within) ? within : 0,
  };
}

// What a filter looks like as a link (for Excel and bookmarks).
export function filterQuery(f: ComplianceFilter): string {
  const q = new URLSearchParams({ view: f.view, show: f.show });
  if (f.role) q.set("role", f.role);
  if (f.team) q.set("team", f.team);
  if (f.within) q.set("within", String(f.within));
  f.items.forEach((i) => q.append("item", i));
  return q.toString();
}

const SHORT: Record<ItemState, string> = {
  todo: "To do",
  update: "Confirm again",
  done: "Done",
  submitted: "To check",
  accepted: "Checked",
  rejected: "Upload again",
  expiring: "Expiring",
  expired: "Expired",
};
const COLOUR: Record<ItemState, ChoiceColour> = {
  todo: "grey",
  update: "yellow",
  done: "green",
  submitted: "blue",
  accepted: "green",
  rejected: "orange",
  expiring: "yellow",
  expired: "red",
};

type Person = { id: string; name: string; role: Role; onboarded_at: string | null; teams: string[]; status: StatusRow[] };

export type ComplianceReport = {
  table: Table;
  totals: { people: number; finished: number; expired: number; expiring: number; check: number };
  items: { id: string; title: string; kind: string }[];
  teams: { id: string; name: string }[];
};

const date = (d: string | null) =>
  d ? new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(`${d}T00:00:00Z`)) : "";

export async function buildComplianceReport(f: ComplianceFilter, today: string): Promise<ComplianceReport> {
  const supabase = await createClient();
  const [{ data: profiles }, { data: members }, { data: teamRows }, { data: itemRows }] = await Promise.all([
    supabase.from("profiles").select("id, full_name, email, role, onboarded_at").eq("active", true).neq("role", "system_admin").order("full_name"),
    supabase.from("team_members").select("team_id, user_id"),
    supabase.from("teams").select("id, name").eq("active", true).eq("is_core", false).order("name"),
    supabase.from("compliance_items").select("id, title, kind, sort_order").eq("active", true).order("kind").order("sort_order").order("title"),
  ]);
  const teams = teamRows ?? [];
  const teamName = new Map(teams.map((t) => [t.id, t.name]));
  const items = (itemRows ?? []).map((i) => ({ id: i.id, title: i.title, kind: i.kind }));
  const chosen = f.items.length ? items.filter((i) => f.items.includes(i.id)) : items;
  const chosenIds = new Set(chosen.map((i) => i.id));

  const base = (profiles ?? [])
    .filter((p) => !f.role || p.role === f.role)
    .map((p) => ({
      id: p.id,
      name: p.full_name || p.email,
      role: p.role as Role,
      onboarded_at: p.onboarded_at as string | null,
      teams: (members ?? []).filter((m) => m.user_id === p.id).map((m) => m.team_id),
    }))
    .filter((p) => !f.team || p.teams.includes(f.team));
  const people: Person[] = await Promise.all(
    base.map(async (p) => {
      const { data } = await supabase.rpc("compliance_status", { p_user: p.id });
      return { ...p, status: ((data ?? []) as StatusRow[]).filter((s) => chosenIds.has(s.item_id)) };
    }),
  );

  const has = (p: Person, states: ItemState[]) => p.status.some((s) => states.includes(s.state));
  const finished = (p: Person) => p.status.every((s) => isDone(s.state));
  const matches = (p: Person) =>
    ({
      all: true,
      unfinished: !finished(p),
      expired: has(p, ["expired"]),
      expiring: has(p, ["expiring"]),
      check: has(p, ["submitted"]),
      sendback: has(p, ["rejected"]),
      done: finished(p),
    })[f.show];
  const shown = people.filter((p) => p.status.length && matches(p));
  const totals = {
    people: people.filter((p) => p.status.length).length,
    finished: people.filter((p) => p.status.length && finished(p)).length,
    expired: people.filter((p) => has(p, ["expired"])).length,
    expiring: people.filter((p) => has(p, ["expiring"])).length,
    check: people.filter((p) => has(p, ["submitted"])).length,
  };
  const teamsOf = (p: Person) => p.teams.map((t) => teamName.get(t)).filter(Boolean).join(", ");
  const count = (n: number, tone?: Cell["tone"]): Cell => ({ text: String(n), num: n, tone: n ? tone : "muted" });

  let table: Table;
  if (f.view === "grid") {
    table = {
      columns: [{ key: "name", label: "Person" }, { key: "role", label: "Role" }, ...chosen.map((i) => ({ key: i.id, label: i.title }))],
      rows: shown.map((p) => {
        const cells: Record<string, Cell> = { name: { text: p.name }, role: { text: ROLE_LABELS[p.role] } };
        for (const i of chosen) {
          const s = p.status.find((x) => x.item_id === i.id);
          cells[i.id] = s
            ? { text: s.expires_on && (s.state === "expiring" || s.state === "expired" || s.state === "accepted") ? `${SHORT[s.state]} · ${date(s.expires_on)}` : SHORT[s.state], badge: COLOUR[s.state] }
            : { text: "Not needed", tone: "muted" };
        }
        return { id: p.id, href: "", cells };
      }),
    };
  } else if (f.view === "expiry") {
    const until = f.within ? new Date(new Date(`${today}T00:00:00Z`).getTime() + f.within * 86_400_000).toISOString().slice(0, 10) : "9999-12-31";
    const rows = shown
      .flatMap((p) => p.status.filter((s) => s.expires_on && s.expires_on <= until).map((s) => ({ p, s })))
      .sort((a, b) => a.s.expires_on!.localeCompare(b.s.expires_on!));
    table = {
      columns: [
        { key: "name", label: "Person" },
        { key: "role", label: "Role" },
        { key: "item", label: "Document", wide: true },
        { key: "expires", label: "Expires" },
        { key: "days", label: "Days left" },
        { key: "state", label: "Status" },
      ],
      rows: rows.map(({ p, s }) => {
        const days = Math.round((new Date(`${s.expires_on}T00:00:00Z`).getTime() - new Date(`${today}T00:00:00Z`).getTime()) / 86_400_000);
        return {
          id: `${p.id}-${s.item_id}`,
          href: "",
          cells: {
            name: { text: p.name },
            role: { text: ROLE_LABELS[p.role] },
            item: { text: s.title },
            expires: { text: date(s.expires_on) },
            days: { text: days < 0 ? `${-days} days ago` : String(days), num: days, tone: days < 0 ? "danger" : undefined },
            state: { text: SHORT[s.state], badge: COLOUR[s.state] },
          },
        };
      }),
    };
  } else {
    table = {
      columns: [
        { key: "name", label: "Person" },
        { key: "role", label: "Role" },
        { key: "teams", label: "Teams" },
        { key: "done", label: "Done" },
        { key: "todo", label: "Still to do" },
        { key: "check", label: "To check" },
        { key: "expired", label: "Expired" },
        { key: "expiring", label: "Expiring" },
        { key: "onboarded", label: "Onboarding finished" },
      ],
      rows: shown.map((p) => {
        const done = p.status.filter((s) => isDone(s.state)).length;
        return {
          id: p.id,
          href: "",
          cells: {
            name: { text: p.name },
            role: { text: ROLE_LABELS[p.role] },
            teams: { text: teamsOf(p) },
            done: { text: `${done} of ${p.status.length}` },
            todo: count(p.status.length - done, "danger"),
            check: count(p.status.filter((s) => s.state === "submitted").length),
            expired: count(p.status.filter((s) => s.state === "expired").length, "danger"),
            expiring: count(p.status.filter((s) => s.state === "expiring").length),
            onboarded: { text: p.onboarded_at ? date(p.onboarded_at.slice(0, 10)) : "Not yet", tone: p.onboarded_at ? undefined : "muted" },
          },
        };
      }),
    };
  }
  return { table, totals, items, teams };
}
