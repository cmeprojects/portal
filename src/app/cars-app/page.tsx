// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canManageCars, canUseCars, getCarRules, loadCarScreen } from "@/lib/cars";
import { hasPin } from "@/lib/car-pin";
import { getTimeZone } from "@/lib/settings";
import { CarsDesk } from "@/components/cars-desk";
import { InstallHint } from "./install-hint";
import { lockApp, signOutApp } from "./actions";

export default async function CarsAppHome({ searchParams }: PageProps<"/cars-app">) {
  const { profile, features } = await requireSession();
  if (!canUseCars(profile.role, features)) {
    return (
      <p className="rounded-xl border border-line bg-surface p-4 text-sm">
        {features.vehicles !== true ? "Cars aren't switched on yet." : "You can use the company cars once your onboarding is done and you have a role."}
      </p>
    );
  }
  // First time on this phone: choose a PIN.
  if (!(await hasPin(profile.id))) redirect("/cars-app/unlock");
  const [rules, timeZone, data, params] = await Promise.all([getCarRules(), getTimeZone(), loadCarScreen(profile.id), searchParams]);

  return (
    <>
      <InstallHint />
      <CarsDesk data={data} userId={profile.id} timeZone={timeZone} preselect={typeof params.car === "string" ? params.car : undefined} />
      <nav className="mt-4 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 border-t border-line pt-4 text-sm">
        {canManageCars(profile.role, rules) ? (
          <Link href="/cars-app/manage" className="font-semibold text-brand underline">
            Manage cars
          </Link>
        ) : null}
        <Link href="/cars-app/unlock?change=1" className="text-brand underline">
          Change PIN
        </Link>
        <form action={lockApp}>
          <button className="min-h-11 text-brand underline">Lock</button>
        </form>
        <form action={signOutApp}>
          <button className="min-h-11 text-muted underline">Sign out</button>
        </form>
      </nav>
    </>
  );
}
