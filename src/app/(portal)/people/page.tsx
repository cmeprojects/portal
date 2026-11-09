// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { loadPeople, profilesReady } from "@/lib/profiles";
import { PageHeader } from "@/components/ui";
import { Directory } from "./directory";

export const metadata: Metadata = { title: "Staff directory" };

// cmeprojects: everyone in the company, with their photo, role and how to reach them (HR Pack → Staff profiles).
export default async function DirectoryPage() {
  const { features } = await requireSession();
  if (features.hr_profiles === false || !(await profilesReady())) notFound();
  const people = (await loadPeople()).filter((p) => p.active && p.role !== "system_admin");
  return (
    <>
      <PageHeader title="Staff directory" intro="Find a colleague and how to reach them." />
      <Directory
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
    </>
  );
}
