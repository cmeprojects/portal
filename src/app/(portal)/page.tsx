// Staff Portal · © cmeproject. All rights reserved.
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { onboardingOn } from "@/lib/feature-parts";
import type { Metadata } from "next";
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { getPeopleRules } from "@/lib/settings";
import { getBranding } from "@/lib/branding";
import { Card, PageHeader } from "@/components/ui";
import { RoleDashboard, WorkerReminders, hasRoleDashboard } from "./role-dashboard";
import { PlatformDashboard } from "./platform-dashboard";
import { MyTasksView } from "./my-tasks-view";
import { Celebrations } from "@/components/celebrations";

export const metadata: Metadata = { title: "Home" };

// Home: a role dashboard for people who oversee others, My tasks for everyone else.
export default async function HomePage({ searchParams }: PageProps<"/">) {
  const { profile } = await requireSession();
  const params = await searchParams;
  if (profile.role === "new_starter" && !(await getPeopleRules()).newStarterTasks) return <Welcome name={profile.full_name} />;
  // cmeprojects: the system admin's home is the platform; external contractors have nothing yet.
  if (profile.role === "system_admin") {
    // A new, empty copy opens the setup wizard first (cmeprojects).
    const { data: setup } = await (await createClient()).from("app_settings").select("value").eq("key", "setup.completed").maybeSingle();
    if (setup && setup.value === false) redirect("/setup");
    return <PlatformDashboard name={profile.full_name} />;
  }
  if (profile.role === "external") {
    return (
      <>
        <PageHeader title={`Welcome${profile.full_name ? `, ${profile.full_name.split(" ")[0]}` : ""}`} />
        <Card className="max-w-2xl p-5 text-sm">Your account is ready. There&apos;s nothing here for you yet; we&apos;ll let you know when there is.</Card>
      </>
    );
  }
  // cmeprojects: managers, staff admins and team leaders get their role's
  // dashboard (their task lists are under Tasks); support workers get My tasks.
  if (hasRoleDashboard(profile.role)) return <RoleDashboard />;
  return (
    <>
      <WorkerReminders />
      <Celebrations me={profile.id} />
      <MyTasksView basePath="/" params={params} />
    </>
  );
}

// New starters' home until a staff admin gives them a role.
async function Welcome({ name }: { name: string }) {
  const brand = await getBranding();
  const { features } = await requireSession();
  return (
    <>
      <PageHeader
        title={`Welcome${name ? `, ${name.split(" ")[0]}` : ""}`}
        intro={`Your ${brand.companyName} staff portal account is ready.`}
      />
      <Card className="flex max-w-2xl flex-col gap-3 p-5">
        <h2 className="heading-sm">What happens next</h2>
        <p className="text-sm">
          A staff admin will set up your role and team. Once they have, your tasks will show here. You don&apos;t need to do anything
          for now.
        </p>
        {onboardingOn(features) ? (
          <p className="text-sm"><Link href="/onboarding" className="font-semibold text-brand underline">Go to My onboarding</Link> to read our policies, complete trainings and upload your documents.</p>
        ) : null}
      </Card>
    </>
  );
}
