// Staff Portal · © cmeproject. All rights reserved.
import { CATEGORIES, MODULES, type CategoryId } from "@/lib/modules";

// cmeprojects: the menu, built from the module catalogue. An item shows only
// when the person can already open its page (the same checks as before:
// `allowed` comes from the existing menu and section-tab rules), so nobody
// gains or loses access. Submodules show under their module; if someone can
// open only one submodule, just that one shows.

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
  const can = (id: string, href: string) => {
    if (id === "workspace.forms") return allowed.has("/forms") && !opts.formsAsMaker;
    if (id === "workflows.forms") return allowed.has("/forms") && opts.formsAsMaker;
    if (id === "ops.features") return opts.builtFeatures.length > 0;
    return allowed.has(href);
  };
  const node = (id: string): NavNode | null => {
    const m = MODULES.find((x) => x.id === id)!;
    let kids = MODULES.filter((c) => c.parent === id)
      .map((c) => (can(c.id, c.href) ? leaf(c.id) : null))
      .filter(Boolean) as NavNode[];
    // Dynamic children: built features and their reports.
    if (id === "ops.features") kids = opts.builtFeatures.map((f) => ({ id: `ops.features.${f.slug}`, label: f.label, icon: "Puzzle", href: `/f/${f.slug}`, match: [`/f/${f.slug}`], children: [] }));
    if (id === "insights.reports")
      kids = [...kids, ...opts.featureReports.map((f) => ({ id: `insights.reports.${f.slug}`, label: f.label, icon: "BarChart3", href: `/reports/f/${f.slug}`, match: [`/reports/f/${f.slug}`], children: [] }))];
    const self = can(id, m.href);
    if (!self && !kids.length) return null;
    // One child only and no parent page: show the child itself.
    if (!self && kids.length === 1) return kids[0];
    const label = id === "workspace.dashboard" ? opts.homeLabel : m.label;
    const match = id === "workspace.dashboard" && opts.homeLabel !== "Dashboard" ? ["/", "/my-tasks"] : (m.match ?? [m.href]);
    return { id, label, icon: m.icon, href: self ? m.href : kids[0].href, match: [...match, ...kids.flatMap((k) => k.match)], children: kids.length > 1 ? kids : [] };
  };
  const leaf = (id: string): NavNode => {
    const m = MODULES.find((x) => x.id === id)!;
    return { id, label: m.label, icon: m.icon, href: m.href, match: m.match ?? [m.href], children: [] };
  };
  return CATEGORIES.map((c) => ({
    id: c.id,
    label: c.label,
    items: MODULES.filter((m) => m.category === c.id && !m.parent)
      .map((m) => node(m.id))
      .filter(Boolean) as NavNode[],
  })).filter((c) => c.items.length);
}
