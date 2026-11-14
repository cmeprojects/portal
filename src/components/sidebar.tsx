// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore, type KeyboardEvent, type ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronDown, ChevronRight, CircleHelp, Menu, PanelLeftClose, PanelLeftOpen, Star, X } from "lucide-react";
import type { NavCategory, NavNode } from "@/lib/nav-tree";
import { ModuleIcon } from "@/components/module-icons";

// cmeprojects: the menu, built from the module catalogue (src/lib/modules.ts).
// Categories and modules fold open and closed (remembered on this device), the
// whole menu can shrink to an icon rail with tooltips, pinned shortcuts sit at
// the top, and on phones it's a drawer. Arrow keys move between items.

const STORE_CLOSED = "portal.nav.closed";
const STORE_RAIL = "portal.nav.rail";
const listeners = new Set<() => void>();
function read(key: string): string {
  try {
    return window.localStorage.getItem(key) ?? "";
  } catch {
    return "";
  }
}
function write(key: string, value: string) {
  try {
    window.localStorage.setItem(key, value);
  } catch {
    // Storage blocked: the menu still works, it just won't remember.
  }
  listeners.forEach((l) => l());
}
const subscribe = (l: () => void) => {
  listeners.add(l);
  return () => listeners.delete(l);
};
const useStored = (key: string) => useSyncExternalStore(subscribe, () => read(key), () => "");

function isActive(path: string, href: string) {
  return href === "/" ? path === "/" : path === href || path.startsWith(`${href}/`);
}

export type Pin = { href: string; label: string };

export function Sidebar({
  tree,
  pins,
  brandMark,
  mobileActions,
  help,
  footer,
  collapseSections = false,
}: {
  tree: NavCategory[];
  pins: Pin[];
  brandMark: ReactNode;
  mobileActions: ReactNode;
  help?: string;
  footer?: ReactNode;
  // cmeprojects: the system admin's long menu starts with its sections closed
  // (except the one with this page) every time a page loads.
  collapseSections?: boolean;
}) {
  const path = usePathname();
  const [drawer, setDrawer] = useState(false);
  const rail = useStored(STORE_RAIL) === "1";
  const closedRaw = useStored(STORE_CLOSED);
  const closed = useMemo(() => new Set(closedRaw ? closedRaw.split(",") : []), [closedRaw]);
  // cmeprojects: sub-pages are all closed when a page loads, and only one
  // module's sub-pages show at a time (opening another closes the last one).
  const [openSub, setOpenSub] = useState<string | null>(null);
  const shown = useMemo(() => (openSub ? [openSub] : []), [openSub]);
  const toggleSubs = useCallback((id: string) => setOpenSub((o) => (o === id ? null : id)), []);
  const [openCats, setOpenCats] = useState<Set<string>>(() => new Set());
  const toggle = useCallback(
    (id: string) => {
      if (collapseSections) {
        setOpenCats((o) => {
          const next = new Set(o);
          if (next.has(id)) next.delete(id);
          else next.add(id);
          return next;
        });
        return;
      }
      const next = new Set(closed);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      write(STORE_CLOSED, [...next].join(","));
    },
    [closed, collapseSections],
  );

  // The longest matching address wins (so a page lights up only one item).
  const current = useMemo(() => {
    const all: { href: string; id: string; m: string }[] = [];
    const walk = (n: NavNode) => {
      for (const m of n.children.length ? [] : n.match) all.push({ href: n.href, id: n.id, m });
      n.children.forEach(walk);
      if (n.children.length) all.push({ href: n.href, id: n.id, m: n.href });
    };
    tree.forEach((c) => c.items.forEach(walk));
    pins.forEach((p) => all.push({ href: p.href, id: `pin:${p.href}`, m: p.href }));
    const best = all.filter((x) => isActive(path, x.m)).sort((a, b) => b.m.length - a.m.length)[0];
    return best?.id ?? "";
  }, [tree, pins, path]);

  useEffect(() => {
    if (!drawer) return;
    const close = (e: globalThis.KeyboardEvent) => e.key === "Escape" && setDrawer(false);
    document.addEventListener("keydown", close);
    return () => document.removeEventListener("keydown", close);
  }, [drawer]);

  // Up/down arrows move between menu items.
  const navRef = useRef<HTMLElement>(null);
  const onKey = (e: KeyboardEvent<HTMLElement>) => {
    if (e.key !== "ArrowDown" && e.key !== "ArrowUp") return;
    const items = [...(navRef.current?.querySelectorAll<HTMLElement>("a[data-nav], button[data-nav]") ?? [])].filter((el) => el.offsetParent !== null);
    const i = items.indexOf(document.activeElement as HTMLElement);
    const next = items[Math.max(0, Math.min(items.length - 1, i + (e.key === "ArrowDown" ? 1 : -1)))];
    if (next) {
      e.preventDefault();
      next.focus();
    }
  };

  const compact = rail && !drawer;
  const itemClass = (active: boolean, sub = false) =>
    `flex items-center gap-3 rounded-xl transition-colors outline-none focus-visible:ring-2 focus-visible:ring-white/60 ${compact ? "size-11 justify-center" : sub ? "min-h-9 px-3 text-[13px]" : "min-h-11 px-3 text-[14.5px] md:min-h-10"} ${
      active ? "bg-brand font-semibold text-brand-fg shadow-[0_6px_14px_rgba(47,111,228,0.35)]" : "text-side-muted hover:bg-side-hover hover:text-side-fg"
    }`;

  const Item = ({ n, sub = false }: { n: NavNode; sub?: boolean }) => {
    const hasKids = n.children.length > 0 && !compact;
    const open = hasKids && shown.includes(n.id);
    const childActive = n.children.some((k) => k.id === current);
    // The module itself is active when one of its pages is open and its sub-pages are hidden.
    const active = n.id === current || (childActive && !open);
    const link = (
      <Link
        href={n.href}
        data-nav
        onClick={() => setDrawer(false)}
        aria-current={active ? "page" : undefined}
        title={compact ? n.label : undefined}
        aria-label={compact ? n.label : undefined}
        className={`${itemClass(active, sub)} ${hasKids ? "flex-1 pr-1" : ""}`}
      >
        {sub ? null : <ModuleIcon name={n.icon} className="size-[19px] shrink-0" />}
        {compact ? null : <span className="truncate">{n.label}</span>}
      </Link>
    );
    if (!hasKids) return link;
    return (
      <div className="flex flex-col gap-0.5">
        <div className="flex items-center gap-1">
          {link}
          <button
            type="button"
            data-nav
            aria-expanded={open}
            onClick={() => toggleSubs(n.id)}
            aria-label={open ? `Hide ${n.label} sub-pages` : `Show ${n.label} sub-pages`}
            title={open ? "Hide sub-pages" : "Show sub-pages"}
            className="grid size-9 shrink-0 place-items-center rounded-lg text-side-muted hover:bg-side-hover hover:text-side-fg"
          >
            <ChevronRight aria-hidden="true" className={`size-4 transition-transform duration-200 motion-reduce:transition-none ${open ? "rotate-90" : ""}`} />
          </button>
        </div>
        {open ? (
          <div className="ml-[22px] flex flex-col gap-0.5 border-l border-side-edge pl-3">
            {n.children.map((k) => (
              <Item key={k.id} n={k} sub />
            ))}
          </div>
        ) : null}
      </div>
    );
  };

  const menu = (
    <nav ref={navRef} aria-label="Main" onKeyDown={onKey} className="flex flex-col gap-1">
      {pins.length ? (
        <div className="flex flex-col gap-0.5">
          {compact ? null : (
            <p className="flex items-center gap-1.5 px-3 pt-1 pb-1 text-[11px] font-semibold tracking-[0.12em] text-side-muted uppercase">
              <Star aria-hidden="true" className="size-3" /> Pinned
            </p>
          )}
          {pins.map((p) => (
            <Link
              key={p.href}
              href={p.href}
              data-nav
              onClick={() => setDrawer(false)}
              title={compact ? p.label : undefined}
              aria-label={compact ? p.label : undefined}
              aria-current={`pin:${p.href}` === current ? "page" : undefined}
              className={itemClass(`pin:${p.href}` === current)}
            >
              <Star aria-hidden="true" className="size-[17px] shrink-0" />
              {compact ? null : <span className="truncate">{p.label}</span>}
            </Link>
          ))}
        </div>
      ) : null}
      {tree.map((cat, i) => {
        const here = cat.items.some((n) => n.id === current || n.children.some((k) => k.id === current));
        const shut = collapseSections ? !openCats.has(`c:${cat.id}`) && !here : closed.has(`c:${cat.id}`) && !here;
        return (
          <div key={cat.id} className="flex flex-col gap-0.5">
            {compact ? (
              i > 0 || pins.length ? <div className="mx-2 my-1.5 h-px bg-side-edge" /> : null
            ) : cat.id === "workspace" && !pins.length ? null : (
              <button
                type="button"
                data-nav
                aria-expanded={!shut}
                onClick={() => toggle(`c:${cat.id}`)}
                className={`flex items-center justify-between rounded-md px-3 pt-3 pb-1 text-[11px] font-semibold tracking-[0.12em] text-side-muted uppercase hover:text-side-fg ${cat.id === "system" ? "mt-1 border-t border-side-edge pt-4" : ""}`}
              >
                {cat.label}
                <ChevronDown aria-hidden="true" className={`size-3.5 transition-transform duration-200 motion-reduce:transition-none ${shut ? "-rotate-90" : ""}`} />
              </button>
            )}
            {shut && !compact ? null : cat.items.map((n) => <Item key={n.id} n={n} />)}
          </div>
        );
      })}
    </nav>
  );

  const bottom = (
    <div className="mt-auto flex flex-col gap-2 pt-4">
      {help && !compact ? (
        <details className="group rounded-xl bg-side-hover text-side-fg">
          <summary className="flex cursor-pointer list-none items-center gap-3 px-3 py-3 [&::-webkit-details-marker]:hidden">
            <CircleHelp aria-hidden="true" className="size-5 shrink-0" />
            <span className="flex-1 text-sm">
              <span className="block font-semibold">Need help?</span>
              <span className="block text-xs text-side-muted">Contact the office</span>
            </span>
            <ChevronRight aria-hidden="true" className="size-4 shrink-0 opacity-70 transition-transform group-open:rotate-90" />
          </summary>
          <p className="px-3 pb-3 text-xs whitespace-pre-line text-side-muted">{help}</p>
        </details>
      ) : null}
      {compact ? null : footer}
    </div>
  );

  return (
    <>
      {/* Phones: a bar with the logo, actions and the menu button. */}
      <div className="sticky top-0 z-30 flex items-center gap-2 bg-brand-dark px-3 py-2 text-side-fg md:hidden print:hidden">
        <button type="button" onClick={() => setDrawer(true)} aria-label="Open menu" aria-expanded={drawer} className="grid size-11 place-items-center rounded-lg hover:bg-side-hover">
          <Menu aria-hidden="true" className="size-6" />
        </button>
        <div className="min-w-0 flex-1">{brandMark}</div>
        {mobileActions}
      </div>
      {/* cmeprojects: a tab on the menu's edge to shrink it to icons or bring it back. */}
      <button
        type="button"
        onClick={() => write(STORE_RAIL, rail ? "" : "1")}
        aria-label={rail ? "Show the full menu" : "Shrink the menu to icons"}
        title={rail ? "Show the full menu" : "Shrink the menu to icons"}
        className={`group fixed top-[78px] z-40 hidden h-9 w-6 items-center justify-center rounded-r-lg border border-l-0 border-line bg-surface text-muted shadow-[2px_2px_8px_rgba(15,29,46,0.12)] transition-[left,color,background-color] duration-200 hover:bg-brand hover:text-brand-fg motion-reduce:transition-none md:flex print:hidden ${
          rail ? "left-[76px]" : "left-[256px]"
        }`}
      >
        {rail ? <PanelLeftOpen aria-hidden="true" className="size-4" strokeWidth={1.75} /> : <PanelLeftClose aria-hidden="true" className="size-4" strokeWidth={1.75} />}
      </button>
      {drawer ? <div className="fixed inset-0 z-40 bg-black/40 md:hidden" onClick={() => setDrawer(false)} aria-hidden="true" /> : null}
      <aside
        className={`print:hidden ${drawer ? "fixed inset-y-0 left-0 z-50 flex w-[min(300px,85vw)] shadow-2xl" : "hidden"} flex-col gap-4 overflow-y-auto overscroll-contain bg-brand-dark px-3 py-4 text-side-fg md:sticky md:top-0 md:flex md:h-screen md:py-5 ${
          compact ? "md:w-[76px] md:items-center" : "md:w-[256px]"
        } transition-[width] duration-200 motion-reduce:transition-none`}
      >
        <div className={`flex items-center gap-2 ${compact ? "justify-center" : "justify-between px-1"}`}>
          {compact ? <div className="[&_span:not(:first-child)]:hidden">{brandMark}</div> : brandMark}
          {drawer ? (
            <button type="button" onClick={() => setDrawer(false)} aria-label="Close menu" className="grid size-10 place-items-center rounded-lg hover:bg-side-hover">
              <X aria-hidden="true" className="size-5" />
            </button>
          ) : null}
        </div>
        {menu}
        {bottom}
      </aside>
    </>
  );
}
