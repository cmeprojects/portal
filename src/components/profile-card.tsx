// Staff Portal · © cmeproject. All rights reserved.
import { Mail, Phone, MapPin, HeartPulse, Briefcase, CalendarDays } from "lucide-react";
import { Avatar } from "@/components/avatar";
import type { PersonCard } from "@/lib/profiles";
import { DAYS, EMPLOYMENT, SHIFTS } from "@/lib/profiles-shared";

// cmeprojects: a staff member's profile, laid out like a business profile:
// photo and name up top, contact and work details, skills, and (for the
// person and people who manage staff) private details and availability.
export function ProfileCard({ person }: { person: PersonCard }) {
  const d = person.directory;
  const p = person.private;
  return (
    <div className="shadow-card @container overflow-hidden rounded-xl border border-line bg-surface">
      <div className="h-20 bg-brand-dark" aria-hidden="true" />
      <div className="flex flex-col gap-5 px-5 pb-5 sm:px-6">
        <div className="-mt-11">
          <Avatar name={person.name} src={person.photo} size={88} className="bg-brand-soft text-brand ring-4 ring-surface" />
        </div>
        <div className="-mt-2 flex flex-wrap items-start gap-4">
          <div className="min-w-0 flex-1">
            <h2 className="heading">{person.name}</h2>
            <p className="text-sm text-muted">
              {d.preferred_name ? `Goes by ${d.preferred_name} · ` : ""}
              {person.jobTitle}
              {d.department ? ` · ${d.department}` : ""}
            </p>
          </div>
          {!person.active ? <span className="rounded-full bg-page px-3 py-1 text-xs font-semibold text-muted ring-1 ring-line">Deactivated</span> : null}
        </div>
        <dl className="grid gap-x-6 gap-y-3 text-sm @sm:grid-cols-2">
          <Item icon={Mail} label="Email">
            <a href={`mailto:${person.email}`} className="text-brand underline">
              {person.email}
            </a>
          </Item>
          <Item icon={Phone} label="Work phone">
            {d.work_phone ? (
              <a href={`tel:${d.work_phone.replace(/\s/g, "")}`} className="text-brand underline">
                {d.work_phone}
              </a>
            ) : (
              <span className="text-muted">Not added</span>
            )}
          </Item>
          <Item icon={Briefcase} label="Role and team">
            {person.roleLabel}
            {person.teams.length ? ` · ${person.teams.join(", ")}` : ""}
          </Item>
          {p ? (
            <Item icon={CalendarDays} label="Employment">
              {[EMPLOYMENT[p.employment_type] && p.employment_type ? EMPLOYMENT[p.employment_type] : "", p.start_date ? `since ${new Date(p.start_date).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" })}` : "", p.employee_id ? `ID ${p.employee_id}` : ""]
                .filter(Boolean)
                .join(" · ") || <span className="text-muted">Not added</span>}
            </Item>
          ) : null}
        </dl>
        <div>
          <p className="mb-1.5 text-xs font-semibold tracking-wide text-muted uppercase">Skills and qualifications</p>
          {d.skills.length ? (
            <ul className="flex flex-wrap gap-2">
              {d.skills.map((s) => (
                <li key={s} className="rounded-full bg-brand-soft px-3 py-1 text-xs font-semibold text-brand">
                  {s}
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted">None added yet.</p>
          )}
        </div>
        {p ? (
          <div className="grid gap-5 border-t border-line pt-4 @2xl:grid-cols-2">
            <dl className="flex flex-col gap-3 text-sm">
              <p className="text-xs font-semibold tracking-wide text-muted uppercase">Private details</p>
              <Item icon={MapPin} label="Address">
                {p.address || <span className="text-muted">Not added</span>}
              </Item>
              <Item icon={HeartPulse} label="Emergency contact">
                {p.emergency_name || p.emergency_phone ? `${p.emergency_name}${p.emergency_phone ? ` · ${p.emergency_phone}` : ""}` : <span className="text-muted">Not added</span>}
              </Item>
            </dl>
            <div>
              <p className="mb-2 text-xs font-semibold tracking-wide text-muted uppercase">Usual availability</p>
              <table className="w-full text-center text-xs">
                <thead>
                  <tr>
                    <th />
                    {DAYS.map(([k, label]) => (
                      <th key={k} scope="col" className="pb-1 font-medium text-muted">
                        {label}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {SHIFTS.map(([s, label]) => (
                    <tr key={s}>
                      <th scope="row" className="pr-2 text-left font-medium text-muted">
                        {label}
                      </th>
                      {DAYS.map(([d2]) => {
                        const on = (p.availability?.[d2] ?? []).includes(s);
                        return (
                          <td key={d2} className="p-0.5">
                            <span className={`block h-5 rounded ${on ? "bg-good" : "bg-page ring-1 ring-line"}`} title={`${label} ${d2}: ${on ? "available" : "not available"}`} />
                          </td>
                        );
                      })}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}

function Item({ icon: Icon, label, children }: { icon: typeof Mail; label: string; children: React.ReactNode }) {
  return (
    <div className="flex gap-3">
      <Icon aria-hidden="true" className="mt-0.5 size-4 shrink-0 text-muted" strokeWidth={1.75} />
      <div className="min-w-0">
        <dt className="text-xs text-muted">{label}</dt>
        <dd className="[overflow-wrap:anywhere]">{children}</dd>
      </div>
    </div>
  );
}
