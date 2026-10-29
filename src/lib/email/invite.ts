// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getBranding } from "@/lib/branding";
import { env } from "@/lib/env";
import { sendEmail } from "./send";
import { renderInvite } from "./templates";

const emailReady = () => Boolean(process.env.RESEND_API_KEY || process.env.MAILPIT_URL);

// Sends the welcome invite. With email set up, the portal sends its own
// branded welcome (logo, what happens next). Otherwise Supabase sends its
// invite email (set up from supabase/templates/invite.html).
export async function sendInvite(opts: { email: string; fullName: string; invitedBy: string; resend?: boolean }) {
  const admin = createAdminClient();
  if (!emailReady()) {
    const { error } = await admin.auth.admin.inviteUserByEmail(opts.email, {
      data: { full_name: opts.fullName },
      redirectTo: `${env.siteUrl}/welcome`,
    });
    return { error: error?.message ?? null };
  }

  // A first invite creates the account; a resend sends a fresh sign-in link.
  let link = await admin.auth.admin.generateLink({
    type: "invite",
    email: opts.email,
    options: { data: { full_name: opts.fullName }, redirectTo: `${env.siteUrl}/welcome` },
  });
  let type = "invite";
  if (link.error && opts.resend) {
    link = await admin.auth.admin.generateLink({ type: "magiclink", email: opts.email });
    type = "magiclink";
  }
  if (link.error || !link.data.properties?.hashed_token) return { error: link.error?.message ?? "No link" };

  const brand = await getBranding();
  const url = `${env.siteUrl}/auth/confirm?token_hash=${encodeURIComponent(link.data.properties.hashed_token)}&type=${type}&next=/welcome`;
  const logo = /^https?:\/\//.test(brand.logoUrl) ? brand.logoUrl : `${env.siteUrl}${brand.logoUrl}`;
  const { data: note } = await admin.from("app_settings").select("value").eq("key", "people.invite_message").maybeSingle();
  const msg = renderInvite({
    note: typeof note?.value === "string" ? note.value.trim() : "",
    recipientName: opts.fullName.split(" ")[0],
    invitedBy: opts.invitedBy,
    companyName: brand.companyName,
    logo,
    link: url,
    brand: brand.colorPrimary,
  });
  try {
    await sendEmail({ to: { email: opts.email, name: opts.fullName }, cc: [], ...msg });
    return { error: null };
  } catch (e) {
    return { error: e instanceof Error ? e.message : String(e) };
  }
}
