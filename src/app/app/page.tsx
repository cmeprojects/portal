// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { hasPin } from "@/lib/car-pin";
import { getStaffAppTiles, staffAppOn } from "@/lib/staff-app";
import { getStaffAppLook } from "@/lib/branding";
import { AppSquare } from "@/components/app-glyph";
import { InstallHint } from "../cars-app/install-hint";
import { AppNav } from "../cars-app/app-nav";

// The Staff app's home: big app-style icons for what this person uses.
export default async function StaffAppHome() {
  const { profile, features } = await requireSession();
  if (!staffAppOn(features)) {
    return <p className="rounded-xl border border-line bg-surface p-4 text-sm">The staff app isn&apos;t switched on for your company.</p>;
  }
  if (!(await hasPin(profile.id))) redirect("/app/unlock");
  const [tiles, look] = await Promise.all([getStaffAppTiles(profile.id, profile.role, features), getStaffAppLook()]);
  const first = (profile.full_name || "").split(" ")[0];
  const hour = Number(new Intl.DateTimeFormat("en-AU", { hour: "numeric", hourCycle: "h23", timeZone: "Australia/Melbourne" }).format(new Date()));
  const greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";

  return (
    <>
      <InstallHint name={look.name} storageKey="staff-install-hint" />
      <h1 className="font-display text-2xl font-semibold">
        {greeting}
        {first ? `, ${first}` : ""}
      </h1>
      {tiles.length === 0 ? (
        <p className="rounded-xl border border-line bg-surface p-4 text-sm">Nothing here for you yet. When your company adds something you use, it appears here.</p>
      ) : (
        <ul className="grid grid-cols-3 gap-x-2 gap-y-6 py-2">
          {tiles.map((t) => (
            <li key={t.key}>
              <Link href={t.href} className="flex flex-col items-center gap-1.5 text-center active:scale-95">
                <AppSquare icon={t.icon} colour={t.colour} />
                <span className="text-sm leading-tight font-semibold">{t.label}</span>
                <span className="-mt-1 text-[11px] leading-tight text-muted">{t.note}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
      <AppNav base="/app" />
    </>
  );
}
