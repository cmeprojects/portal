// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { AppSettingsScreen } from "../settings-screen";

export const metadata: Metadata = { title: "Settings" };

export default async function CarsAppSettings({ searchParams }: PageProps<"/cars-app/settings">) {
  return <AppSettingsScreen base="/cars-app" saved={(await searchParams).saved === "1"} />;
}
