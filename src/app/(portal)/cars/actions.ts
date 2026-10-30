// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { canManageCars, canUseCars, getCarRules } from "@/lib/cars";
import { friendlyError } from "@/lib/db-error";
import { text, type FormState } from "@/lib/form";

// Readings are typed with spaces or commas on phones: keep the digits.
function reading(form: FormData, name: string): number | null {
  const digits = text(form, name).replace(/[^\d]/g, "");
  return digits ? Number(digits) : null;
}

function refresh() {
  revalidatePath("/cars", "layout");
  revalidatePath("/cars-app", "layout");
}

async function requireDriver() {
  const session = await requireSession();
  if (!canUseCars(session.profile.role, session.features)) throw new Error("Cars aren't available to you");
  return session;
}

async function requireCarManager() {
  const session = await requireDriver();
  if (!canManageCars(session.profile.role, await getCarRules())) throw new Error("Only car managers can do this");
  return session;
}

// The client list is shared by Cars and built features: car managers, and
// managers, staff admins and the system admin (People → Clients) keep it.
async function requireClientManager() {
  const session = await requireSession();
  const role = session.profile.role;
  if (["manager", "staff_admin", "system_admin"].includes(role)) return session;
  if (canUseCars(role, session.features) && canManageCars(role, await getCarRules())) return session;
  throw new Error("You can't change the client list");
}

// ---------------------------------------------------------------------------
// Staff: start, return and undo
// ---------------------------------------------------------------------------

export async function startTrip(_: FormState, form: FormData): Promise<FormState> {
  await requireDriver();
  const odo = reading(form, "start_odo");
  if (odo === null) return { error: "Enter the odometer reading." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("start_car_trip", {
    p_car_id: text(form, "car_id"),
    p_purpose_id: text(form, "purpose_id"),
    p_client_id: text(form, "client_id") || null,
    p_start_odo: odo,
    p_details: text(form, "details"),
  });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Started. Drive safely." };
}

export async function undoStart(_: FormState, form: FormData): Promise<FormState> {
  await requireDriver();
  const supabase = await createClient();
  const { error } = await supabase.rpc("undo_car_start", { p_trip_id: Number(text(form, "trip_id")) });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Undone. The car is free again." };
}

export async function returnTrip(_: FormState, form: FormData): Promise<FormState> {
  await requireDriver();
  const odo = reading(form, "end_odo");
  if (odo === null) return { error: "Enter the odometer reading." };
  const supabase = await createClient();
  const { data, error } = await supabase.rpc("return_car_trip", {
    p_trip_id: Number(text(form, "trip_id")),
    p_end_odo: odo,
    p_photo_path: text(form, "photo_path") || null,
    p_note: text(form, "note"),
  });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: `Returned. That trip was ${Number(data).toLocaleString("en-AU")} km.` };
}

export async function undoReturn(_: FormState, form: FormData): Promise<FormState> {
  await requireDriver();
  const supabase = await createClient();
  const { error } = await supabase.rpc("undo_car_return", { p_trip_id: Number(text(form, "trip_id")) });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Undone. You still have the car." };
}

// ---------------------------------------------------------------------------
// Car managers: cars, clients, purposes, returning for someone, corrections
// ---------------------------------------------------------------------------

function optionalDate(form: FormData, name: string): string | null {
  const v = text(form, name);
  return /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : null;
}

export async function saveCar(_: FormState, form: FormData): Promise<FormState> {
  await requireCarManager();
  const id = text(form, "id");
  const name = text(form, "name");
  const rego = text(form, "rego").toUpperCase();
  if (!name) return { error: "Give the car a name, for example Kia Carnival." };
  if (!rego) return { error: "Enter the rego." };
  const odo = reading(form, "odometer");
  const values: Record<string, unknown> = {
    name: name.slice(0, 80),
    rego: rego.slice(0, 12),
    car_type: text(form, "car_type").slice(0, 60),
    colour: text(form, "colour").slice(0, 40),
    rego_expires: optionalDate(form, "rego_expires"),
    service_due_date: optionalDate(form, "service_due_date"),
    service_due_km: reading(form, "service_due_km"),
    notes: text(form, "notes").slice(0, 1000),
    active: id ? form.get("active") === "true" : true,
  };
  const photo = text(form, "photo_path");
  if (photo) values.photo_path = photo;
  const supabase = await createClient();
  if (id) {
    // The reading only moves forward here; trips keep it up to date.
    if (odo !== null) {
      const { data: car } = await supabase.from("cars").select("odometer").eq("id", id).maybeSingle();
      if (car && odo < car.odometer) return { error: `The odometer can't go below the last reading (${car.odometer.toLocaleString("en-AU")} km). Fix the trip instead.` };
      values.odometer = odo;
    }
    const { error } = await supabase.from("cars").update(values).eq("id", id);
    if (error) return { error: error.code === "23505" ? "Another car already has that rego." : friendlyError(error) };
  } else {
    if (odo === null) return { error: "Enter the odometer reading now." };
    const { error } = await supabase.from("cars").insert({ ...values, odometer: odo });
    if (error) return { error: error.code === "23505" ? "A car with that rego has already been added." : friendlyError(error) };
  }
  refresh();
  return { message: id ? "Saved." : `${name} added. Staff can use it now.` };
}

// Whether trips have a client: car managers decide (System settings → Cars has it too).
export async function saveClientField(_: FormState, form: FormData): Promise<FormState> {
  await requireCarManager();
  const value = text(form, "value");
  if (!["off", "optional", "required"].includes(value)) return { error: "Choose Off, Optional or Required." };
  const supabase = await createClient();
  const { data, error } = await supabase.from("app_settings").update({ value }).eq("key", "vehicles.client_field").select("key");
  if (error || !data?.length) return { error: friendlyError(error, "That didn't save. Please try again.") };
  revalidatePath("/", "layout");
  return { message: value === "off" ? "Saved. Staff won't see a client field." : value === "optional" ? "Saved. Staff can choose a client or leave it blank." : "Saved. Staff must choose a client to start a trip." };
}

export async function saveClient(_: FormState, form: FormData): Promise<FormState> {
  await requireClientManager();
  const id = text(form, "id");
  const name = text(form, "name");
  if (!name) return { error: "Enter the client's name." };
  const values = { name: name.slice(0, 80), reference: text(form, "reference").slice(0, 60) };
  const supabase = await createClient();
  const { error } = id ? await supabase.from("car_clients").update(values).eq("id", id) : await supabase.from("car_clients").insert(values);
  if (error) return { error: friendlyError(error) };
  refresh();
  revalidatePath("/settings/clients");
  return { message: id ? "Saved." : `${name} added.` };
}

export async function savePurpose(_: FormState, form: FormData): Promise<FormState> {
  await requireCarManager();
  const id = text(form, "id");
  const name = text(form, "name");
  if (!name) return { error: "Enter the purpose, for example Community access." };
  const supabase = await createClient();
  let error;
  if (id) {
    ({ error } = await supabase.from("car_purposes").update({ name: name.slice(0, 60) }).eq("id", id));
  } else {
    // New purposes go to the bottom of the list ("Other" stays last).
    const { data: list } = await supabase.from("car_purposes").select("name, sort_order").order("sort_order", { ascending: false });
    const top = (list ?? []).filter((p) => p.name !== "Other")[0]?.sort_order ?? 0;
    ({ error } = await supabase.from("car_purposes").insert({ name: name.slice(0, 60), sort_order: top + 1, active: true }));
  }
  if (error) return { error: error.code === "23505" ? "That purpose is already on the list." : friendlyError(error) };
  refresh();
  return { message: id ? "Renamed." : `${name} added.` };
}

// Move a purpose up or down the list staff see.
export async function movePurpose(form: FormData) {
  await requireCarManager();
  const id = text(form, "id");
  const up = text(form, "dir") === "up";
  const supabase = await createClient();
  const { data } = await supabase.from("car_purposes").select("id, sort_order").order("sort_order").order("name");
  const list = data ?? [];
  const i = list.findIndex((p) => p.id === id);
  const j = up ? i - 1 : i + 1;
  if (i < 0 || j < 0 || j >= list.length) return;
  [list[i], list[j]] = [list[j], list[i]];
  // Number them 10, 20, 30… in the new order.
  await Promise.all(
    list.map((p, n) => ((n + 1) * 10 !== p.sort_order ? supabase.from("car_purposes").update({ sort_order: (n + 1) * 10 }).eq("id", p.id) : null)),
  );
  refresh();
}

export async function setPurposeShown(form: FormData) {
  await requireCarManager();
  const supabase = await createClient();
  await supabase.from("car_purposes").update({ active: text(form, "active") === "true" }).eq("id", text(form, "id"));
  refresh();
}

export async function setClientShown(form: FormData) {
  await requireClientManager();
  const supabase = await createClient();
  await supabase.from("car_clients").update({ active: text(form, "active") === "true" }).eq("id", text(form, "id"));
  refresh();
}

export async function returnForSomeone(_: FormState, form: FormData): Promise<FormState> {
  await requireCarManager();
  const odo = reading(form, "end_odo");
  if (odo === null) return { error: "Enter the odometer reading." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("return_car_trip", {
    p_trip_id: Number(text(form, "trip_id")),
    p_end_odo: odo,
    p_photo_path: null,
    p_note: text(form, "note"),
  });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Returned. They've been told." };
}

export async function correctTrip(_: FormState, form: FormData): Promise<FormState> {
  await requireCarManager();
  const start = reading(form, "start_odo");
  if (start === null) return { error: "Enter the start reading." };
  const supabase = await createClient();
  const { error } = await supabase.rpc("correct_car_trip", {
    p_trip_id: Number(text(form, "trip_id")),
    p_start_odo: start,
    p_end_odo: reading(form, "end_odo"),
    p_purpose: text(form, "purpose"),
    p_client_id: text(form, "client_id") || null,
    p_reason: text(form, "reason"),
  });
  if (error) return { error: friendlyError(error) };
  refresh();
  return { message: "Trip fixed. The change log has both versions." };
}
