// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { ManageCars } from "@/app/(portal)/cars/manage/manage-view";

export const metadata: Metadata = { title: "Manage cars" };

export default async function AppManageCarsPage({ searchParams }: PageProps<"/cars-app/manage">) {
  return <ManageCars base="/cars-app" tabParam={(await searchParams).tab} />;
}
