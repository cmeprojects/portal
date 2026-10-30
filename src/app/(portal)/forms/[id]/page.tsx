// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formsOn, loadForm } from "@/lib/forms";
import { getBranding } from "@/lib/branding";
import type { FormAnswers } from "@/lib/form-types";
import { Card, buttonClass } from "@/components/ui";
import { FormFiller } from "@/components/form-filler";

export async function generateMetadata({ params }: PageProps<"/forms/[id]">): Promise<Metadata> {
  const def = await loadForm((await params).id);
  return { title: def?.form.title ?? "Form" };
}

// cmeprojects: a form to fill in (from the bell, an email, the link or its QR code).
export default async function FillFormPage({ params }: PageProps<"/forms/[id]">) {
  const { profile, features } = await requireSession();
  if (!formsOn(features)) notFound();
  const def = await loadForm((await params).id);
  if (!def) notFound();
  const { form, questions } = def;
  const supabase = await createClient();
  const [{ data: canFill }, { data: canManage }, { data: done }, { data: draft }, { data: contact }, brand] = await Promise.all([
    supabase.rpc("can_fill_form", { p_form: form.id }),
    supabase.rpc("can_manage_form", { p_form: form.id }),
    supabase.from("form_completions").select("done_at").eq("form_id", form.id).eq("user_id", profile.id).maybeSingle(),
    supabase.from("form_responses").select("answers").eq("form_id", form.id).eq("user_id", profile.id).eq("status", "draft").maybeSingle(),
    supabase.rpc("form_contact", { p_form: form.id }).maybeSingle<{ name: string; email: string }>(),
    getBranding(),
  ]);
  const manageBar = canManage ? (
    <div className="flex flex-wrap gap-3 text-sm font-semibold print:hidden">
      <Link href={`/forms/${form.id}/edit`} className="text-brand underline">
        Edit
      </Link>
      <Link href={`/forms/${form.id}/replies`} className="text-brand underline">
        See replies
      </Link>
      <Link href="/forms" className="text-brand underline">
        All forms
      </Link>
    </div>
  ) : null;

  if (!canFill) {
    return (
      <div className="flex w-full max-w-2xl flex-col gap-4">
        {manageBar}
        <Card className="flex flex-col gap-2 p-6">
          <h1 className="heading-sm">{form.title}</h1>
          <p className="text-sm text-muted">
            {form.status === "draft" ? "This form hasn't been published yet." : "This form isn't taking replies any more."}
          </p>
          {canManage && form.status === "draft" ? (
            <Link href={`/forms/${form.id}/edit`} className={buttonClass("primary", "self-start")}>
              Edit and publish it
            </Link>
          ) : null}
        </Card>
      </div>
    );
  }

  return (
    <div className="flex w-full max-w-2xl flex-col gap-4">
      {manageBar}
      <Card className="p-5 sm:p-7">
        {done && !form.repeatable ? (
          <div className="flex flex-col gap-2">
            <h1 className="heading-sm">{form.title}</h1>
            <p className="text-sm text-good">
              You filled this in on{" "}
              {new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "long", year: "numeric" }).format(new Date(done.done_at))}. Thank you.
            </p>
          </div>
        ) : (
          <FormFiller
            form={form}
            questions={questions}
            brand={{ companyName: brand.companyName, logoUrl: brand.logoUrl }}
            contact={contact ?? null}
            userId={profile.id}
            mode="live"
            draft={(draft?.answers ?? undefined) as FormAnswers | undefined}
          />
        )}
      </Card>
    </div>
  );
}
