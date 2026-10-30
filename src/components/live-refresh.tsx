// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

// cmeprojects: keeps an open page up to date. When one of these tables
// changes (and this person may see the change), the page refreshes itself.
// With onShow, it also refreshes when someone comes back to the tab or
// reopens the app on their phone. Typing in a form isn't lost.
export function LiveRefresh({ tables, onShow = false }: { tables: string[]; onShow?: boolean }) {
  const router = useRouter();
  const key = tables.join(",");

  useEffect(() => {
    let last = Date.now();
    let stale = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const refresh = () => {
      clearTimeout(timer);
      timer = setTimeout(() => {
        last = Date.now();
        stale = false;
        router.refresh();
      }, 500);
    };
    const visible = () => document.visibilityState === "visible";
    // Back on the page: refresh if something changed meanwhile, or (onShow) if it's been a little while.
    const shown = () => {
      if (visible() && (stale || (onShow && Date.now() - last > 10_000))) refresh();
    };
    document.addEventListener("visibilitychange", shown);
    window.addEventListener("focus", shown);
    window.addEventListener("pageshow", shown);

    // Connect as the signed-in person, so they hear about what they may see.
    const supabase = createClient();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let gone = false;
    void supabase.auth.getSession().then(async ({ data }) => {
      if (gone || !key || !data.session) return;
      await supabase.realtime.setAuth(data.session.access_token);
      if (gone) return;
      channel = supabase.channel(`live:${key}:${Math.random().toString(36).slice(2)}`);
      for (const table of key.split(",")) {
        channel.on("postgres_changes", { event: "*", schema: "public", table }, () => {
          if (visible()) refresh();
          else stale = true;
        });
      }
      channel.subscribe();
    });

    return () => {
      gone = true;
      clearTimeout(timer);
      document.removeEventListener("visibilitychange", shown);
      window.removeEventListener("focus", shown);
      window.removeEventListener("pageshow", shown);
      if (channel) void supabase.removeChannel(channel);
    };
  }, [router, key, onShow]);

  return null;
}
