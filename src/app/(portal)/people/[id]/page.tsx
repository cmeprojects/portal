// Staff Portal · © cmeproject. All rights reserved.
import {
  REQUEST_STATUS,
  TYPE_LABEL,
  refOf,
  type RequestStatus,
} from "@/lib/requests-shared";
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { loadPerson, profilesReady } from "@/lib/profiles";
import {
  STATUS_CLASS,
  STATUS_LABELS,
  formatDue,
  todayIn,
  type Status,
} from "@/lib/tasks";
import { getTimeZone } from "@/lib/settings";
import { onboardingOn } from "@/lib/feature-parts";
import { ProfileCard } from "@/components/profile-card";
import { ProfileForm } from "@/components/profile-form";
import { Card } from "@/components/ui";

export const metadata: Metadata = { title: "Profile" };

const PEOPLE_MANAGERS = ["manager", "staff_admin", "system_admin"];

// cmeprojects: one person's profile. Everyone sees the business card; the
// person and people who manage staff also see private details and can edit.
export default async function PersonPage({
  params,
}: PageProps<"/people/[id]">) {
  const { profile, features } = await requireSession();
  if (features.hr_profiles === false || !(await profilesReady())) notFound();
  const { id } = await params;
  if (!/^[0-9a-f-]{36}$/.test(id)) notFound();
  const person = await loadPerson(id);
  if (!person) notFound();
  const manager = PEOPLE_MANAGERS.includes(profile.role);
  const me = person.id === profile.id;
  const overseer = manager || profile.role === "team_leader";
  const supabase = await createClient();
  const today = todayIn(await getTimeZone());
  // Their open tasks (only what this person may see; the database decides).
  const { data: tasks } =
    overseer || me
      ? await supabase
          .from("tasks")
          .select("id, title, status, due_date")
          .eq("assigned_to", id)
          .not("status", "in", "(completed,closed)")
          .order("due_date", { ascending: true, nullsFirst: false })
          .limit(8)
      : { data: [] };
  // cmeprojects: their recent requests, for people who manage staff (after live update 56).
  const { data: reqs } =
    manager && features.hr_requests !== false
      ? await supabase
          .from("requests")
          .select("id, ref_number, type, subject, status")
          .eq("requester", id)
          .order("created_at", { ascending: false })
          .limit(6)
      : { data: null };
  return (
    <>
      <p className="text-sm">
        <Link href="/people" className="text-brand underline">
          ← Staff directory
        </Link>
      </p>
      <div className="grid grid-cols-[minmax(0,1fr)] gap-4 lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
        <div className="flex min-w-0 flex-col gap-4">
          <ProfileCard person={person} />
          {/* cmeprojects: editing opens with a button; your own profile is edited in My account. */}
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
          ) : manager ? (
            <details className="group rounded-xl border border-line bg-surface shadow-card">
              <summary className="flex min-h-11 cursor-pointer list-none items-center justify-between gap-3 px-5 py-3 font-semibold text-brand [&::-webkit-details-marker]:hidden">
                <span>Edit {person.name}&apos;s details</span>
                <span
                  aria-hidden="true"
                  className="text-muted transition group-open:rotate-180"
                >
                  ▾
                </span>
              </summary>
              <div className="border-t border-line p-5 sm:p-6">
                <ProfileForm person={person} employment={manager} />
              </div>
            </details>
          ) : null}
          {tasks?.length ? (
            <Card className="p-5">
              <h2 className="heading-sm mb-2">Open tasks</h2>
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
              {overseer ? (
                <Link
                  href={`/tasks?person=${id}#all`}
                  className="mt-2 inline-block text-sm font-semibold text-brand underline"
                >
                  All their tasks
                </Link>
              ) : null}
            </Card>
          ) : null}
        </div>
        <div className="flex flex-col gap-4">
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
          {manager && onboardingOn(features) ? (
            <Card className="p-5">
              <h2 className="heading-sm mb-1">Compliance</h2>
              <p className="mb-2 text-sm text-muted">
                Their onboarding, documents and trainings.
              </p>
              <Link
                href={`/compliance/people/${id}`}
                className="text-sm font-semibold text-brand underline"
              >
                Open their compliance
              </Link>
            </Card>
          ) : null}
        </div>
      </div>
    </>
  );
}
