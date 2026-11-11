// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { CornerDownLeft, FileText, FolderKanban, LayoutGrid, Search, User } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import { STATUS_LABELS, type Status } from "@/lib/tasks";

// cmeprojects: search the portal from anywhere (Ctrl+K or the search box).
// Pages come from the person's own menu; tasks, registers and people are read
// as the signed-in person, so the database's rules decide what can be found.
type Hit = { kind: "page" | "task" | "register" | "person"; label: string; detail?: string; href: string };
const EVENT = "portal:search";
const ICON = { page: LayoutGrid, task: FileText, register: FolderKanban, person: User };
const GROUP = { page: "Pages", task: "Tasks", register: "Registers", person: "People" };

export function SearchButton({ variant }: { variant: "box" | "icon" | "top" }) {
  const open = () => window.dispatchEvent(new Event(EVENT));
  if (variant === "icon") {
    return (
      <button type="button" onClick={open} aria-label="Search" className="flex size-11 shrink-0 items-center justify-center rounded-md text-side-fg hover:bg-side-hover md:hidden">
        <Search aria-hidden="true" className="size-5" strokeWidth={1.8} />
      </button>
    );
  }
  // cmeprojects: the search box on the light top bar.
  if (variant === "top") {
    return (
      <button
        type="button"
        onClick={open}
        className="flex h-11 w-56 items-center gap-2 rounded-xl border border-line bg-surface px-3 text-sm text-muted shadow-sm transition-colors hover:border-muted lg:w-72"
      >
        <Search aria-hidden="true" className="size-4" strokeWidth={1.8} />
        <span className="flex-1 truncate text-left whitespace-nowrap">Search…</span>
        <kbd className="rounded border border-line px-1.5 text-[11px] font-medium">Ctrl K</kbd>
      </button>
    );
  }
  return (
    <button
      type="button"
      onClick={open}
      className="flex min-h-10 w-full items-center gap-2 rounded-lg bg-side-hover px-3 text-sm text-side-muted transition-colors hover:bg-side-active hover:text-side-fg"
    >
      <Search aria-hidden="true" className="size-4" strokeWidth={1.8} />
      <span className="flex-1 text-left">Search</span>
      <kbd className="hidden rounded border border-white/20 px-1.5 text-[11px] font-medium md:inline">Ctrl K</kbd>
    </button>
  );
}

export function CommandPalette({ pages, people, registers }: { pages: { label: string; href: string }[]; people: boolean; registers: boolean }) {
  const router = useRouter();
  const dialog = useRef<HTMLDialogElement>(null);
  const input = useRef<HTMLInputElement>(null);
  const [q, setQ] = useState("");
  const [found, setFound] = useState<Hit[]>([]);
  const [active, setActive] = useState(0);

  useEffect(() => {
    const show = () => {
      setQ("");
      setFound([]);
      setActive(0);
      dialog.current?.showModal();
      setTimeout(() => input.current?.focus(), 0);
    };
    const key = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        if (dialog.current?.open) dialog.current.close();
        else show();
      }
    };
    window.addEventListener(EVENT, show);
    window.addEventListener("keydown", key);
    return () => {
      window.removeEventListener(EVENT, show);
      window.removeEventListener("keydown", key);
    };
  }, []);

  // Tasks, registers and people, a moment after typing stops.
  useEffect(() => {
    const term = q.trim();
    if (term.length < 2) return;
    let stale = false;
    const t = setTimeout(async () => {
      const supabase = createClient();
      const like = `%${term.replace(/[\\%_]/g, "\\$&")}%`;
      const ref = term.match(/^([a-z]{2,6})-?0*(\d{1,6})$/i);
      const [tasks, regs, folks] = await Promise.all([
        ref
          ? supabase.from("tasks").select("id, title, ref_number, status, registries!inner(prefix)").eq("ref_number", Number(ref[2])).ilike("registries.prefix", ref[1]).limit(5)
          : supabase.from("tasks").select("id, title, ref_number, status, registries(prefix)").ilike("title", like).order("created_at", { ascending: false }).limit(6),
        registers ? supabase.from("registries").select("id, name").eq("active", true).ilike("name", like).limit(4) : Promise.resolve({ data: [] }),
        people ? supabase.from("profiles").select("id, full_name, email").eq("active", true).or(`full_name.ilike.${like},email.ilike.${like}`).limit(4) : Promise.resolve({ data: [] }),
      ]);
      if (stale) return;
      type TaskHit = { id: string; title: string; ref_number: number; status: Status; registries: { prefix: string } | { prefix: string }[] | null };
      const prefix = (r: TaskHit["registries"]) => (Array.isArray(r) ? r[0]?.prefix : r?.prefix) ?? "";
      setFound([
        ...((tasks.data ?? []) as TaskHit[]).map((t) => ({
          kind: "task" as const,
          label: t.title,
          detail: `${prefix(t.registries)}-${String(t.ref_number).padStart(4, "0")} · ${STATUS_LABELS[t.status] ?? ""}`,
          href: `/tasks/${t.id}`,
        })),
        ...((regs.data ?? []) as { id: string; name: string }[]).map((r) => ({ kind: "register" as const, label: r.name, href: `/registers/${r.id}` })),
        ...((folks.data ?? []) as { id: string; full_name: string; email: string }[]).map((p) => ({ kind: "person" as const, label: p.full_name || p.email, detail: p.email, href: "/settings/staff" })),
      ]);
      setActive(0);
    }, 200);
    return () => {
      stale = true;
      clearTimeout(t);
    };
  }, [q, people, registers]);

  const term = q.trim().toLowerCase();
  const hits: Hit[] = useMemo(() => {
    const pageHits = pages.filter((p) => !term || p.label.toLowerCase().includes(term)).slice(0, term ? 5 : 8).map((p) => ({ kind: "page" as const, label: p.label, href: p.href }));
    return [...pageHits, ...(term.length >= 2 ? found : [])];
  }, [pages, term, found]);

  const go = (h: Hit | undefined) => {
    if (!h) return;
    dialog.current?.close();
    router.push(h.href);
  };

  return (
    <dialog
      ref={dialog}
      aria-label="Search"
      className="mx-auto mt-[12vh] w-[min(36rem,calc(100vw-2rem))] rounded-xl border border-line bg-surface p-0 text-ink shadow-xl backdrop:bg-black/40"
      onClick={(e) => e.target === dialog.current && dialog.current?.close()}
    >
      <div className="flex items-center gap-3 border-b border-line px-4">
        <Search aria-hidden="true" className="size-5 text-muted" strokeWidth={1.8} />
        <input
          ref={input}
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "ArrowDown") {
              e.preventDefault();
              setActive((a) => Math.min(a + 1, hits.length - 1));
            } else if (e.key === "ArrowUp") {
              e.preventDefault();
              setActive((a) => Math.max(a - 1, 0));
            } else if (e.key === "Enter") {
              e.preventDefault();
              go(hits[active]);
            }
          }}
          placeholder="Search tasks, registers, people or pages"
          aria-label="Search"
          className="h-14 flex-1 bg-transparent text-base outline-none placeholder:text-muted focus-visible:outline-none"
        />
        <kbd className="rounded border border-line px-1.5 text-[11px] text-muted">Esc</kbd>
      </div>
      <ul role="listbox" aria-label="Results" className="max-h-[60vh] overflow-y-auto p-2">
        {hits.length === 0 ? <li className="px-3 py-6 text-center text-sm text-muted">{term.length < 2 ? "Type to search." : "Nothing found."}</li> : null}
        {hits.map((h, i) => {
          const Icon = ICON[h.kind];
          const heading = i === 0 || hits[i - 1].kind !== h.kind ? GROUP[h.kind] : null;
          return (
            <li key={`${h.kind}-${h.href}-${i}`} role="option" aria-selected={i === active}>
              {heading ? <p className="px-3 pt-2 pb-1 text-[11px] font-semibold tracking-wider text-muted uppercase">{heading}</p> : null}
              <button
                type="button"
                onMouseEnter={() => setActive(i)}
                onClick={() => go(h)}
                className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm ${i === active ? "bg-brand-soft text-ink" : "hover:bg-page"}`}
              >
                <Icon aria-hidden="true" className="size-4 shrink-0 text-muted" strokeWidth={1.75} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-medium">{h.label}</span>
                  {h.detail ? <span className="block truncate text-xs text-muted">{h.detail}</span> : null}
                </span>
                {i === active ? <CornerDownLeft aria-hidden="true" className="size-4 text-muted" /> : null}
              </button>
            </li>
          );
        })}
      </ul>
    </dialog>
  );
}
