// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { requireSession } from "@/lib/session";
import { getNavAccess } from "@/lib/nav-access";
import { sectionTabs, type Section } from "@/components/nav";
import {
  Activity,
  BarChart3,
  Car,
  ClipboardCheck,
  Clock,
  Contact,
  FileSignature,
  GraduationCap,
  HeartHandshake,
  History,
  KeyRound,
  ListChecks,
  Puzzle,
  Settings,
  ShieldCheck,
  Smartphone,
  UserPlus,
  Users,
  UsersRound,
  Wrench,
  type LucideIcon,
} from "lucide-react";

// cmeprojects: one consistent icon per tab (anything new gets a puzzle piece).
const TAB_ICONS: Record<string, LucideIcon> = {
  Staff: Users,
  Teams: UsersRound,
  Roles: ShieldCheck,
  Clients: HeartHandshake,
  "Staff requests": ClipboardCheck,
  Onboarding: GraduationCap,
  Contracts: FileSignature,
  "Invite staff": UserPlus,
  "My tasks": ListChecks,
  "My account": Contact,
  "Use a car": Car,
  "Manage cars": Wrench,
  "Get the app": Smartphone,
  Tasks: ListChecks,
  Cars: Car,
  Compliance: GraduationCap,
  "SLA settings": Clock,
  "System settings": Settings,
  "Website settings": KeyRound,
  "Request approvals": ClipboardCheck,
  "Change log": History,
  "Staff access": KeyRound,
  "Feature builder": Puzzle,
  "System health": Activity,
};

// The row of tabs at the top of a section (Tasks, Cars, People, Reports,
// Settings). Only the tabs this person can open; nothing if there's just one.
export async function SectionTabs({ section, current }: { section: Section; current: string }) {
  const { profile, features } = await requireSession();
  const tabs = sectionTabs(section, profile.role, features, await getNavAccess(profile.role));
  if (tabs.length < 2) return null;
  return (
    <nav aria-label="Section" className="-mb-2 flex flex-wrap gap-1.5 print:hidden">
      {tabs.map((t) => {
        const active = t.href === current;
        const Icon = TAB_ICONS[t.text] ?? (t.href.startsWith("/reports") ? BarChart3 : Puzzle);
        return (
          <Link
            key={t.href}
            href={t.href}
            aria-current={active ? "page" : undefined}
            className={`flex min-h-10 items-center gap-1.5 rounded-full border px-4 text-sm font-semibold md:min-h-9 ${
              active ? "border-brand bg-brand text-brand-fg" : "border-line bg-surface text-muted hover:border-muted hover:text-ink"
            }`}
          >
            <Icon className="size-4 shrink-0" aria-hidden="true" />
            {t.text}
          </Link>
        );
      })}
    </nav>
  );
}
