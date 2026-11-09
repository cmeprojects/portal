// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import { photoLinks } from "@/lib/avatars";
import { ROLE_LABELS, type Role } from "@/lib/roles";

// cmeprojects: staff profiles (HR Pack). The directory card is visible to all
// staff; private details only come back for the person, people who manage
// staff, and the team leader (the database decides). Everything is read as
// the signed-in person, and works on copies without profiles (before update 55).
export type Directory = { preferred_name: string; department: string; work_phone: string; skills: string[] };
export type Private = {
  address: string;
  emergency_name: string;
  emergency_phone: string;
  start_date: string | null;
  employment_type: string;
  employee_id: string;
  availability: Record<string, string[]>;
};
export type PersonCard = {
  id: string;
  name: string;
  email: string;
  role: Role;
  roleLabel: string;
  jobTitle: string;
  active: boolean;
  photo?: string;
  teams: string[];
  directory: Directory;
  private: Private | null;
};

export const EMPTY_DIRECTORY: Directory = { preferred_name: "", department: "", work_phone: "", skills: [] };
export { EMPLOYMENT, DAYS, SHIFTS } from "@/lib/profiles-shared";

export async function loadPeople(ids?: string[]): Promise<PersonCard[]> {
  const supabase = await createClient();
  let q = supabase.from("profiles").select("id, full_name, email, role, active, avatar_ref, job_titles(name)").order("full_name");
  if (ids) q = q.in("id", ids);
  const { data: people, error } = await q;
  const rows = (error ? (await (ids ? supabase.from("profiles").select("id, full_name, email, role, active").in("id", ids) : supabase.from("profiles").select("id, full_name, email, role, active").order("full_name"))).data : people) ?? [];
  const list = rows as { id: string; full_name: string; email: string; role: Role; active: boolean; avatar_ref?: string | null; job_titles?: { name?: string } | null }[];
  const idsAll = list.map((p) => p.id);
  const [{ data: dir }, { data: priv }, { data: members }, { data: teams }, photos] = await Promise.all([
    supabase.from("staff_directory").select("*").in("user_id", idsAll),
    supabase.from("staff_private").select("*").in("user_id", idsAll),
    supabase.from("team_members").select("team_id, user_id").in("user_id", idsAll),
    supabase.from("teams").select("id, name"),
    photoLinks(list),
  ]);
  const dirOf = new Map((dir ?? []).map((d) => [d.user_id as string, d as Directory]));
  const privOf = new Map((priv ?? []).map((d) => [d.user_id as string, d as Private]));
  const teamName = new Map((teams ?? []).map((t) => [t.id as string, t.name as string]));
  return list.map((p) => ({
    id: p.id,
    name: p.full_name || p.email,
    email: p.email,
    role: p.role,
    roleLabel: ROLE_LABELS[p.role] ?? p.role,
    jobTitle: p.job_titles?.name || ROLE_LABELS[p.role] || "",
    active: p.active,
    photo: photos[p.id],
    teams: (members ?? []).filter((m) => m.user_id === p.id).map((m) => teamName.get(m.team_id) ?? "").filter(Boolean),
    directory: { ...EMPTY_DIRECTORY, ...(dirOf.get(p.id) ?? {}) },
    private: privOf.get(p.id) ?? null,
  }));
}

export async function loadPerson(id: string): Promise<PersonCard | null> {
  return (await loadPeople([id]))[0] ?? null;
}

// Whether this copy has profiles yet (live update 55).
export async function profilesReady(): Promise<boolean> {
  const { error } = await (await createClient()).from("staff_directory").select("user_id", { head: true, count: "exact" }).limit(1);
  return !error;
}
