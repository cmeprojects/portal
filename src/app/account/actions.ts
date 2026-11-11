// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { requireSession } from "@/lib/session";
import { confirmIdentity } from "@/lib/reauth";
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

  // cmeprojects: the name is only set here when the office left it blank.
  const { data: current } = await supabase.from("profiles").select("full_name").eq("id", userId).maybeSingle();
  const blank = !current?.full_name?.trim();
  const fullName = blank ? text(form, "full_name") : "";
  if (blank && !fullName) return { error: "Tell us your name." };

  if (form.get("skip_password") !== "1") {
    const problem = await setPassword(supabase, form);
    if (problem) return { error: problem };
  }

  if (blank) {
    const { error } = await supabase.from("profiles").update({ full_name: fullName }).eq("id", userId);
    if (error) return { error: "We couldn't save your name. Please try again." };
  }
  // Lets the staff admins know they've joined (once).
  await supabase.rpc("mark_joined");
  // cmeprojects: account set up. Sign out here and ask them to sign in with
  // their new password (or Google or an email link), then on to onboarding.
  await supabase.auth.signOut({ scope: "local" });
  redirect(`/login?ready=1&next=${encodeURIComponent("/onboarding")}`);
}

export async function changePassword(_: FormState, form: FormData): Promise<FormState> {
  // cmeprojects: your current password (or an authenticator code) first.
  const check = await confirmIdentity(String(form.get("current") ?? ""));
  if (!check.ok) return { error: check.error };
  const supabase = await createClient();
  const problem = await setPassword(supabase, form);
  if (problem) return { error: problem };
  return { message: "Password saved." };
}

// cmeprojects: only the system admin changes their own name here; everyone
// else's name is set by the office (the database enforces it too).
export async function updateMyName(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  if (profile.role !== "system_admin") return { error: "Your name is set by the office. Ask your manager or the system admin to change it." };
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");
  const fullName = text(form, "full_name");
  if (!fullName) return { error: "Tell us your name." };
  const { error } = await supabase.from("profiles").update({ full_name: fullName }).eq("id", userId);
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

// After a password reset link (Forgot password): they've proved it's them by
// email, so no current password is asked for.
export async function setNewPasswordAfterReset(_: FormState, form: FormData): Promise<FormState> {
  const supabase = await createClient();
  const problem = await setPassword(supabase, form);
  if (problem) return { error: problem };
  return { message: "Password saved." };
}

// cmeprojects: my profile photo. The database checks the file is in my own folder.
export async function setMyPhoto(ref: string): Promise<{ error?: string; message?: string }> {
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_my_avatar", { p_ref: ref });
  if (error) return { error: error.code === "P0001" ? error.message : "That photo didn't save. Please try again." };
  revalidatePath("/", "layout");
  return { message: "Photo saved." };
}

export async function removeMyPhoto(): Promise<{ error?: string; message?: string }> {
  const supabase = await createClient();
  const { data: claims } = await supabase.auth.getClaims();
  const userId = claims?.claims?.sub;
  if (!userId) redirect("/login");
  const { error } = await supabase.rpc("remove_avatar", { p_user: userId });
  if (error) return { error: "That didn't work. Please try again." };
  revalidatePath("/", "layout");
  return { message: "Photo removed." };
}
