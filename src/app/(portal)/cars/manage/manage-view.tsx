// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { SectionTabs } from "@/components/section-tabs";
import { redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { canManageCars, canUseCars, getCarRules } from "@/lib/cars";
import { getTimeZone } from "@/lib/settings";
import { km } from "@/lib/car-types";
import { Badge, Card, PageHeader, Tabs } from "@/components/ui";
import { createClient } from "@/lib/supabase/server";
import { AddClientForm, AddPurposeForm, CarForm, ClientFieldForm, ClientRow, CorrectTripForm, PurposeRow, ReturnForSomeoneForm, type CarRow } from "./forms";

const TABS = [
  { key: "out", text: "Cars out now" },
  { key: "cars", text: "Cars" },
  { key: "clients", text: "Clients" },
  { key: "purposes", text: "Purposes of use" },
  { key: "trips", text: "Fix a trip" },
] as const;
type Tab = (typeof TABS)[number]["key"];

type TripRow = {
  id: number;
  car_id: string;
  driver_id: string;
  purpose: string;
  details: string;
  client_id: string | null;
  client_name: string;
  started_at: string;
  start_odo: number;
  gap_km: number;
  returned_at: string | null;
  end_odo: number | null;
  km: number | null;
  corrected_at: string | null;
};

// Shared with the Cars app (base "/cars-app"), so managers can do this on their phone.
export async function ManageCars({ base, tabParam }: { base: string; tabParam: string | string[] | undefined }) {
  const { profile, features } = await requireSession();
  const rules = await getCarRules();
  if (!canUseCars(profile.role, features) || !canManageCars(profile.role, rules)) redirect(base);
  const asked = tabParam;
  const tab: Tab = TABS.some((t) => t.key === asked) ? (asked as Tab) : "out";
  const supabase = await createClient();
  const timeZone = await getTimeZone();
  const when = new Intl.DateTimeFormat("en-AU", { weekday: "short", day: "numeric", month: "short", hour: "numeric", minute: "2-digit", timeZone });
  const date = (d: string | null) => (d ? new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", timeZone: "UTC" }).format(new Date(`${d}T00:00:00Z`)) : "");

  const [{ data: cars }, { data: people }] = await Promise.all([
    supabase.from("cars").select("id, name, rego, car_type, colour, odometer, rego_expires, service_due_date, service_due_km, notes, active").order("active", { ascending: false }).order("name"),
    supabase.from("profiles").select("id, full_name, email"),
  ]);
  const carList = (cars ?? []) as CarRow[];
  const carName = new Map(carList.map((c) => [c.id, `${c.name} · ${c.rego}`]));
  const nameOf = new Map((people ?? []).map((p) => [p.id, p.full_name || p.email]));

  return (
    <>
      {base === "/cars" ? <SectionTabs section="cars" current="/cars/manage" /> : null}
      <PageHeader
        eyebrow="Cars"
        title="Manage cars"
        intro="Add cars, clients and purposes of use, return a car for someone, or fix a trip. Every change goes in the change log."
        action={base === "/cars" ? undefined : <Link href={base} className="text-sm font-semibold text-brand underline">Back to Cars</Link>}
      />
      <Tabs label="Manage cars" items={TABS.map((t) => ({ href: `${base}/manage?tab=${t.key}`, text: t.text, current: t.key === tab }))} />

      {tab === "out" ? <CarsOut carName={carName} nameOf={nameOf} when={when} /> : null}

      {tab === "cars" ? (
        <>
          <Card className="p-5">
            <h2 className="mb-4 heading-sm">Add a car</h2>
            <CarForm />
          </Card>
          <div className="flex flex-col gap-3">
            {carList.map((c) => (
              <Card key={c.id} className="p-0">
                <details className="group">
                  <summary className="flex min-h-14 cursor-pointer list-none flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3">
                    <span className={`min-w-48 flex-1 ${c.active ? "" : "text-muted"}`}>
                      <span className="block font-semibold">{c.name}</span>
                      <span className="block text-sm text-muted">
                        {c.rego}
                        {c.car_type ? ` · ${c.car_type}` : ""} · {km(c.odometer)}
                      </span>
                    </span>
                    {c.rego_expires ? <span className="text-sm text-muted">Rego {date(c.rego_expires)}</span> : null}
                    {c.active ? <Badge tone="good">In use</Badge> : <Badge tone="grey">Retired</Badge>}
                    <span className="text-sm font-semibold text-brand group-open:hidden">Edit</span>
                    <span className="hidden text-sm font-semibold text-brand group-open:inline">Close</span>
                  </summary>
                  <div className="border-t border-line px-5 py-5">
                    <CarForm car={c} />
                    {base === "/cars" ? (
                      <p className="mt-4 text-sm text-muted">
                        QR sticker for the dashboard: <Link className="font-semibold text-brand underline" href={`/cars/install?car=${c.id}`}>print it</Link>
                      </p>
                    ) : null}
                  </div>
                </details>
              </Card>
            ))}
          </div>
        </>
      ) : null}

      {tab === "clients" ? <Clients /> : null}
      {tab === "purposes" ? <Purposes /> : null}
      {tab === "trips" ? <Trips carName={carName} nameOf={nameOf} when={when} /> : null}
    </>
  );
}

async function CarsOut({ carName, nameOf, when }: { carName: Map<string, string>; nameOf: Map<string, string>; when: Intl.DateTimeFormat }) {
  const supabase = await createClient();
  const { data } = await supabase.from("car_trips").select("id, car_id, driver_id, purpose, client_name, started_at, start_odo, managers_told_at").is("returned_at", null).order("started_at");
  const out = (data ?? []) as (Pick<TripRow, "id" | "car_id" | "driver_id" | "purpose" | "client_name" | "started_at" | "start_odo"> & {
    managers_told_at: string | null;
  })[];
  return (
    <Card className="overflow-hidden">
      <h2 className="heading-sm border-b border-line px-5 py-3">Cars out now · {out.length}</h2>
      {out.length === 0 ? (
        <p className="px-5 py-4 text-sm text-muted">All cars are in.</p>
      ) : (
        <ul className="divide-y divide-line">
          {out.map((t) => (
            <li key={t.id} className="flex flex-col gap-3 px-5 py-4">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span>
                  <span className="block font-semibold">{carName.get(t.car_id) ?? "A car"}</span>
                  <span className="block text-sm text-muted">
                    {nameOf.get(t.driver_id) ?? "Someone"} · since {when.format(new Date(t.started_at))} · {t.purpose}
                    {t.client_name ? ` · ${t.client_name}` : ""}
                  </span>
                </span>
                {t.managers_told_at ? <Badge tone="warn">Not returned overnight</Badge> : null}
              </div>
              <details>
                <summary className="cursor-pointer text-sm font-semibold text-brand">Return it for them</summary>
                <div className="pt-3">
                  <ReturnForSomeoneForm tripId={t.id} startOdo={t.start_odo} driver={nameOf.get(t.driver_id) ?? "them"} />
                </div>
              </details>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}

async function Clients() {
  const supabase = await createClient();
  const [{ data }, rules] = await Promise.all([supabase.from("car_clients").select("id, name, reference, active").order("active", { ascending: false }).order("name"), getCarRules()]);
  const clients = data ?? [];
  return (
    <>
      <Card className="p-5">
        <ClientFieldForm current={rules.clientField} />
      </Card>
      <Card className="p-5">
        <h2 className="mb-4 heading-sm">Add a client</h2>
        <AddClientForm />
      </Card>
      {clients.length ? (
        <Card className="overflow-hidden">
          <h2 className="heading-sm border-b border-line px-5 py-3">Clients · {clients.length}</h2>
          <ul className="divide-y divide-line">
            {clients.map((c) => (
              <ClientRow key={c.id} client={c} />
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  );
}

async function Purposes() {
  const supabase = await createClient();
  const { data } = await supabase.from("car_purposes").select("id, name, sort_order, active").order("sort_order").order("name");
  const purposes = data ?? [];
  return (
    <Card className="overflow-hidden">
      <div className="flex flex-col gap-3 border-b border-line px-5 py-4">
        <div>
          <h2 className="heading-sm">Purposes of use</h2>
          <p className="text-sm text-muted">
            Staff choose one when they start a trip, in this order. Use the arrows to reorder. Hidden ones stay on old trips but can&apos;t be
            chosen. &quot;Other&quot; asks staff to write a few words.
          </p>
        </div>
        <AddPurposeForm />
      </div>
      <ul className="divide-y divide-line">
        {purposes.map((p, i) => (
          <PurposeRow key={p.id} purpose={p} first={i === 0} last={i === purposes.length - 1} />
        ))}
      </ul>
    </Card>
  );
}

async function Trips({ carName, nameOf, when }: { carName: Map<string, string>; nameOf: Map<string, string>; when: Intl.DateTimeFormat }) {
  const supabase = await createClient();
  const [{ data }, { data: purposes }, { data: clients }] = await Promise.all([
    supabase.from("car_trips").select("id, car_id, driver_id, purpose, details, client_id, client_name, started_at, start_odo, gap_km, returned_at, end_odo, km, corrected_at").order("started_at", { ascending: false }).limit(40),
    supabase.from("car_purposes").select("name").eq("active", true).order("sort_order"),
    supabase.from("car_clients").select("id, name").order("name"),
  ]);
  const trips = (data ?? []) as TripRow[];
  return (
    <Card className="overflow-hidden">
      <div className="border-b border-line px-5 py-3">
        <h2 className="heading-sm">Recent trips</h2>
        <p className="text-sm text-muted">Staff can undo their own start or return for a few minutes. After that, fix it here with a reason.</p>
      </div>
      {trips.length === 0 ? (
        <p className="px-5 py-4 text-sm text-muted">No trips yet.</p>
      ) : (
        <ul className="divide-y divide-line">
          {trips.map((t) => (
            <li key={t.id} className="px-5 py-3">
              <details>
                <summary className="flex cursor-pointer list-none flex-wrap items-center justify-between gap-x-4 gap-y-1">
                  <span className="min-w-48 flex-1">
                    <span className="block text-sm font-semibold">
                      {carName.get(t.car_id) ?? "A car"} · {nameOf.get(t.driver_id) ?? "Someone"}
                    </span>
                    <span className="block text-xs text-muted">
                      {when.format(new Date(t.started_at))} · {t.purpose}
                      {t.client_name ? ` · ${t.client_name}` : ""} · {t.start_odo.toLocaleString("en-AU")} → {t.end_odo?.toLocaleString("en-AU") ?? "still out"}
                    </span>
                  </span>
                  <span className="flex items-center gap-2">
                    {t.gap_km > 0 ? <Badge tone="warn">{km(t.gap_km)} gap</Badge> : null}
                    {t.corrected_at ? <Badge tone="grey">Fixed</Badge> : null}
                    <span className="text-sm font-semibold tabular-nums">{km(t.km)}</span>
                  </span>
                </summary>
                <div className="pt-4">
                  <CorrectTripForm trip={t} purposes={(purposes ?? []).map((p) => p.name)} clients={clients ?? []} />
                </div>
              </details>
            </li>
          ))}
        </ul>
      )}
    </Card>
  );
}
