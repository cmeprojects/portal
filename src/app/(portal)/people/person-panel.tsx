// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import {
  REQUEST_STATUS,
  TYPE_LABEL,
  refOf,
  type RequestStatus,
} from "@/lib/requests-shared";
import { createClient } from "@/lib/supabase/server";
import { loadPerson } from "@/lib/profiles";
import {
  STATUS_CLASS,
  STATUS_LABELS,
  formatDue,
  todayIn,
  type Status,
} from "@/lib/tasks";
import { getTimeZone } from "@/lib/settings";
import { onboardingOn } from "@/lib/feature-parts";
import type { Role } from "@/lib/roles";
import { ProfileCard } from "@/components/profile-card";
import { EditProfileDialog } from "@/components/edit-profile-dialog";
import { SensitiveRecords } from "./sensitive-records";
import { Card } from "@/components/ui";

const PEOPLE_MANAGERS = ["manager", "staff_admin", "system_admin"];

// cmeprojects: one person at a glance: their business card, then their open
// tasks, requests and compliance beside it. People who manage staff edit in a
// pop-up; your own details are edited in My account. Returns null if not found.
export async function PersonPanel({
  id,
  viewer,
  features,
}: {
  id: string;
  viewer: { id: string; role: Role };
  features: Record<string, boolean>;
}) {
  const person = await loadPerson(id);
  if (!person) return null;
  const manager = PEOPLE_MANAGERS.includes(viewer.role);
  const me = person.id === viewer.id;
  const overseer = manager || viewer.role === "team_leader";
  const supabase = await createClient();
  const today = todayIn(await getTimeZone());
  // Their open tasks (only what the viewer may see; the database decides).
  // cmeprojects: editing someone's details needs a Staff details grant covering them.
  const [{ data: tasks }, { data: reqs }, { data: canEdit }] = await Promise.all([
    overseer || me
      ? supabase
          .from("tasks")
          .select("id, title, status, due_date")
          .eq("assigned_to", id)
          .not("status", "in", "(completed,closed)")
          .order("due_date", { ascending: true, nullsFirst: false })
          .limit(8)
      : Promise.resolve({ data: null }),
    manager && features.hr_requests !== false
      ? supabase
          .from("requests")
          .select("id, ref_number, type, subject, status")
          .eq("requester", id)
          .order("created_at", { ascending: false })
          .limit(6)
      : Promise.resolve({ data: null }),
    me ? Promise.resolve({ data: false }) : supabase.rpc("has_access", { p_area: "staff_details", p_person: id }),
  ]);
  return (
    <div className="grid grid-cols-[minmax(0,1fr)] gap-4 xl:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
      <div className="flex min-w-0 flex-col gap-3">
        <div className="flex flex-wrap items-center gap-3">
          {me ? (
            <p className="text-sm text-muted">
              This is you.{" "}
              <Link
                href="/account"
                className="font-semibold text-brand underline"
              >
                Edit your details in My account
              </Link>
            </p>
          ) : canEdit === true ? (
            <EditProfileDialog
              key={person.id}
              person={person}
              employment
            />
          ) : manager ? (
            <p className="text-sm text-muted">You don&apos;t have access to edit staff details. The system admin can give it to you.</p>
          ) : null}
          {manager && onboardingOn(features) ? (
            <Link
              href={`/compliance/people/${id}`}
              className="text-sm font-semibold text-brand underline"
            >
              Their compliance
            </Link>
          ) : null}
        </div>
        <ProfileCard person={person} />
      </div>
      <div className="flex min-w-0 flex-col gap-4">
        {tasks ? (
          <Card className="p-5">
            <h2 className="heading-sm mb-2">
              Open tasks
              {tasks.length
                ? ` · ${tasks.length}${tasks.length === 8 ? "+" : ""}`
                : ""}
            </h2>
            {tasks.length === 0 ? (
              <p className="text-sm text-muted">Nothing open.</p>
            ) : null}
            <ul className="flex flex-col divide-y divide-line text-sm">
              {tasks.map((t) => (
                <li key={t.id} className="py-2">
                  <Link
                    href={`/tasks/${t.id}`}
                    className="font-medium hover:text-brand"
                  >
                    {t.title}
                  </Link>
                  <span className="mt-1 flex flex-wrap items-center gap-2 text-xs">
                    <span
                      className={`rounded-full px-2 py-0.5 font-semibold ${STATUS_CLASS[t.status as Status]}`}
                    >
                      {STATUS_LABELS[t.status as Status]}
                    </span>
                    <span
                      className={
                        t.due_date && t.due_date < today
                          ? "font-semibold text-danger"
                          : "text-muted"
                      }
                    >
                      {formatDue(t.due_date, today, t.status as Status)}
                    </span>
                  </span>
                </li>
              ))}
            </ul>
            {overseer && tasks.length ? (
              <Link
                href={`/tasks?person=${id}#all`}
                className="mt-2 inline-block text-sm font-semibold text-brand underline"
              >
                All their tasks
              </Link>
            ) : null}
          </Card>
        ) : null}
        {/* cmeprojects Phase 3: only for people whose access covers them. */}
        <SensitiveRecords subject={id} viewer={viewer.id} />
        {reqs && reqs.length ? (
          <Card className="p-5">
            <h2 className="heading-sm mb-2">Requests</h2>
            <ul className="flex flex-col divide-y divide-line text-sm">
              {reqs.map((r) => (
                <li
                  key={r.id}
                  className="flex items-center justify-between gap-2 py-2"
                >
                  <Link
                    href={`/requests/${r.id}`}
                    className="min-w-0 truncate font-medium hover:text-brand"
                  >
                    {refOf(r.ref_number)} · {r.subject || TYPE_LABEL[r.type]}
                  </Link>
                  <span
                    className={`shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold ${REQUEST_STATUS[r.status as RequestStatus].cls}`}
                  >
                    {REQUEST_STATUS[r.status as RequestStatus].label}
                  </span>
                </li>
              ))}
            </ul>
          </Card>
        ) : null}
      </div>
    </div>
  );
}
