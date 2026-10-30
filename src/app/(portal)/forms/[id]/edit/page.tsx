// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formsOn, loadForm } from "@/lib/forms";
import { getBranding } from "@/lib/branding";
import { FormEditor } from "./editor";

export const metadata: Metadata = { title: "Edit form" };

// Only the person who made the form, people they share it with, and the system admin.
export default async function EditFormPage({ params }: PageProps<"/forms/[id]/edit">) {
  const { profile, features } = await requireSession();
  if (!formsOn(features)) notFound();
  const def = await loadForm((await params).id);
  if (!def) notFound();
  const supabase = await createClient();
  const [{ data: canManage }, { count }, { data: maker }, brand] = await Promise.all([
    supabase.rpc("can_manage_form", { p_form: def.form.id }),
    supabase.from("form_responses").select("id", { count: "exact", head: true }).eq("form_id", def.form.id).eq("status", "submitted"),
    supabase.rpc("form_contact", { p_form: def.form.id }).maybeSingle<{ name: string; email: string }>(),
    getBranding(),
  ]);
  if (!canManage) notFound();
  return (
    <FormEditor
      key={def.form.id}
      form={def.form}
      questions={def.questions}
      brand={{ companyName: brand.companyName, logoUrl: brand.logoUrl }}
      me={maker ?? { name: profile.full_name || profile.email, email: profile.email }}
      userId={profile.id}
      replies={count ?? 0}
    />
  );
}
