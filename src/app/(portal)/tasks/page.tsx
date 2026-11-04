// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole } from "@/lib/session";
import { DashboardView } from "../dashboard-view";

export const metadata: Metadata = { title: "Tasks" };

// cmeprojects: everyone's tasks, for the system admin (whose home is the
// platform dashboard). Everyone else has their tasks on their own home page.
export default async function TasksPage({ searchParams }: PageProps<"/tasks">) {
  await requireRole(["system_admin"]);
  return <DashboardView params={await searchParams} />;
}
