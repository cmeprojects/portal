// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";

// cmeprojects (update 154): the download trail. Every export and document
// download records who, what and when (and the client or staff member it was
// about). Never stops the download: if the trail can't be written (say, before
// update 154 is run), the file still comes.
export type DownloadKind = "export" | "document" | "record";

export async function logDownload(entry: { kind: DownloadKind; label: string; action?: "export" | "download_link_issued" | "download_denied"; clientId?: string | null; personId?: string | null; details?: Record<string, unknown> }) {
  try {
    const supabase = await createClient();
    await supabase.from("download_log").insert({
      kind: entry.kind,
      action: entry.action ?? (entry.kind === "export" ? "export" : "download_link_issued"),
      outcome: entry.action === "download_denied" ? "denied" : "success",
      label: entry.label.slice(0, 300) || "Download",
      client_id: entry.clientId ?? null,
      person_id: entry.personId ?? null,
      details: entry.details ?? {},
    });
  } catch {
    // The trail is best effort; the download goes ahead.
  }
}
