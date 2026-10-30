// Staff Portal · © cmeproject. All rights reserved.
import { SectionTabs } from "@/components/section-tabs";
import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canUseCars, loadCarScreen } from "@/lib/cars";
import { getTimeZone } from "@/lib/settings";
import { CarsDesk } from "@/components/cars-desk";
import { PageHeader } from "@/components/ui";
import { LiveRefresh } from "@/components/live-refresh";

export const metadata: Metadata = { title: "Cars" };

// Company cars in the portal (the Cars app on phones shows the same screen).
export default async function CarsPage({ searchParams }: PageProps<"/cars">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features)) redirect("/");
  const [timeZone, data, params] = await Promise.all([getTimeZone(), loadCarScreen(profile.id), searchParams]);

  return (
    <>
      <SectionTabs section="cars" current="/cars" />
      <LiveRefresh tables={["cars"]} />
      <PageHeader
        title="Cars"
        intro="Pick a company car and press Start. Press Return when you bring it back. You're recorded as the driver, with the times."
      />
      <div className="w-full max-w-xl">
        <CarsDesk data={data} userId={profile.id} timeZone={timeZone} preselect={typeof params.car === "string" ? params.car : undefined} />
      </div>
    </>
  );
}
