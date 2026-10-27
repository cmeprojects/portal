// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireSession } from "@/lib/session";
import { seesDashboard } from "@/lib/dashboard";
import { DashboardView } from "./dashboard-view";
import { MyTasksView } from "./my-tasks-view";

export const metadata: Metadata = { title: "Home" };

// Home: the dashboard for people who oversee others, My tasks for everyone else.
export default async function HomePage({ searchParams }: PageProps<"/">) {
  const { profile } = await requireSession();
  const params = await searchParams;
  return seesDashboard(profile.role) ? <DashboardView params={params} /> : <MyTasksView basePath="/" params={params} />;
}
