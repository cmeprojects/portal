// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { requireSession } from "@/lib/session";
import { logDownload } from "@/lib/download-log";

// cmeprojects (update 154): files made in the browser (like the client list
// export) are recorded here, in the signed-in person's name.
export async function recordExport(label: string, rows: number): Promise<void> {
  await requireSession();
  await logDownload({ kind: "export", label: String(label).slice(0, 200), details: { rows: Number(rows) || 0 } });
}
