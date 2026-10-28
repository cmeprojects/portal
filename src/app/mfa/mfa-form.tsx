// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button, Field, Notice, inputClass } from "@/components/ui";

export type MfaMethods = { app: boolean; sms: boolean };

type Mode =
  | { kind: "loading" }
  | { kind: "choose" }
  | { kind: "enroll-app"; factorId: string; qr: string; secret: string }
  | { kind: "enroll-phone" }
  | { kind: "verify-app"; factorId: string }
  // A text has been sent (or can be sent) for this phone factor.
  | { kind: "verify-phone"; factorId: string; challengeId: string | null; phone: string }
  | { kind: "failed"; message: string };

// Australian mobiles: 04xx xxx xxx → +614xxxxxxxx. Anything else must already
// start with + and the country code.
function toE164(input: string): string | null {
  const digits = input.replace(/[\s()-]/g, "");
  if (/^04\d{8}$/.test(digits)) return `+61${digits.slice(1)}`;
  if (/^\+\d{8,15}$/.test(digits)) return digits;
  return null;
}

export function MfaForm({ methods }: { methods: MfaMethods }) {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>({ kind: "loading" });
  const [code, setCode] = useState("");
  const [phone, setPhone] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);
  const started = useRef(false);

  async function startApp() {
    const supabase = createClient();
    const enrolled = await supabase.auth.mfa.enroll({ factorType: "totp" });
    if (enrolled.error) return setMode({ kind: "failed", message: "We couldn't start two-factor set-up. Refresh to try again." });
    setMode({ kind: "enroll-app", factorId: enrolled.data.id, qr: enrolled.data.totp.qr_code, secret: enrolled.data.totp.secret });
  }

  async function sendText(factorId: string, shownPhone: string) {
    setBusy(true);
    setError("");
    const { data, error } = await createClient().auth.mfa.challenge({ factorId });
    setBusy(false);
    if (error) {
      setError("We couldn't send the text. Check the number, or try again in a minute.");
      return;
    }
    setMode({ kind: "verify-phone", factorId, challengeId: data.id, phone: shownPhone });
  }

  useEffect(() => {
    // Start only once, even if React runs this effect twice.
    if (started.current) return;
    started.current = true;
    const supabase = createClient();
    (async () => {
      const { data, error } = await supabase.auth.mfa.listFactors();
      if (error) return setMode({ kind: "failed", message: "We couldn't load your two-factor settings. Refresh to try again." });

      const app = data.totp[0];
      const sms = data.phone?.[0];
      if (methods.app && app) return setMode({ kind: "verify-app", factorId: app.id });
      if (methods.sms && sms) return setMode({ kind: "verify-phone", factorId: sms.id, challengeId: null, phone: (sms as { phone?: string }).phone ?? "" });

      // Clear any half-finished set-up, then start a fresh one.
      for (const f of data.all.filter((f) => f.status === "unverified")) {
        await supabase.auth.mfa.unenroll({ factorId: f.id });
      }
      if (methods.app && methods.sms) return setMode({ kind: "choose" });
      if (methods.app) return startApp();
      if (methods.sms) return setMode({ kind: "enroll-phone" });
      setMode({ kind: "failed", message: "No two-factor method is switched on. Ask your system admin." });
    })();
  }, [methods.app, methods.sms]);

  async function addPhone(e: FormEvent) {
    e.preventDefault();
    const number = toE164(phone);
    if (!number) {
      setError("Enter a mobile number like 0412 345 678.");
      return;
    }
    setBusy(true);
    setError("");
    const enrolled = await createClient().auth.mfa.enroll({ factorType: "phone", phone: number });
    setBusy(false);
    if (enrolled.error) {
      setError("We couldn't use that number. Check it and try again.");
      return;
    }
    await sendText(enrolled.data.id, number);
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    const supabase = createClient();
    const clean = code.replace(/\s/g, "");
    let failed = false;
    if (mode.kind === "enroll-app" || mode.kind === "verify-app") {
      failed = Boolean((await supabase.auth.mfa.challengeAndVerify({ factorId: mode.factorId, code: clean })).error);
    } else if (mode.kind === "verify-phone" && mode.challengeId) {
      failed = Boolean((await supabase.auth.mfa.verify({ factorId: mode.factorId, challengeId: mode.challengeId, code: clean })).error);
    }
    setBusy(false);
    if (failed) {
      setError(
        mode.kind === "verify-phone"
          ? "That code didn't work. Use the newest text, or send a new one."
          : "That code didn't work. Codes change every 30 seconds, so use the newest one.",
      );
      return;
    }
    router.replace("/");
    router.refresh();
  }

  if (mode.kind === "loading") return <p className="text-muted">Loading…</p>;
  if (mode.kind === "failed") return <Notice tone="error">{mode.message}</Notice>;

  if (mode.kind === "choose") {
    return (
      <div className="flex flex-col gap-3">
        <p className="text-sm font-semibold">How would you like to get your codes?</p>
        <Button className="min-h-12 text-base" onClick={() => startApp()}>
          Authenticator app (recommended)
        </Button>
        <Button variant="outline" className="min-h-12 text-base" onClick={() => setMode({ kind: "enroll-phone" })}>
          Text message to my mobile
        </Button>
      </div>
    );
  }

  if (mode.kind === "enroll-phone") {
    return (
      <form onSubmit={addPhone} className="flex flex-col gap-5">
        {error ? <Notice tone="error">{error}</Notice> : null}
        <Field label="Your mobile number" htmlFor="phone" hint="We'll text you a code each time you sign in.">
          <input
            id="phone"
            type="tel"
            inputMode="tel"
            autoComplete="tel"
            required
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="0412 345 678"
            className={`${inputClass} h-14 text-lg`}
          />
        </Field>
        <Button className="min-h-12 text-base" disabled={busy}>
          {busy ? "Sending…" : "Text me a code"}
        </Button>
        {methods.app ? (
          <Button type="button" variant="outline" onClick={() => startApp()}>
            Use an authenticator app instead
          </Button>
        ) : null}
      </form>
    );
  }

  if (mode.kind === "verify-phone" && !mode.challengeId) {
    return (
      <div className="flex flex-col gap-4">
        {error ? <Notice tone="error">{error}</Notice> : null}
        <p className="text-sm">We&apos;ll text a code to your mobile{mode.phone ? ` ending in ${mode.phone.slice(-3)}` : ""}.</p>
        <Button className="min-h-12 text-base" disabled={busy} onClick={() => sendText(mode.factorId, mode.phone)}>
          {busy ? "Sending…" : "Text me a code"}
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={submit} className="flex flex-col gap-5">
      {mode.kind === "enroll-app" ? (
        <>
          <ol className="flex list-decimal flex-col gap-2 pl-5 text-sm leading-relaxed">
            <li>Open an authenticator app (Google Authenticator, Microsoft Authenticator or 1Password).</li>
            <li>Scan this code, or copy the set-up key into the app.</li>
          </ol>
          <div className="flex flex-wrap items-center gap-4">
            {/* eslint-disable-next-line @next/next/no-img-element -- QR code is generated per person */}
            <img
              src={mode.qr.startsWith("data:") ? mode.qr : `data:image/svg+xml;utf-8,${encodeURIComponent(mode.qr)}`}
              alt="QR code for your authenticator app"
              width={160}
              height={160}
              className="rounded-md border border-line bg-surface p-2"
            />
            <Button
              type="button"
              variant="outline"
              onClick={async () => {
                await navigator.clipboard.writeText(mode.secret);
                setCopied(true);
              }}
            >
              {copied ? "Copied" : "Copy set-up key"}
            </Button>
          </div>
        </>
      ) : null}

      {mode.kind === "verify-phone" ? (
        <p className="text-sm">We&apos;ve texted a code to your mobile{mode.phone ? ` ending in ${mode.phone.slice(-3)}` : ""}.</p>
      ) : null}
      {error ? <Notice tone="error">{error}</Notice> : null}
      <Field
        label={
          mode.kind === "enroll-app"
            ? "3. Type the 6-digit code from the app"
            : mode.kind === "verify-phone"
              ? "6-digit code from the text"
              : "6-digit code from your authenticator app"
        }
        htmlFor="code"
      >
        <input
          id="code"
          inputMode="numeric"
          autoComplete="one-time-code"
          pattern="[0-9 ]{6,7}"
          required
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className={`${inputClass} h-14 border-2 border-brand text-2xl font-semibold tracking-[0.3em]`}
        />
      </Field>
      <Button className="min-h-12 text-base" disabled={busy}>
        {busy ? "Checking…" : mode.kind === "enroll-app" ? "Turn on and continue" : "Continue"}
      </Button>
      {mode.kind === "verify-phone" ? (
        <Button type="button" variant="outline" disabled={busy} onClick={() => sendText(mode.factorId, mode.phone)}>
          Send a new code
        </Button>
      ) : null}
    </form>
  );
}
