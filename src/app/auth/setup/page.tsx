// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { getBranding } from "@/lib/branding";
import { AuthShell } from "@/components/auth-shell";
import { Notice } from "@/components/ui";
import { OneTimeLinkForm } from "./form";

export const metadata: Metadata = { title: "Set up your account" };

const COPY: Record<string, { title: string; text: string; button: string }> = {
  invite: { title: "Set up your account", text: "You've been invited to the staff portal. Press the button to choose your password and get started.", button: "Set up my account" },
  recovery: { title: "Set a new password", text: "Press the button to choose a new password.", button: "Set a new password" },
  magiclink: { title: "Sign in", text: "Press the button to sign in.", button: "Sign in" },
};

// cmeprojects: where links from emails open. The one-time link is only used
// when the person presses the button, so email scanners can't spend it.
export default async function OneTimeLinkPage({ searchParams }: PageProps<"/auth/setup">) {
  const sp = await searchParams;
  const tokenHash = typeof sp.token_hash === "string" ? sp.token_hash : "";
  const type = typeof sp.type === "string" ? sp.type : "";
  const next = typeof sp.next === "string" ? sp.next : "/";
  // A resent invite for someone who opened the first one is a sign-in link to /welcome.
  const copy = next === "/welcome" ? COPY.invite : (COPY[type] ?? COPY.magiclink);
  const brand = await getBranding();
  return (
    <AuthShell brand={brand}>
      <div className="flex flex-col gap-1">
        <h1 className="heading">{copy.title}</h1>
        <p className="text-sm text-muted">{copy.text}</p>
      </div>
      {tokenHash && type ? (
        <OneTimeLinkForm tokenHash={tokenHash} type={type} next={next} label={copy.button} />
      ) : (
        <Notice tone="error">
          This link isn&apos;t complete. Open it again from the email, or{" "}
          <Link href="/login?error=link" className="font-semibold underline">
            ask for a new one
          </Link>
          .
        </Notice>
      )}
      <p className="text-center text-xs text-muted">This link works once. If it has expired, ask your manager to resend your invite.</p>
    </AuthShell>
  );
}
