// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";
import { seesDashboard } from "@/lib/dashboard";

export type NavItem = { href: string; label: string };
export type NavGroup = { heading?: string; items: NavItem[] };

export function navFor(role: Role, features: Record<string, boolean>): NavGroup[] {
  const staffAdmin = role === "staff_admin" || role === "system_admin";
  const groups: NavGroup[] = [];

  const home: NavItem[] = seesDashboard(role)
    ? [
        { href: "/", label: "Dashboard" },
        { href: "/my-tasks", label: "My tasks" },
      ]
    : [{ href: "/", label: "My tasks" }];
  groups.push({
    items: [
      ...home,
      ...(features.tasks !== false ? [{ href: "/tasks/new", label: "New task" }] : []),
      { href: "/registers", label: "Registers" },
    ],
  });

  const people = role === "manager" || staffAdmin;
  if (people) {
    groups.push({
      items: [
        { href: "/settings/staff", label: "Staff & roles" },
        { href: "/settings/teams", label: "Teams" },
      ],
    });
  }

  if (role === "system_admin") {
    groups.push({
      items: [
        { href: "/system", label: "System settings" },
        { href: "/system/audit", label: "Change log" },
      ],
    });
  }

  // Last, with no heading.
  groups.push({
    items: [
      { href: "/account", label: "My account" },
      { href: "/about", label: "About" },
    ],
  });

  return groups;
}
