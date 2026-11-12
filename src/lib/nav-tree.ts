// Staff Portal · © cmeproject. All rights reserved.
import { CATEGORIES, MODULES, type CategoryId } from "@/lib/modules";

// cmeprojects: the menu, built from the module catalogue: one item per module,
// grouped by category. A module's own sub-pages are tabs on its page, not
// menu items unless the person shows them. An item shows only when the person can already open one of its
// pages (`allowed` comes from the existing menu and page rules), and opens the
// first of those pages, so nobody gains or loses access.

export type NavNode = { id: string; label: string; icon: string; href: string; match: string[]; children: NavNode[] };
export type NavCategory = { id: CategoryId; label: string; items: NavNode[] };

export function buildNav(opts: {
  allowed: Set<string>;
  homeLabel: string;
  formsAsMaker: boolean;
  builtFeatures: { slug: string; label: string }[];
  featureReports: { slug: string; label: string }[];
}): NavCategory[] {
  const { allowed } = opts;
  const allowedList = [...allowed];
  // The first page of this module the person can open (its own page first).
  const firstPage = (href: string, match: string[]) => {
    if (href && allowed.has(href)) return href;
    for (const m of match) {
      const hit = allowed.has(m) ? m : allowedList.find((a) => a.startsWith(`${m}/`));
      if (hit) return hit;
    }
    return null;
  };
  const items = (cat: CategoryId): NavNode[] => {
    const out: NavNode[] = [];
    for (const m of MODULES.filter((x) => x.category === cat && !x.parent)) {
      if (m.id === "ops.features") {
        // Each built feature is its own item.
        for (const f of opts.builtFeatures) out.push({ id: `ops.features.${f.slug}`, label: f.label, icon: "Puzzle", href: `/f/${f.slug}`, match: [`/f/${f.slug}`], children: [] });
        continue;
      }
      if (m.id === "workspace.forms" && opts.formsAsMaker) continue;
      if (m.id === "workflows.forms" && !opts.formsAsMaker) continue;
      if (!m.href) continue;
      const match = m.match ?? [m.href];
      // A hub (Portal settings) opens its own page whenever one of its sub-pages is allowed.
      const hubOk = m.hub && MODULES.some((c) => c.parent === m.id && c.href && allowed.has(c.href));
      const href = hubOk ? m.href : m.hub ? null : firstPage(m.href, match);
      if (!href) continue;
      const home = m.id === "workspace.dashboard";
      // Sub-pages (shown only when the person chooses; see the sidebar).
      const kids: NavNode[] = MODULES.filter((c) => !m.hub && c.parent === m.id && c.href && allowed.has(c.href)).map((c) => ({
        id: c.id,
        label: c.label,
        icon: c.icon,
        href: c.href,
        match: c.match ?? [c.href],
        children: [],
      }));
      if (m.id === "insights.reports")
        for (const f of opts.featureReports) kids.push({ id: `insights.reports.${f.slug}`, label: f.label, icon: "BarChart3", href: `/reports/f/${f.slug}`, match: [`/reports/f/${f.slug}`], children: [] });
      out.push({
        id: m.id,
        label: home ? opts.homeLabel : m.label,
        icon: m.icon,
        href,
        match: home && opts.homeLabel !== "Dashboard" ? ["/", "/my-tasks"] : match,
        children: kids.length > 1 ? kids : [],
      });
    }
    return out;
  };
  return CATEGORIES.map((c) => ({ id: c.id, label: c.label, items: items(c.id) })).filter((c) => c.items.length);
}
