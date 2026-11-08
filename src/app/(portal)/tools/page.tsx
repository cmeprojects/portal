// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { getNavAccess } from "@/lib/nav-access";
import { canUseCars } from "@/lib/cars";
import { PageHeader } from "@/components/ui";

export const metadata: Metadata = { title: "Tools" };

// cmeprojects: managers' shortcut to the built features, Cars and the phone
// apps, so the menu stays short. Others see these in the menu directly.
export default async function ToolsPage() {
  const { profile, features } = await requireSession();
  const access = await getNavAccess(profile.role);
  if (!access.tools) redirect("/");
  const tiles = [
    ...(access.customFeatures ?? []).map((f) => ({ href: `/f/${f.slug}`, label: f.label, note: "Built feature" })),
    ...(canUseCars(profile.role, features) ? [{ href: "/cars", label: "Cars", note: "Book and return cars" }] : []),
    ...(access.appsLabel ? [{ href: "/apps", label: access.appsLabel, note: "Phone apps and QR stickers" }] : []),
  ];
  return (
    <>
      <PageHeader title="Tools" intro="Your built features, cars and phone apps in one place." />
      {tiles.length === 0 ? (
        <p className="shadow-card rounded-xl border border-line bg-surface px-4 py-3 text-sm text-muted">Nothing here yet. Features you build in the Feature builder appear here.</p>
      ) : (
        <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {tiles.map((t) => (
            <li key={t.href}>
              <Link href={t.href} className="flex min-h-20 flex-col justify-center shadow-card rounded-xl border border-line bg-surface px-5 py-4 hover:border-brand">
                <span className="font-semibold">{t.label}</span>
                <span className="text-sm text-muted">{t.note}</span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </>
  );
}
