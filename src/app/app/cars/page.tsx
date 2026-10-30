// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { hasPin } from "@/lib/car-pin";
import { canManageCars, canUseCars, getCarRules, loadCarScreen } from "@/lib/cars";
import { getStaffAppLook } from "@/lib/branding";
import { staffAppOn } from "@/lib/staff-app";
import { getTimeZone } from "@/lib/settings";
import { CarsDesk } from "@/components/cars-desk";
import { LiveRefresh } from "@/components/live-refresh";
import { AppNav } from "../../cars-app/app-nav";

export const metadata: Metadata = { title: "Cars" };

// Cars inside the Staff app (when the system admin put it there).
export default async function StaffAppCars({ searchParams }: PageProps<"/app/cars">) {
  const { profile, features } = await requireSession();
  const look = await getStaffAppLook();
  if (!staffAppOn(features) || !look.cars || !canUseCars(profile.role, features)) notFound();
  if (!(await hasPin(profile.id))) redirect("/app/unlock");
  const [rules, timeZone, data, params] = await Promise.all([getCarRules(), getTimeZone(), loadCarScreen(profile.id), searchParams]);
  return (
    <>
      <LiveRefresh tables={["cars"]} />
      <Link href="/app" className="-mb-1 self-start text-sm font-semibold text-brand">
        ‹ All
      </Link>
      <CarsDesk data={data} userId={profile.id} timeZone={timeZone} preselect={typeof params.car === "string" ? params.car : undefined} />
      <AppNav base="/app">
        {canManageCars(profile.role, rules) ? (
          <Link href="/cars-app/manage" className="font-semibold text-brand underline">
            Manage cars
          </Link>
        ) : null}
      </AppNav>
    </>
  );
}
