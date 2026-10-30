// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { UnlockScreen } from "./unlock-screen";

export const metadata: Metadata = { title: "Unlock" };

export default async function UnlockPage({ searchParams }: PageProps<"/cars-app/unlock">) {
  return <UnlockScreen base="/cars-app" change={(await searchParams).change === "1"} />;
}
