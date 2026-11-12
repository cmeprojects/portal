// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ChevronRight } from "lucide-react";
import { PageHeader } from "@/components/ui";
import { ModuleIcon } from "@/components/module-icons";
import { MODULES } from "@/lib/modules";
import { getAllowedPages } from "@/lib/allowed-pages";

export const metadata: Metadata = { title: "Portal settings" };

// cmeprojects: Portal settings. One place for every settings and
// configuration section this person can open (the sections keep their own
// pages and checks). New sections are added to the module catalogue under
// "system.settings" and appear here for the people allowed to open them.
export default async function PortalSettingsPage() {
  const { allowed } = await getAllowedPages();
  const sections = MODULES.filter((m) => m.parent === "system.settings" && m.href && allowed.has(m.href));
  if (!sections.length) notFound();
  return (
    <>
      <PageHeader title="Portal settings" intro="Settings and configuration for the portal. Open a section to change it." />
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {sections.map((m) => (
          <Link
            key={m.id}
            href={m.href}
            className="group flex items-start gap-4 rounded-2xl border border-line bg-surface p-5 shadow-card transition hover:-translate-y-0.5 hover:border-brand/40 hover:shadow-lg motion-reduce:transform-none"
          >
            <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-brand-soft text-brand">
              <ModuleIcon name={m.icon} className="size-5" />
            </span>
            <span className="min-w-0 flex-1">
              <span className="flex items-center gap-1 font-semibold text-ink">
                {m.label}
                <ChevronRight aria-hidden="true" className="size-4 text-muted transition-transform group-hover:translate-x-0.5" />
              </span>
              {m.description ? <span className="mt-1 block text-sm text-muted">{m.description}</span> : null}
            </span>
          </Link>
        ))}
      </div>
    </>
  );
}
