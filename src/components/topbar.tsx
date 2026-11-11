// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, useTransition, type ReactNode } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronDown, CircleUser, Landmark, LogOut, Star } from "lucide-react";
import { toast } from "@/components/toast";
import { togglePin } from "@/app/(portal)/pin-actions";
import { signOut } from "@/app/login/actions";

// cmeprojects: the top bar on wide screens (search, pin this page, bell, and
// your account menu). On phones these sit in the menu bar instead.

export function PinButton({ pinned, labels }: { pinned: string[]; labels: Record<string, string> }) {
  const path = usePathname();
  const [pending, start] = useTransition();
  const on = pinned.includes(path);
  return (
    <button
      type="button"
      disabled={pending}
      onClick={() =>
        start(async () => {
          const name = labels[path] || document.querySelector("main h1")?.textContent?.trim() || "Pinned page";
          const r = await togglePin(path, name);
          if (r.error) toast(r.error, "error");
          else toast(r.pinned ? `Pinned "${name}" to your menu.` : "Unpinned.");
        })
      }
      aria-pressed={on}
      aria-label={on ? "Unpin this page" : "Pin this page to your menu"}
      title={on ? "Unpin this page" : "Pin this page to your menu"}
      className="grid size-11 place-items-center rounded-xl border border-line bg-surface text-ink shadow-sm hover:border-muted disabled:opacity-60"
    >
      <Star aria-hidden="true" className={`size-[18px] ${on ? "fill-[#f5b301] text-[#f5b301]" : ""}`} />
    </button>
  );
}

export function UserMenu({ name, role, avatar, extra }: { name: string; role: string; avatar: ReactNode; extra?: ReactNode }) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent | KeyboardEvent) => {
      if (e instanceof KeyboardEvent ? e.key === "Escape" : !box.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", close);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", close);
    };
  }, [open]);
  return (
    <div ref={box} className="relative">
      <button type="button" aria-expanded={open} aria-haspopup="menu" onClick={() => setOpen(!open)} className="flex items-center gap-3 rounded-xl px-2 py-1 hover:bg-surface">
        {avatar}
        <span className="hidden text-left leading-tight lg:block">
          <span className="block max-w-48 truncate text-sm font-semibold text-ink">{name}</span>
          <span className="block max-w-48 truncate text-xs text-muted">{role}</span>
        </span>
        <ChevronDown aria-hidden="true" className={`size-4 text-muted transition-transform ${open ? "rotate-180" : ""}`} />
      </button>
      {open ? (
        <div role="menu" className="absolute top-full right-0 z-[60] mt-2 w-64 overflow-hidden rounded-xl border border-line bg-surface p-1.5 text-sm shadow-lg">
          <Link role="menuitem" href="/account" onClick={() => setOpen(false)} className="flex items-center gap-2.5 rounded-lg px-3 py-2.5 hover:bg-page">
            <CircleUser aria-hidden="true" className="size-4" /> My account
          </Link>
          <Link role="menuitem" href="/account/records" onClick={() => setOpen(false)} className="flex items-center gap-2.5 rounded-lg px-3 py-2.5 hover:bg-page">
            <Landmark aria-hidden="true" className="size-4" /> Pay and work rights
          </Link>
          {extra ? <div className="border-t border-line px-3 py-2.5">{extra}</div> : null}
          <form action={signOut} className="border-t border-line pt-1">
            <button role="menuitem" className="flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-left font-semibold text-danger hover:bg-danger-soft">
              <LogOut aria-hidden="true" className="size-4" /> Sign out
            </button>
          </form>
        </div>
      ) : null}
    </div>
  );
}
