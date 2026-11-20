// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { createContext, startTransition, useCallback, useContext, useEffect, useId, useMemo, useRef, useState, type ReactNode } from "react";
import Link from "next/link";
import { ArrowLeft, ArrowRight, Check, List, LogOut, Save, Undo2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useDirty } from "@/components/use-dirty";
import { ToastOnMount } from "@/components/toast";
import type { FormState } from "@/lib/form";

// cmeprojects (owner, 19 Nov 2026): one Save for a whole page. Every form on
// the page registers here and hides its own Save; the bar at the bottom saves
// everything that changed, in order. Leaving with changes asks first: save and
// leave, leave without saving, or stay.

type Entry = { dirty: boolean; label: string; save: () => Promise<boolean> };
type Registry = { set: (id: string, e: Entry | null) => void };
const Ctx = createContext<Registry | null>(null);

export type PageSaveConfig = {
  mode: "steps" | "tab";
  // Steps: Back goes to the step before (none on step 1). Exit (cancel) leaves the edit steps; list is the client list.
  back?: string;
  list?: string;
  next?: string;
  nextLabel?: string;
  cancel?: string;
};

export function PageSave({ config, children }: { config: PageSaveConfig | null; children: ReactNode }) {
  if (!config) return <>{children}</>;
  return <PageSaveOn config={config}>{children}</PageSaveOn>;
}

function PageSaveOn({ config, children }: { config: PageSaveConfig; children: ReactNode }) {
  const router = useRouter();
  const entries = useRef(new Map<string, Entry>());
  const [dirtyCount, setDirtyCount] = useState(0);
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(0);
  const [problem, setProblem] = useState("");
  const [leaving, setLeaving] = useState<string | null>(null);
  const skipGuard = useRef(false);
  const registry = useMemo<Registry>(
    () => ({
      set: (id, e) => {
        const before = entries.current.get(id);
        if (e) entries.current.set(id, e);
        else entries.current.delete(id);
        if (before?.dirty !== e?.dirty) setDirtyCount([...entries.current.values()].filter((x) => x.dirty).length);
      },
    }),
    [],
  );

  // Save every changed form, one after another. True when all saved.
  const saveAll = useCallback(async () => {
    const todo = [...entries.current.values()].filter((e) => e.dirty);
    if (!todo.length) return true;
    setBusy(true);
    setProblem("");
    const failed: string[] = [];
    for (const e of todo) if (!(await e.save())) failed.push(e.label);
    setBusy(false);
    if (failed.length) {
      setProblem(`Not saved: ${failed.join(", ")}. Check the message next to ${failed.length === 1 ? "it" : "each"}.`);
      return false;
    }
    setSaved((n) => n + 1);
    return true;
  }, []);

  const go = useCallback(
    (href: string) => {
      skipGuard.current = true;
      router.push(href);
      // The page can stay mounted (only the step changes): ask again after this move.
      window.setTimeout(() => {
        skipGuard.current = false;
      }, 1500);
    },
    [router],
  );

  // Leaving by a link with unsaved changes: ask first.
  useEffect(() => {
    const onClick = (ev: MouseEvent) => {
      if (skipGuard.current || ev.defaultPrevented || ev.button !== 0 || ev.metaKey || ev.ctrlKey || ev.shiftKey || ev.altKey) return;
      const a = ev.target instanceof Element ? ev.target.closest<HTMLAnchorElement>("a[href]") : null;
      if (!a || a.target === "_blank" || a.hasAttribute("download") || a.dataset.pageSave === "skip") return;
      const url = new URL(a.href, location.href);
      if (url.origin !== location.origin) return;
      if (url.pathname === location.pathname && url.search === location.search) return; // a jump within the page
      if (![...entries.current.values()].some((e) => e.dirty)) return;
      ev.preventDefault();
      ev.stopPropagation();
      setLeaving(url.pathname + url.search + url.hash);
    };
    document.addEventListener("click", onClick, true);
    return () => document.removeEventListener("click", onClick, true);
  }, []);

  const steps = config.mode === "steps";
  return (
    <Ctx.Provider value={registry}>
      {children}
      {saved ? <ToastOnMount key={saved} text="Saved." /> : null}
      {/* Client list and Exit as small floating icons, named on hover (owner, 20 Nov 2026). */}
      {steps && (config.list || config.cancel) ? (
        <div className="fixed right-4 bottom-24 z-30 flex flex-col items-end gap-2 md:right-8 print:hidden">
          {config.list ? <FloatIcon href={config.list} label="Back to client list" icon={<List aria-hidden="true" className="size-4" />} /> : null}
          {config.cancel ? <FloatIcon href={config.cancel} label="Exit to this client's page" icon={<LogOut aria-hidden="true" className="size-4" />} /> : null}
        </div>
      ) : null}
      {steps || dirtyCount || problem ? (
        <div className="sticky bottom-0 z-30 -mx-4 mt-2 border-t border-line bg-surface/95 px-4 py-3 shadow-[0_-4px_12px_rgb(0_0_0/0.06)] backdrop-blur md:-mx-8 md:px-8 print:hidden">
          <div className="flex flex-wrap items-center gap-2">
            <p className={`min-w-0 flex-1 text-sm ${problem ? "font-medium text-danger" : "text-muted"}`} role={problem ? "alert" : "status"}>
              {problem || (dirtyCount ? `${dirtyCount} unsaved change${dirtyCount === 1 ? "" : "s"}` : "No unsaved changes")}
            </p>
            {/* Back, next to the other buttons (owner, 20 Nov 2026): to the step before (none on step 1). */}
            {steps && config.back ? (
              <Link href={config.back} className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-4 py-2 text-sm font-semibold text-ink shadow-sm hover:bg-page">
                <ArrowLeft aria-hidden="true" className="size-4" /> Back
              </Link>
            ) : null}
            {steps ? (
              <>
                <button
                  type="button"
                  disabled={busy || !dirtyCount}
                  onClick={() => startTransition(() => void saveAll())}
                  className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-4 py-2 text-sm font-semibold text-ink shadow-sm hover:bg-page disabled:opacity-50"
                >
                  <Save aria-hidden="true" className="size-4" /> {busy ? "Saving…" : "Save for later"}
                </button>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() =>
                    startTransition(async () => {
                      if ((await saveAll()) && config.next) go(config.next);
                    })
                  }
                  className="inline-flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg shadow-sm hover:opacity-90 disabled:opacity-50"
                >
                  {busy ? "Saving…" : (config.nextLabel ?? "Save and continue")}
                  {config.nextLabel ? <Check aria-hidden="true" className="size-4" /> : <ArrowRight aria-hidden="true" className="size-4" />}
                </button>
              </>
            ) : (
              <button
                type="button"
                disabled={busy || !dirtyCount}
                onClick={() => startTransition(() => void saveAll())}
                className="inline-flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg shadow-sm hover:opacity-90 disabled:opacity-50"
              >
                <Save aria-hidden="true" className="size-4" /> {busy ? "Saving…" : "Save"}
              </button>
            )}
          </div>
        </div>
      ) : null}
      {leaving ? (
        <>
          <button type="button" aria-label="Stay on this page" onClick={() => setLeaving(null)} className="fixed inset-0 z-50 bg-black/30" />
          <div role="dialog" aria-modal="true" aria-label="Unsaved changes" className="fixed inset-x-4 top-[25vh] z-50 mx-auto flex max-w-md flex-col gap-3 rounded-xl bg-surface p-5 shadow-2xl">
            <h2 className="heading-sm">Save your changes?</h2>
            <p className="text-sm text-muted">
              You have {dirtyCount} unsaved change{dirtyCount === 1 ? "" : "s"} on this page.
            </p>
            <div className="flex flex-wrap justify-end gap-2">
              <button type="button" onClick={() => setLeaving(null)} className="inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-semibold text-muted hover:bg-page">
                <Undo2 aria-hidden="true" className="size-4" /> Stay
              </button>
              <button
                type="button"
                onClick={() => {
                  setLeaving(null);
                  go(leaving);
                }}
                className="inline-flex items-center gap-1.5 rounded-lg border border-field px-4 py-2 text-sm font-semibold text-ink hover:bg-page"
              >
                <LogOut aria-hidden="true" className="size-4" /> Leave without saving
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() =>
                  startTransition(async () => {
                    const to = leaving;
                    const ok = await saveAll();
                    setLeaving(null);
                    if (ok) go(to);
                  })
                }
                className="inline-flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg hover:opacity-90 disabled:opacity-50"
              >
                <Save aria-hidden="true" className="size-4" /> {busy ? "Saving…" : "Save and leave"}
              </button>
            </div>
          </div>
        </>
      ) : null}
    </Ctx.Provider>
  );
}

// Is this form inside a page with one Save? (Then it hides its own button.)
export function usePageSaveOn() {
  return useContext(Ctx) !== null;
}

// A form that can be saved by its own button, or by the page's Save.
// `act` is the form's server action. `beforeSave` can ask a question first
// (return false to stop). `onSaved` runs after a successful save.
export function useSavableForm(
  act: (prev: FormState, form: FormData) => Promise<FormState>,
  opts: { label: string; beforeSave?: (form: FormData) => Promise<boolean>; onSaved?: (state: FormState) => void } = { label: "This section" },
) {
  const registry = useContext(Ctx);
  const id = useId();
  const [state, setState] = useState<FormState>(null);
  const [pending, setPending] = useState(false);
  const { ref, dirty, markClean } = useDirty();
  const optsRef = useRef(opts);
  useEffect(() => {
    optsRef.current = opts;
  });

  const save = useCallback(async () => {
    const form = ref.current;
    if (!form) return true;
    const data = new FormData(form);
    const o = optsRef.current;
    if (o.beforeSave && !(await o.beforeSave(data))) return false;
    setPending(true);
    const result = await new Promise<FormState>((resolve) =>
      startTransition(async () => {
        try {
          resolve(await act(null, data));
        } catch {
          resolve({ error: "That didn't save. Please try again." });
        }
      }),
    );
    setPending(false);
    setState(result);
    if (result?.error) return false;
    markClean();
    o.onSaved?.(result);
    return true;
  }, [act, markClean, ref]);

  useEffect(() => {
    if (!registry) return;
    registry.set(id, { dirty, label: optsRef.current.label, save });
  }, [registry, id, dirty, save]);
  useEffect(() => () => registry?.set(id, null), [registry, id]);

  const onSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    void save();
  };
  return { state, pending, ref, dirty, onSubmit, pageSave: registry !== null };
}

// A round floating link with its name shown on hover or keyboard focus.
export function FloatIcon({ href, label, icon, onClick }: { href?: string; label: string; icon: ReactNode; onClick?: () => void }) {
  const cls = "peer inline-flex size-11 items-center justify-center rounded-full border border-line bg-surface text-muted shadow-lg hover:bg-page hover:text-ink";
  return (
    <span className="relative flex items-center">
      {href ? (
        <Link href={href} aria-label={label} title={label} className={cls}>
          {icon}
        </Link>
      ) : (
        <button type="button" onClick={onClick} aria-label={label} title={label} className={cls}>
          {icon}
        </button>
      )}
      <span role="tooltip" className="pointer-events-none absolute right-full mr-2 hidden rounded-md bg-ink px-2 py-1 text-xs font-semibold whitespace-nowrap text-white shadow peer-hover:block peer-focus-visible:block">
        {label}
      </span>
    </span>
  );
}
