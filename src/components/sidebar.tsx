// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { SearchButton } from "@/components/command-palette";
import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { NavGroup } from "@/components/nav";
import {
  BarChart3,
  Car,
  CircleUser,
  ClipboardCheck,
  Contact,
  ClipboardList,
  FileSignature,
  FolderKanban,
  GraduationCap,
  Inbox,
  LayoutDashboard,
  ListChecks,
  MessageCircle,
  Puzzle,
  Settings,
  Smartphone,
  Trophy,
  Users,
  type LucideIcon,
} from "lucide-react";

// cmeprojects: one line icon per menu item (built features and anything new get a puzzle piece).
const ICONS: Record<string, LucideIcon> = {
  Dashboard: LayoutDashboard,
  Home: LayoutDashboard,
  "My tasks": ListChecks,
  Tasks: ListChecks,
  Registers: FolderKanban,
  Forms: ClipboardList,
  "My forms": ClipboardList,
  "My contracts": FileSignature,
  Enquiries: Inbox,
  Assistant: MessageCircle,
  People: Users,
  Scoreboard: Trophy,
  Reports: BarChart3,
  Settings: Settings,
  Cars: Car,
  "My onboarding": GraduationCap,
  "My account": CircleUser,
  Directory: Contact,
  "My requests": ClipboardCheck,
  Requests: ClipboardCheck,
};
function iconFor(label: string, href: string): LucideIcon {
  return ICONS[label] ?? (href === "/apps" ? Smartphone : Puzzle);
}

function isActive(path: string, href: string) {
  return href === "/" ? path === "/" : path === href || path.startsWith(`${href}/`);
}

// Menu: a fixed column on wide screens (scrolls by itself on a short screen),
// a drop-down panel on phones.
export function Sidebar({
  groups,
  brandMark,
  bell,
  footer,
}: {
  groups: NavGroup[];
  brandMark: React.ReactNode;
  bell: React.ReactNode;
  footer: React.ReactNode;
}) {
  const path = usePathname();
  const [open, setOpen] = useState(false);
  // The longest matching address wins, so /registers/new highlights "Registers" only once.
  // A section's item also lights up on any of its tabs.
  const all = groups.flatMap((g) => g.items.flatMap((i) => (i.match ?? [i.href]).map((m) => ({ m, href: i.href }))));
  const current = all.filter((x) => isActive(path, x.m)).sort((a, b) => b.m.length - a.m.length)[0]?.href;

  return (
    <div className="border-side-edge bg-brand-dark max-md:border-b md:border-r print:hidden">
      <aside className="flex flex-col gap-4 px-4 py-4 text-side-fg md:sticky md:top-0 md:h-screen md:overflow-y-auto md:overscroll-contain md:py-6">
        <div className="flex items-center justify-between gap-2">
          {brandMark}
          <div className="-mr-2 flex shrink-0 items-center">
          <SearchButton variant="icon" />
          {bell}
          <button
            type="button"
            className="flex size-11 shrink-0 items-center justify-center rounded-md text-side-fg hover:bg-side-hover md:hidden"
            aria-expanded={open}
            aria-controls="main-menu"
            aria-label={open ? "Close menu" : "Open menu"}
            onClick={() => setOpen(!open)}
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true">
              {open ? <path d="M6 6l12 12M18 6L6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
            </svg>
          </button>
          </div>
        </div>

        <div id="main-menu" className={`${open ? "flex" : "hidden"} flex-1 flex-col gap-4 md:flex`}>
          <div className="max-md:hidden">
            <SearchButton variant="box" />
          </div>
          <nav aria-label="Main" className="flex flex-col gap-0.5">
            {groups.map((group, i) => (
              <div key={group.heading ?? i} className={`flex flex-col gap-0.5 ${i > 0 && !group.heading ? "mt-2 border-t border-side-active pt-2" : ""}`}>
                {group.heading ? (
                  <p className="px-3 pt-4 pb-1 text-[11px] font-medium tracking-[0.2em] text-side-muted uppercase">{group.heading}</p>
                ) : null}
                {group.items.map((item) => {
                  const active = item.href === current;
                  return (
                    <Link
                      key={item.label}
                      href={item.href}
                      onClick={() => setOpen(false)}
                      aria-current={active ? "page" : undefined}
                      className={`flex min-h-11 items-center gap-3 rounded-lg px-3 text-sm transition-colors md:min-h-9 ${
                        active ? "bg-side-active font-semibold text-side-fg" : "font-medium text-side-muted hover:bg-side-hover hover:text-side-fg"
                      }`}
                    >
                      {(() => {
                        const Icon = iconFor(item.label, item.href);
                        return <Icon aria-hidden="true" className="size-[18px] shrink-0 opacity-90" strokeWidth={1.75} />;
                      })()}
                      {item.label}
                    </Link>
                  );
                })}
              </div>
            ))}
          </nav>
          <div className="mt-auto border-t border-side-active pt-4">{footer}</div>
        </div>
      </aside>
    </div>
  );
}
