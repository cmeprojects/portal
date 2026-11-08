// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { hasHomeDashboard, seesDashboard } from "@/lib/dashboard";
import { DashboardView } from "../dashboard-view";
import { MyTasksView } from "../my-tasks-view";

export const metadata: Metadata = { title: "Tasks" };

// cmeprojects: the task lists, for everyone whose home is a Dashboard. People
// who oversee tasks (system admin, managers, team leaders) see everyone's (or
// their team's); staff admins see their own. Support workers' tasks are on
// their home page.
export default async function TasksPage({ searchParams }: PageProps<"/tasks">) {
  const { profile } = await requireSession();
  if (!hasHomeDashboard(profile.role)) redirect("/");
  const params = await searchParams;
  return seesDashboard(profile.role) ? <DashboardView params={params} /> : <MyTasksView basePath="/tasks" params={params} />;
}
