// Staff Portal · © cmeproject. All rights reserved.
import type { Role } from "@/lib/roles";

export type NavItem = { href: string; label: string };
export type NavGroup = { heading?: string; items: NavItem[] };

export function navFor(role: Role, features: Record<string, boolean>): NavGroup[] {
  const staffAdmin = role === "staff_admin" || role === "system_admin";
  const groups: NavGroup[] = [];

  groups.push({
    items:
      features.tasks !== false
        ? [
            { href: "/", label: "My tasks" },
            { href: "/tasks/new", label: "New task" },
          ]
        : [{ href: "/", label: "My tasks" }],
  });

  if (staffAdmin) {
    groups.push({
      heading: "Settings",
      items: [
        { href: "/settings/staff", label: "Staff & roles" },
        { href: "/settings/teams", label: "Teams" },
        { href: "/settings/registries", label: "Registries" },
      ],
    });
  }

  if (role === "system_admin") {
    groups.push({
      heading: "System",
      items: [
        { href: "/system", label: "System settings" },
        { href: "/system/audit", label: "Change log" },
      ],
    });
  }

  groups.push({
    heading: "You",
    items: [
      { href: "/account", label: "My account" },
      { href: "/about", label: "About" },
    ],
  });

  return groups;
}
