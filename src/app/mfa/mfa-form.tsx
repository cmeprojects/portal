// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button, Field, Notice, inputClass } from "@/components/ui";

type Mode =
  | { kind: "loading" }
  | { kind: "enroll"; factorId: string; qr: string; secret: string }
  | { kind: "verify"; factorId: string }
  | { kind: "failed"; message: string };

export function MfaForm() {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>({ kind: "loading" });
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);
  const started = useRef(false);

  useEffect(() => {
    // Start set-up only once, even if React runs this effect twice.
    if (started.current) return;
    started.current = true;
    const supabase = createClient();
    (async () => {
      const { data, error } = await supabase.auth.mfa.listFactors();
      if (error) return setMode({ kind: "failed", message: "We couldn't load your two-factor settings. Refresh to try again." });

      const verified = data.totp[0];
      if (verified) return setMode({ kind: "verify", factorId: verified.id });

      // Clear any half-finished set-up, then start a fresh one.
      for (const f of data.all.filter((f) => f.status === "unverified")) {
        await supabase.auth.mfa.unenroll({ factorId: f.id });
      }
      const enrolled = await supabase.auth.mfa.enroll({ factorType: "totp" });
      if (enrolled.error) return setMode({ kind: "failed", message: "We couldn't start two-factor set-up. Refresh to try again." });
      setMode({
        kind: "enroll",
        factorId: enrolled.data.id,
        qr: enrolled.data.totp.qr_code,
        secret: enrolled.data.totp.secret,
      });
    })();
  }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (mode.kind !== "enroll" && mode.kind !== "verify") return;
    setBusy(true);
    setError("");
    const supabase = createClient();
    const { error } = await supabase.auth.mfa.challengeAndVerify({
      factorId: mode.factorId,
      code: code.replace(/\s/g, ""),
    });
    setBusy(false);
    if (error) {
      setError("That code didn't work. Codes change every 30 seconds, so use the newest one.");
      return;
    }
    router.replace("/");
    router.refresh();
  }

  if (mode.kind === "loading") return <p className="text-muted">Loading…</p>;
  if (mode.kind === "failed") return <Notice tone="error">{mode.message}</Notice>;

  return (
    <form onSubmit={submit} className="flex flex-col gap-5">
      {mode.kind === "enroll" ? (
        <>
          <ol className="flex list-decimal flex-col gap-2 pl-5 text-[15px] leading-relaxed">
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
              className="rounded-xl border border-line bg-white p-2"
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

      {error ? <Notice tone="error">{error}</Notice> : null}
      <Field
        label={mode.kind === "enroll" ? "3. Type the 6-digit code from the app" : "6-digit code from your authenticator app"}
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
          className={`${inputClass} h-14 border-2 border-brand text-2xl font-bold tracking-[0.3em]`}
        />
      </Field>
      <Button className="h-[52px] text-[17px]" disabled={busy}>
        {busy ? "Checking…" : mode.kind === "enroll" ? "Turn on and continue" : "Continue"}
      </Button>
    </form>
  );
}
