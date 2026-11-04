// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, useTransition } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Button } from "@/components/ui";
import { deployDrafts, discardDrafts } from "@/app/(portal)/deploy-actions";

export type DraftLine = { key: string; text: string; when: string };

// Pages where settings are changed: leaving them with changes not live yet
// brings up the reminder.
const SETTINGS_PAGES = ["/system", "/assistant", "/settings/sla"];
const inSettings = (path: string) => SETTINGS_PAGES.some((p) => path === p || path.startsWith(`${p}/`));
const REMINDED = "portal-drafts-reminded";

// cmeprojects: saved settings aren't live until deployed. A yellow bar on
// every page while there are any, and a pop-up after signing in and when
// leaving Settings.
export function DeployBar({ items }: { items: DraftLine[] }) {
  const router = useRouter();
  const path = usePathname();
  const previous = useRef(path);
  const [open, setOpen] = useState(false);
  const [result, setResult] = useState<{ error?: string; message?: string } | null>(null);
  const [pending, start] = useTransition();
  const count = items.length;

  // Once per sign-in (per browser session), and when leaving Settings.
  useEffect(() => {
    let show = false;
    if (count) {
      try {
        if (!sessionStorage.getItem(REMINDED)) {
          sessionStorage.setItem(REMINDED, "1");
          show = true;
        }
      } catch {
        // Storage blocked: the yellow bar still shows.
      }
      if (inSettings(previous.current) && !inSettings(path)) show = true;
    }
    previous.current = path;
    if (!show) return;
    const t = setTimeout(() => setOpen(true), 0);
    return () => clearTimeout(t);
  }, [path, count]);

  const run = (action: typeof deployDrafts) =>
    start(async () => {
      const r = await action();
      setResult(r);
      if (!r.error) {
        setOpen(false);
        router.refresh();
      }
    });

  const words = `${count} change${count === 1 ? "" : "s"}`;
  return (
    <>
      {count ? (
        <div role="status" className="flex flex-wrap items-center gap-3 rounded-lg border border-warn/50 bg-warn-soft px-4 py-3 text-sm text-ink print:hidden">
          <span className="min-w-0 flex-1">
            <strong>{words} saved but not live yet.</strong> Staff won&apos;t see {count === 1 ? "it" : "them"} until you deploy.
          </span>
          <Button size="sm" onClick={() => setOpen(true)}>
            Review and deploy
          </Button>
        </div>
      ) : result?.message ? (
        <p role="status" className="text-sm font-semibold text-good print:hidden">
          ✓ {result.message}
        </p>
      ) : null}

      {open && count ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-4 sm:items-center print:hidden" onClick={() => setOpen(false)}>
          <div
            role="dialog"
            aria-modal="true"
            aria-labelledby="deploy-title"
            className="flex max-h-[85vh] w-full max-w-lg flex-col gap-4 overflow-y-auto rounded-xl border border-line bg-surface p-5 text-ink shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div>
              <h2 id="deploy-title" className="heading-sm">
                {words} not live yet
              </h2>
              <p className="text-sm text-muted">These are saved. Deploy makes them live for everyone, together.</p>
            </div>
            <ul className="flex flex-col divide-y divide-line rounded-md border border-line text-sm">
              {items.map((i) => (
                <li key={i.key} className="px-3 py-2">
                  {i.text}
                </li>
              ))}
            </ul>
            {result?.error ? <p className="text-sm font-semibold text-danger">{result.error}</p> : null}
            <div className="flex flex-wrap gap-2">
              <Button disabled={pending} onClick={() => run(deployDrafts)}>
                {pending ? "Working…" : `Deploy ${words}`}
              </Button>
              <Button
                variant="outline"
                disabled={pending}
                onClick={() => confirm(`Throw away ${words}? Nothing that's live changes.`) && run(discardDrafts)}
              >
                Discard
              </Button>
              <Button variant="outline" disabled={pending} onClick={() => setOpen(false)}>
                Later
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
