// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { requireSession } from "@/lib/session";
import { getNavAccess } from "@/lib/nav-access";
import { navFor, sectionTabs } from "@/components/nav";

// cmeprojects: the pages this person can open, from the existing menu and
// page-tab rules (the same checks the pages themselves use). The menu and the
// Portal settings page show only these, so nobody gains or loses access.
export const getAllowedPages = cache(async () => {
  const { profile, features } = await requireSession();
  const navAccess = await getNavAccess(profile.role);
  const groups = navFor(profile.role, features, navAccess);
  const tabPages = (["tasks", "cars", "people", "reports", "settings"] as const).flatMap((sec) =>
    sectionTabs(sec, profile.role, features, navAccess).map((t) => ({ label: t.text, href: t.href })),
  );
  const searchPages = [...groups.flatMap((g) => g.items.map((it) => ({ label: it.label, href: it.href }))), ...tabPages].filter(
    (p, i, all) => all.findIndex((x) => x.href === p.href && x.label === p.label) === i,
  );
  const allowed = new Set<string>(searchPages.map((p) => p.href));
  for (const t of sectionTabs("account", profile.role, features, navAccess)) allowed.add(t.href);
  if (allowed.has("/compliance")) allowed.add("/compliance/expiry");
  return { navAccess, groups, tabPages, searchPages, allowed };
});
