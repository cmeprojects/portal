// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { sydneyToday } from "@/lib/sydney-time";

const day = (d: string) => new Date(`${d}T12:00:00`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" });

// cmeprojects (update 124, Stage 6): an Allied Health practitioner's home: the
// clients they've been given, and when each one's access ends.
export async function PractitionerHome({ me, name }: { me: string; name: string | null }) {
  const supabase = await createClient();
  const today = sydneyToday();
  const { data: on } = await supabase.rpc("feature_enabled", { p_key: "allied_health" });
  const { data: rows } = on === true
    ? await supabase.from("client_external_access").select("client_id, ends_on").eq("user_id", me).is("ended_at", null).lte("starts_on", today).gte("ends_on", today).order("ends_on")
    : { data: [] };
  const access = (rows ?? []) as { client_id: string; ends_on: string }[];
  const { data: clients } = access.length ? await supabase.from("car_clients").select("id, name, preferred_name").in("id", access.map((a) => a.client_id)) : { data: [] };
  const nameOf = new Map(((clients ?? []) as { id: string; name: string; preferred_name: string | null }[]).map((c) => [c.id, c.preferred_name || c.name]));
  const soon = (d: string) => new Date(`${d}T12:00:00`).getTime() - new Date(`${today}T12:00:00`).getTime() <= 14 * 86_400_000;
  const listed = access.filter((a) => nameOf.has(a.client_id));
  return (
    <>
      <PageHeader title={`Welcome${name ? `, ${name.split(" ")[0]}` : ""}`} intro={on === true ? "The clients you've been given access to. Access ends by itself on the date shown." : undefined} />
      {on !== true ? (
        <Card className="max-w-2xl p-5 text-sm">Your account is ready. There&apos;s nothing here for you yet; we&apos;ll let you know when there is.</Card>
      ) : listed.length ? (
        <Card className="p-0">
          <ul className="divide-y divide-line">
            {listed.map((a) => (
              <li key={a.client_id}>
                <Link href={`/practitioner/${a.client_id}`} className="flex flex-wrap items-center gap-2 px-4 py-3 hover:bg-page">
                  <span className="flex-1 font-semibold">{nameOf.get(a.client_id)}</span>
                  <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${soon(a.ends_on) ? "bg-warn-soft" : "bg-page ring-1 ring-line"}`}>
                    Access ends {day(a.ends_on)}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </Card>
      ) : (
        <Card className="max-w-2xl p-5 text-sm">You haven&apos;t been given access to any clients yet. The client&apos;s case manager will set it up and you&apos;ll get an email.</Card>
      )}
    </>
  );
}
