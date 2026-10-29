// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canManageCars, canSeeCarReports, canUseCars, getCarRules, loadCarScreen } from "@/lib/cars";
import { getTimeZone } from "@/lib/settings";
import { CarsDesk } from "@/components/cars-desk";
import { PageHeader } from "@/components/ui";

export const metadata: Metadata = { title: "Cars" };

// Company cars in the portal (the Cars app on phones shows the same screen).
export default async function CarsPage({ searchParams }: PageProps<"/cars">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features)) redirect("/");
  const [rules, timeZone, data, params] = await Promise.all([getCarRules(), getTimeZone(), loadCarScreen(profile.id), searchParams]);
  const manages = canManageCars(profile.role, rules);
  const reports = canSeeCarReports(profile.role, rules) && features.reports !== false;

  return (
    <>
      <PageHeader
        title="Cars"
        intro="Pick a company car and press Start. Press Return when you bring it back. You're recorded as the driver, with the times."
        action={
          <div className="flex flex-wrap gap-x-4 gap-y-1 text-sm font-semibold">
            {manages ? <Link href="/cars/manage" className="text-brand underline">Manage cars</Link> : null}
            {reports ? <Link href="/reports/cars" className="text-brand underline">Car reports</Link> : null}
            <Link href="/cars/install" className="text-brand underline">Get the app</Link>
          </div>
        }
      />
      <div className="w-full max-w-xl">
        <CarsDesk data={data} userId={profile.id} timeZone={timeZone} preselect={typeof params.car === "string" ? params.car : undefined} />
      </div>
    </>
  );
}
