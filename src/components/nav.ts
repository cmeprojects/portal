// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";
import { seesDashboard } from "@/lib/dashboard";

export type NavItem = { href: string; label: string };
export type NavGroup = { heading?: string; items: NavItem[] };

export function navFor(role: Role, features: Record<string, boolean>, newStarterTasks = false): NavGroup[] {
  const staffAdmin = role === "staff_admin" || role === "system_admin";
  const groups: NavGroup[] = [];

  // New starters: just their welcome page and account until they have a role.
  if (role === "new_starter" && !newStarterTasks) {
    return [
      { items: [{ href: "/", label: "Home" }] },
      {
        items: [
          { href: "/account", label: "My account" },
          { href: "/about", label: "About" },
        ],
      },
    ];
  }

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
        ...(role === "manager" || role === "system_admin"
          ? [
              { href: "/settings/roles", label: "Roles" },
              { href: "/settings/sla", label: "Due dates (SLA)" },
            ]
          : []),
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
