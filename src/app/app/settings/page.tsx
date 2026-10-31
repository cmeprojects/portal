// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { AppSettingsScreen } from "../../cars-app/settings-screen";

export const metadata: Metadata = { title: "Settings" };

export default async function StaffAppSettings({ searchParams }: PageProps<"/app/settings">) {
  return <AppSettingsScreen base="/app" saved={(await searchParams).saved === "1"} />;
}
