// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getPeople, getRegistries } from "@/lib/register-data";
import { refLabel } from "@/lib/registers";
import { getTimeZone } from "@/lib/settings";
import { Bell, type BellItem } from "@/components/bell";
import { getBranding } from "@/lib/branding";
import { ROLE_LABELS } from "@/lib/roles";
import { BrandMark } from "@/components/brand-mark";
import { Sidebar } from "@/components/sidebar";
import { ThemeSwitch } from "@/components/theme-switch";
import { navFor } from "@/components/nav";
import { signOut } from "@/app/login/actions";

// Frame for every page after sign-in: the company's sidebar on desktop, a top
// bar with a drop-down menu on phones.
export default async function PortalLayout({ children }: LayoutProps<"/">) {
  const [{ profile, features }, brand] = await Promise.all([requireSession(), getBranding()]);
  const bellItems = await newTasksForMe();

  const footer = (
    <div className="flex flex-wrap items-center justify-between gap-3 md:flex-col md:items-start">
      <div className="min-w-0 text-sm">
        <p className="truncate font-medium text-side-fg">{profile.full_name || profile.email}</p>
        <p className="text-xs text-side-muted">{ROLE_LABELS[profile.role]}</p>
      </div>
      <form action={signOut}>
        <button className="min-h-9 text-xs text-side-muted underline hover:text-side-fg">Sign out</button>
      </form>
      <ThemeSwitch />
      <p className="text-[11px] text-side-muted">
        <Link href="/about" className="underline hover:text-side-fg">About</Link> · Built by cmeproject
      </p>
    </div>
  );

  return (
    <div className="min-h-screen md:grid md:grid-cols-[230px_minmax(0,1fr)] print:block">
      <Sidebar groups={navFor(profile.role, features)} brandMark={<BrandMark brand={brand} />}
        bell={features.tasks !== false ? <Bell items={bellItems} /> : null}
        footer={footer}
      />
      <main className="mx-auto flex w-full max-w-6xl min-w-0 flex-col gap-6 px-4 py-6 md:px-8 md:py-8 print:max-w-none print:gap-4 print:p-0">{children}</main>
    </div>
  );
}

// Tasks newly given to the signed-in person, newest first, for the bell.
async function newTasksForMe(): Promise<BellItem[]> {
  const supabase = await createClient();
  const { data } = await supabase.rpc("my_new_tasks");
  const fresh = (data ?? []) as { task_id: string; kind: "assigned" | "helping"; actor_id: string | null; at: string }[];
  if (!fresh.length) return [];
  const [{ data: tasks }, registries, people, timeZone] = await Promise.all([
    supabase.from("tasks").select("id, ref_number, title, registry_id").in("id", fresh.map((f) => f.task_id)),
    getRegistries(),
    getPeople(),
    getTimeZone(),
  ]);
  const when = new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  return fresh
    .sort((a, b) => (a.at < b.at ? 1 : -1))
    .flatMap((f) => {
      const t = (tasks ?? []).find((x) => x.id === f.task_id);
      if (!t) return [];
      const prefix = registries.find((r) => r.id === t.registry_id)?.prefix;
      return [
        {
          id: t.id,
          ref: refLabel(prefix, t.ref_number),
          title: t.title,
          kind: f.kind,
          by: people.find((p) => p.id === f.actor_id)?.name ?? "someone",
          when: when.format(new Date(f.at)),
        },
      ];
    });
}
