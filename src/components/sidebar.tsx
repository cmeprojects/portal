// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import type { NavGroup } from "@/components/nav";

function isActive(path: string, href: string) {
  return href === "/" ? path === "/" : path === href || path.startsWith(`${href}/`);
}

// Menu: a fixed column on wide screens, a slide-down panel on phones.
export function Sidebar({
  groups,
  brandMark,
  footer,
}: {
  groups: NavGroup[];
  brandMark: React.ReactNode;
  footer: React.ReactNode;
}) {
  const path = usePathname();
  const [open, setOpen] = useState(false);
  // Exact matches win over prefixes (so /system doesn't light up on /system/audit).
  const all = groups.flatMap((g) => g.items.map((i) => i.href));
  const current = all.filter((h) => isActive(path, h)).sort((a, b) => b.length - a.length)[0];

  return (
    <nav aria-label="Main" className="bg-brand-dark lg:sticky lg:top-0 lg:h-screen lg:w-64 lg:shrink-0 lg:overflow-y-auto">
      <div className="flex items-center justify-between gap-3 px-4 py-4 lg:px-5 lg:py-6">
        {brandMark}
        <button
          type="button"
          className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/10 text-white lg:hidden"
          aria-expanded={open}
          aria-controls="main-menu"
          aria-label={open ? "Close menu" : "Open menu"}
          onClick={() => setOpen(!open)}
        >
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
            {open ? <path d="M6 6l12 12M18 6L6 18" /> : <path d="M4 7h16M4 12h16M4 17h16" />}
          </svg>
        </button>
      </div>

      <div id="main-menu" className={`${open ? "flex" : "hidden"} flex-col gap-1 px-3 pb-5 lg:flex lg:px-4`}>
        {groups.map((group, i) => (
          <div key={group.heading ?? i} className="flex flex-col gap-1">
            {group.heading ? (
              <p className="px-3 pb-1 pt-4 text-xs font-bold uppercase tracking-wider text-white/70">{group.heading}</p>
            ) : null}
            {group.items.map((item) => {
              const active = item.href === current;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  aria-current={active ? "page" : undefined}
                  className={`flex min-h-11 items-center rounded-xl px-3.5 text-[15px] font-semibold ${
                    active ? "bg-brand text-white" : "text-white/85 hover:bg-white/10"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>
        ))}
        <div className="mt-6 border-t border-white/15 pt-4">{footer}</div>
      </div>
    </nav>
  );
}
