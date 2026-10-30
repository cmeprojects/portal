// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { UnlockScreen } from "../../cars-app/unlock/unlock-screen";

export const metadata: Metadata = { title: "Unlock" };

export default async function StaffAppUnlock({ searchParams }: PageProps<"/app/unlock">) {
  return <UnlockScreen base="/app" change={(await searchParams).change === "1"} />;
}
