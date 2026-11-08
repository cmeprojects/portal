// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getSession } from "@/lib/session";

// cmeprojects: staff photos are private files. For signed-in staff only, the
// server makes short-lived links to them. A photo is only ever taken from the
// person's own folder (avatars/<id>/… or compliance-files/<id>/…), so a link
// can never point at someone else's documents.
export type PhotoOwner = { id: string; avatar_ref?: string | null };

const OK = /^(avatars|compliance-files)\/([0-9a-f-]{36})\/[^/]+$/;

export async function photoLinks(people: PhotoOwner[]): Promise<Record<string, string>> {
  const session = await getSession();
  if (!session) return {};
  const byBucket: Record<string, { id: string; path: string }[]> = {};
  for (const p of people) {
    const m = p.avatar_ref?.match(OK);
    if (!m || m[2] !== p.id) continue;
    (byBucket[m[1]] ??= []).push({ id: p.id, path: p.avatar_ref!.slice(m[1].length + 1) });
  }
  const out: Record<string, string> = {};
  const admin = createAdminClient();
  await Promise.all(
    Object.entries(byBucket).map(async ([bucket, list]) => {
      const { data } = await admin.storage.from(bucket).createSignedUrls(
        list.map((l) => l.path),
        60 * 60,
      );
      (data ?? []).forEach((d, i) => {
        if (d.signedUrl) out[list[i].id] = d.signedUrl;
      });
    }),
  );
  return out;
}
