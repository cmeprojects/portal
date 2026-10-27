// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { MyTasksView } from "../my-tasks-view";

export const metadata: Metadata = { title: "My tasks" };

export default async function MyTasksPage({ searchParams }: PageProps<"/my-tasks">) {
  return <MyTasksView basePath="/my-tasks" params={await searchParams} />;
}
