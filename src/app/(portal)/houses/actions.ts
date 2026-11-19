// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { canDo } from "@/lib/module-access";
import { createClient } from "@/lib/supabase/server";
import { friendlyError } from "@/lib/db-error";
import type { FormState } from "@/lib/form";
import { checkAuPhone, checkFullAddress } from "@/lib/validate";
import { HOUSE_KINDS } from "@/lib/houses";

// cmeprojects (update 150): SIL houses. Only while the switch is on; the
// database checks who may change houses and residents (Houses: change).
const isId = (v: string) => /^[0-9a-f-]{36}$/.test(v);
const isDate = (v: string) => /^\d{4}-\d{2}-\d{2}$/.test(v);
async function requireHouses() {
  const session = await requireSession();
  if (session.live.sil_houses !== true) throw new Error("SIL houses is switched off.");
  if (!(await canDo("clients.houses", "edit"))) throw new Error("You can't change houses.");
  return session;
}
const refresh = (id?: string) => {
  revalidatePath("/houses");
  if (id) revalidatePath(`/houses/${id}`);
};

export async function saveHouse(_: FormState, form: FormData): Promise<FormState> {
  await requireHouses();
  const id = String(form.get("id") ?? "");
  const name = String(form.get("name") ?? "").trim().slice(0, 80);
  if (!name) return { error: "Enter the house's name (for example 4 Oak St, or Oak House)." };
  const kind = String(form.get("kind") ?? "sil");
  const address = checkFullAddress(String(form.get("address") ?? ""));
  if (!address.ok) return { error: address.error };
  const phone = checkAuPhone(String(form.get("phone") ?? ""));
  if (!phone.ok) return { error: phone.error };
  const bedsRaw = String(form.get("beds") ?? "").trim();
  const beds = bedsRaw ? Number(bedsRaw) : null;
  if (beds !== null && (!Number.isInteger(beds) || beds < 1 || beds > 30)) return { error: "Beds is a number from 1 to 30." };
  const manager = String(form.get("manager_id") ?? "");
  const team = String(form.get("team_id") ?? "");
  const values = {
    name,
    kind: HOUSE_KINDS.some(([k]) => k === kind) ? kind : "sil",
    address: address.value,
    phone: phone.value,
    beds,
    manager_id: isId(manager) ? manager : null,
    team_id: isId(team) ? team : null,
    staff_notes: String(form.get("staff_notes") ?? "").trim().slice(0, 4000),
  };
  const supabase = await createClient();
  if (id) {
    if (!isId(id)) return { error: "That didn't save. Please reload the page." };
    const { error } = await supabase.from("sil_houses").update(values).eq("id", id);
    if (error) return { error: error.code === "23505" ? "Another open house has that name." : friendlyError(error) };
    refresh(id);
    return { message: "Saved." };
  }
  const { data, error } = await supabase.from("sil_houses").insert(values).select("id").single();
  if (error || !data) return { error: error?.code === "23505" ? "Another open house has that name." : friendlyError(error) };
  refresh(data.id);
  return { message: `${name} added.`, spotlight: data.id };
}

// Close or reopen a house (it needs no residents to close).
export async function setHouseActive(_: FormState, form: FormData): Promise<FormState> {
  await requireHouses();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const active = form.get("active") === "1";
  const { error } = await (await createClient()).from("sil_houses").update({ active }).eq("id", id);
  if (error) return { error: error.code === "23505" ? "Another open house has that name." : friendlyError(error) };
  refresh(id);
  return { message: active ? "Reopened." : "Closed." };
}

export async function moveIn(_: FormState, form: FormData): Promise<FormState> {
  await requireHouses();
  const house = String(form.get("house_id") ?? "");
  const client = String(form.get("client_id") ?? "");
  const date = String(form.get("moved_in") ?? "");
  if (!isId(house)) return { error: "That didn't save. Please reload the page." };
  if (!isId(client)) return { error: "Choose who is moving in." };
  if (!isDate(date)) return { error: "Choose the move-in date." };
  const { error } = await (await createClient())
    .from("sil_house_residents")
    .insert({ house_id: house, client_id: client, moved_in: date, room: String(form.get("room") ?? "").trim().slice(0, 40), move_reason: String(form.get("move_reason") ?? "").trim().slice(0, 500) });
  if (error) return { error: friendlyError(error) };
  refresh(house);
  revalidatePath(`/settings/clients/${client}`);
  return { message: "Moved in." };
}

export async function moveOut(_: FormState, form: FormData): Promise<FormState> {
  await requireHouses();
  const id = String(form.get("id") ?? "");
  const date = String(form.get("moved_out") ?? "");
  const reason = String(form.get("move_reason") ?? "").trim().slice(0, 500);
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  if (!isDate(date)) return { error: "Choose the move-out date." };
  if (!reason) return { error: "Say why they're moving out (for example moved to another house, hospital, family)." };
  const { data, error } = await (await createClient()).from("sil_house_residents").update({ moved_out: date, move_reason: reason }).eq("id", id).select("house_id, client_id").maybeSingle();
  if (error) return { error: error.code === "23514" ? "The move-out can't be before the move-in." : friendlyError(error) };
  refresh(data?.house_id);
  if (data) revalidatePath(`/settings/clients/${data.client_id}`);
  return { message: "Moved out." };
}

export async function setRoom(_: FormState, form: FormData): Promise<FormState> {
  await requireHouses();
  const id = String(form.get("id") ?? "");
  if (!isId(id)) return { error: "That didn't save. Please reload the page." };
  const { data, error } = await (await createClient()).from("sil_house_residents").update({ room: String(form.get("room") ?? "").trim().slice(0, 40) }).eq("id", id).select("house_id").maybeSingle();
  if (error) return { error: friendlyError(error) };
  refresh(data?.house_id);
  return { message: "Saved." };
}
