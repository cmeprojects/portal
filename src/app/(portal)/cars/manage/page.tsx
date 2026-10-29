// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { ManageCars } from "./manage-view";

export const metadata: Metadata = { title: "Manage cars" };

export default async function ManageCarsPage({ searchParams }: PageProps<"/cars/manage">) {
  return <ManageCars base="/cars" tabParam={(await searchParams).tab} />;
}
