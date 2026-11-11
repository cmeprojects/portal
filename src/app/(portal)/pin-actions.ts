// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";

// cmeprojects: pin or unpin a page in your menu (your own shortcuts only).
export async function togglePin(href: string, label: string): Promise<{ pinned?: boolean; error?: string }> {
  const { profile } = await requireSession();
  if (!/^\/[A-Za-z0-9/_?=&.-]*$/.test(href) || href.length > 200) return { error: "This page can't be pinned." };
  const supabase = await createClient();
  const { data: existing } = await supabase.from("pinned_items").select("href").eq("user_id", profile.id).eq("href", href).maybeSingle();
  if (existing) {
    const { error } = await supabase.from("pinned_items").delete().eq("user_id", profile.id).eq("href", href);
    if (error) return { error: "Couldn't unpin it. Please try again." };
    revalidatePath("/", "layout");
    return { pinned: false };
  }
  const { count } = await supabase.from("pinned_items").select("href", { count: "exact", head: true }).eq("user_id", profile.id);
  if ((count ?? 0) >= 8) return { error: "You can pin up to 8 pages. Unpin one first." };
  const { error } = await supabase.from("pinned_items").insert({ user_id: profile.id, href, label: label.trim().slice(0, 60) || "Pinned page", position: count ?? 0 });
  if (error) return { error: "Couldn't pin it. Please try again." };
  revalidatePath("/", "layout");
  return { pinned: true };
}
