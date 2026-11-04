// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { cache } from "react";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { AREA_LABELS, isArea } from "@/lib/delegation";

// cmeprojects: settings are saved as drafts and go live together on Deploy.

export type DraftKind = "setting" | "feature" | "delegation" | "website";
export type Draft = { kind: DraftKind; key: string; value: unknown; saved_by: string; saved_at: string };

export const SAVED_NOT_LIVE = "Saved. Not live yet: press Deploy to make it live.";
export const NOTHING_CHANGED = "Nothing has changed.";
const NEEDS_UPDATE = "This needs the latest database update (update 46).";

// The drafts the signed-in person can see: everyone's for the system admin, their own for others.
export const getDrafts = cache(async (): Promise<Draft[]> => {
  const { data, error } = await (await createClient()).from("settings_drafts").select("kind, key, value, saved_by, saved_at").order("saved_at");
  if (error) return [];
  return (data ?? []) as Draft[];
});

// A draft's value, if there is one.
export async function draftOf(kind: DraftKind, key: string): Promise<Draft | undefined> {
  return (await getDrafts()).find((d) => d.kind === kind && d.key === key);
}

// Save a change as a draft (the database checks who may change it).
export async function saveDraft(kind: DraftKind, key: string, value: unknown): Promise<FormState> {
  const { data, error } = await (await createClient()).rpc("save_draft", { p_kind: kind, p_key: key, p_value: value });
  if (error) return { error: error.code === "PGRST202" ? NEEDS_UPDATE : friendlyError(error) };
  return { message: data === "unchanged" ? NOTHING_CHANGED : SAVED_NOT_LIVE };
}

const WEBSITE_PARTS: Record<string, string> = { landing: "Website: landing page", answers: "Website: where it looks for answers", limits: "Website: model, limits and credit" };

// Short descriptions of each draft, for the Deploy list.
export async function describeDrafts(drafts: Draft[]): Promise<{ key: string; text: string; when: string }[]> {
  if (!drafts.length) return [];
  const supabase = await createClient();
  const settingKeys = drafts.filter((d) => d.kind === "setting").map((d) => d.key);
  const featureKeys = drafts.filter((d) => d.kind === "feature").map((d) => d.key);
  const [{ data: settings }, { data: features }] = await Promise.all([
    settingKeys.length ? supabase.from("app_settings").select("key, label").in("key", settingKeys) : Promise.resolve({ data: [] }),
    featureKeys.length ? supabase.from("features").select("key, label").in("key", featureKeys) : Promise.resolve({ data: [] }),
  ]);
  return drafts.map((d) => {
    let text: string;
    if (d.kind === "setting") text = (settings ?? []).find((s) => s.key === d.key)?.label ?? d.key;
    else if (d.kind === "feature") {
      const on = (d.value as { enabled?: boolean })?.enabled === true;
      text = `${(features ?? []).find((f) => f.key === d.key)?.label ?? d.key}: switch ${on ? "on" : "off"}`;
    } else if (d.kind === "delegation") {
      const mode = (d.value as { mode?: string })?.mode;
      const who = mode === "managers" ? "all managers" : mode === "selected" ? "selected people" : "only the system admin";
      text = `Who looks after ${isArea(d.key) ? AREA_LABELS[d.key].split(" (")[0].toLowerCase() : d.key}: ${who}`;
    } else text = WEBSITE_PARTS[d.key] ?? "Website settings";
    return { key: `${d.kind}:${d.key}`, text, when: d.saved_at };
  });
}

// Settings as they'll be once deployed: a saved draft replaces the live value
// on screen, marked as not live yet.
export async function withSettingDrafts<T extends { key: string; value: unknown }>(rows: T[]): Promise<(T & { pending?: boolean })[]> {
  const drafts = (await getDrafts()).filter((d) => d.kind === "setting");
  if (!drafts.length) return rows;
  return rows.map((r) => {
    const d = drafts.find((x) => x.key === r.key);
    return d ? { ...r, value: d.value, pending: true } : r;
  });
}
