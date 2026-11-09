// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { Contact } from "lucide-react";
import { requireSession } from "@/lib/session";
import { loadPeople, profilesReady } from "@/lib/profiles";
import { EmptyState, PageHeader } from "@/components/ui";
import { Directory } from "./directory";
import { PersonPanel } from "./person-panel";

export const metadata: Metadata = { title: "Staff directory" };

// cmeprojects: the staff directory (HR Pack → Staff profiles). A searchable
// list; click a person to see their card, tasks and requests beside it,
// without leaving the page. On phones the person shows on its own, with a
// way back to the list.
export default async function DirectoryPage({ searchParams }: PageProps<"/people">) {
  const { profile, features } = await requireSession();
  if (features.hr_profiles === false || !(await profilesReady())) notFound();
  const people = (await loadPeople()).filter((p) => p.active && p.role !== "system_admin");
  const sp = await searchParams;
  const picked = typeof sp.p === "string" && /^[0-9a-f-]{36}$/.test(sp.p) ? sp.p : null;
  const panel = picked ? await PersonPanel({ id: picked, viewer: { id: profile.id, role: profile.role }, features }) : null;
  return (
    <>
      <PageHeader title="Staff directory" intro="Find a colleague and how to reach them." />
      <div className="grid grid-cols-[minmax(0,1fr)] items-start gap-4 lg:grid-cols-[20rem_minmax(0,1fr)]">
        <div className={`${panel ? "hidden lg:block" : ""} lg:sticky lg:top-4`}>
          <Directory
            selected={picked}
            people={people.map((p) => ({
              id: p.id,
              name: p.name,
              preferred: p.directory.preferred_name,
              jobTitle: p.jobTitle,
              department: p.directory.department,
              phone: p.directory.work_phone,
              photo: p.photo,
              teams: p.teams,
              skills: p.directory.skills,
            }))}
          />
        </div>
        <div className={`${panel ? "" : "hidden lg:block"} flex min-w-0 flex-col gap-3`}>
          {panel ? (
            <>
              <Link href="/people" scroll={false} className="text-sm text-brand underline lg:hidden">
                ← All staff
              </Link>
              {panel}
            </>
          ) : (
            <div className="shadow-card rounded-xl border border-line bg-surface">
              <EmptyState icon={Contact} title={picked ? "We can't find that person" : "Choose someone"} text="Pick a name from the list to see their details here." />
            </div>
          )}
        </div>
      </div>
    </>
  );
}
