// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { getNavAccess } from "@/lib/nav-access";
import { sectionTabs, type Section } from "@/components/nav";

// The row of tabs at the top of a section (Tasks, Cars, People, Reports,
// Settings). Only the tabs this person can open; nothing if there's just one.
export async function SectionTabs({ section, current }: { section: Section; current: string }) {
  const { profile, features } = await requireSession();
  const tabs = sectionTabs(section, profile.role, features, await getNavAccess(profile.role));
  if (tabs.length < 2) return null;
  return (
    <nav aria-label="Section" className="-mb-2 flex flex-wrap gap-1.5 print:hidden">
      {tabs.map((t) => {
        const active = t.href === current;
        return (
          <Link
            key={t.href}
            href={t.href}
            aria-current={active ? "page" : undefined}
            className={`flex min-h-10 items-center rounded-full border px-4 text-sm font-semibold md:min-h-9 ${
              active ? "border-brand bg-brand text-brand-fg" : "border-line bg-surface text-muted hover:border-muted hover:text-ink"
            }`}
          >
            {t.text}
          </Link>
        );
      })}
    </nav>
  );
}
