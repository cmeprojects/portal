// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ChevronDown, ExternalLink } from "lucide-react";
import type { ReactNode } from "react";
import { PageHeader } from "@/components/ui";
import { ModuleIcon } from "@/components/module-icons";
import { MODULES } from "@/lib/modules";
import { getAllowedPages } from "@/lib/allowed-pages";
import { SystemSettings } from "../system/page";
import { ChangeLog } from "../system/audit/page";
import SlaPage from "./sla/page";
import RequestSettingsPage from "./requests/page";
import BuilderPage from "../system/builder/page";
import SystemHealthPage from "../system/health/page";

export const metadata: Metadata = { title: "Portal settings" };

// cmeprojects: Portal settings. One place for every settings and
// configuration section this person can open. Choosing a tile opens that
// section underneath (same page; each section keeps its own checks), and it
// can still be opened on its own page. New sections are added to the module
// catalogue under "system.settings" and appear here for the people allowed.
export default async function PortalSettingsPage({ searchParams }: PageProps<"/settings">) {
  const { allowed } = await getAllowedPages();
  const sections = MODULES.filter((m) => m.parent === "system.settings" && m.href && allowed.has(m.href));
  if (!sections.length) notFound();
  const params = await searchParams;
  const asked = typeof params.open === "string" ? params.open : "";
  const open = sections.find((m) => m.id === asked);
  const base = open ? `/settings?open=${encodeURIComponent(open.id)}` : "/settings";

  // The section shown underneath (the same code as its own page).
  const body = (id: string): ReactNode => {
    switch (id) {
      case "system.settings.general":
        return <SystemSettings searchParams={searchParams as never} base={base} />;
      case "system.audit":
        return <ChangeLog searchParams={searchParams as never} base={base} />;
      case "workflows.sla":
        return <SlaPage />;
      case "workflows.request_rules":
        return <RequestSettingsPage />;
      case "system.builder":
        return <BuilderPage />;
      case "system.health":
        return <SystemHealthPage />;
      default:
        return null;
    }
  };

  return (
    <>
      <PageHeader title="Portal settings" intro="Settings and configuration for the portal. Choose a section to open it below." />
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {sections.map((m) => {
          const here = open?.id === m.id;
          return (
            <Link
              key={m.id}
              href={here ? "/settings" : `/settings?open=${encodeURIComponent(m.id)}`}
              scroll={false}
              aria-current={here ? "page" : undefined}
              aria-expanded={here}
              className={`group flex items-start gap-4 rounded-2xl border bg-surface p-5 shadow-card transition hover:-translate-y-0.5 hover:shadow-lg motion-reduce:transform-none ${
                here ? "border-brand ring-2 ring-brand/30" : "border-line hover:border-brand/40"
              }`}
            >
              <span className={`grid size-11 shrink-0 place-items-center rounded-xl ${here ? "bg-brand text-brand-fg" : "bg-brand-soft text-brand"}`}>
                <ModuleIcon name={m.icon} className="size-5" />
              </span>
              <span className="min-w-0 flex-1">
                <span className="flex items-center gap-1 font-semibold text-ink">
                  {m.label}
                  <ChevronDown aria-hidden="true" className={`size-4 text-muted transition-transform ${here ? "rotate-180" : ""}`} />
                </span>
                {m.description ? <span className="mt-1 block text-sm text-muted">{m.description}</span> : null}
              </span>
            </Link>
          );
        })}
      </div>
      {open ? (
        <section id="section" aria-label={open.label} className="flex flex-col gap-5 border-t border-line pt-5">
          <p className="flex justify-end text-sm">
            <Link href={open.href} className="inline-flex items-center gap-1 font-semibold text-brand hover:underline">
              Open on its own page <ExternalLink aria-hidden="true" className="size-3.5" />
            </Link>
          </p>
          {body(open.id) ?? (
            <p className="text-sm text-muted">
              This section opens on its own page: <Link href={open.href} className="font-semibold text-brand underline">{open.label}</Link>.
            </p>
          )}
        </section>
      ) : null}
    </>
  );
}
