// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { NavGroup } from "@/components/nav";

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
  const all = groups.flatMap((g) => g.items.map((i) => i.href));
  const current = all.filter((h) => isActive(path, h)).sort((a, b) => b.length - a.length)[0];

  return (
    <div className="border-side-edge bg-brand-dark max-md:border-b md:border-r print:hidden">
      <aside className="flex flex-col gap-4 px-4 py-4 text-side-fg md:sticky md:top-0 md:h-screen md:overflow-y-auto md:overscroll-contain md:py-6">
        <div className="flex items-center justify-between gap-2">
          {brandMark}
          <div className="-mr-2 flex shrink-0 items-center">
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
                      key={item.href}
                      href={item.href}
                      onClick={() => setOpen(false)}
                      aria-current={active ? "page" : undefined}
                      className={`flex min-h-11 items-center rounded-md px-3 text-sm font-medium md:min-h-9 ${
                        active ? "bg-side-active text-side-fg" : "text-side-muted hover:bg-side-hover hover:text-side-fg"
                      }`}
                    >
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
