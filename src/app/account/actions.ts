// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { sendPasswordReset } from "@/lib/email/password-reset";
import { EMAIL, text, type FormState } from "@/lib/form";

const MIN_PASSWORD = 10;

async function setPassword(supabase: Awaited<ReturnType<typeof createClient>>, form: FormData): Promise<string | null> {
  const password = String(form.get("password") ?? "");
  const confirm = String(form.get("confirm") ?? "");
  if (password.length < MIN_PASSWORD) return `Use at least ${MIN_PASSWORD} characters.`;
  if (password !== confirm) return "The two passwords don't match.";
  const { error } = await supabase.auth.updateUser({ password });
  if (error) {
    return error.code === "same_password"
      ? "That's your current password. Choose a new one."
      : "We couldn't save that password. Try a longer or less common one.";
  }
  return null;
}

// Welcome page after accepting an invite: confirm name, create a password.
export async function finishWelcome(_: FormState, form: FormData): Promise<FormState> {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");

  const fullName = text(form, "full_name");
  if (!fullName) return { error: "Tell us your name." };

  if (form.get("skip_password") !== "1") {
    const problem = await setPassword(supabase, form);
    if (problem) return { error: problem };
  }

  const { error } = await supabase.from("profiles").update({ full_name: fullName }).eq("id", userId);
  if (error) return { error: "We couldn't save your name. Please try again." };
  // Lets the staff admins know they've joined (once).
  await supabase.rpc("mark_joined");
  redirect("/onboarding");
}

export async function changePassword(_: FormState, form: FormData): Promise<FormState> {
  const supabase = await createClient();
  const problem = await setPassword(supabase, form);
  if (problem) return { error: problem };
  return { message: "Password saved." };
}

export async function updateMyName(_: FormState, form: FormData): Promise<FormState> {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const fullName = text(form, "full_name");
  if (!fullName) return { error: "Tell us your name." };
  const { error } = await supabase.from("profiles").update({ full_name: fullName }).eq("id", claims?.claims?.sub ?? "");
  if (error) return { error: "We couldn't save your name." };
  revalidatePath("/", "layout");
  return { message: "Name saved." };
}

export async function requestPasswordReset(_: FormState, form: FormData): Promise<FormState> {
  const email = text(form, "email").toLowerCase();
  if (!EMAIL.test(email)) return { error: "Enter the email you sign in with." };
  // Branded email through Resend once it's set up; Supabase's email until then.
  await sendPasswordReset(email);
  return { message: `If ${email} has an account, we've emailed a link to set a new password. Check your junk folder too.` };
}
