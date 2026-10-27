// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useState } from "react";
import Link from "next/link";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { sendSignInLink, signInWithGoogle, signInWithPassword } from "./actions";

export function LoginForm({
  next,
  googleOn,
  linkOn,
  initialError,
}: {
  next: string;
  googleOn: boolean;
  linkOn: boolean;
  initialError?: string;
}) {
  const [email, setEmail] = useState("");
  const [pwState, pwAction, pwPending] = useActionState(signInWithPassword, null);
  const [linkState, linkAction, linkPending] = useActionState(sendSignInLink, null);
  const error = pwState?.error ?? linkState?.error ?? initialError;

  return (
    <div className="flex flex-col gap-4">
      {error ? <Notice tone="error">{error}</Notice> : null}
      {linkState?.message ? <Notice tone="success">{linkState.message}</Notice> : null}

      {googleOn ? (
        <>
          <form action={signInWithGoogle}>
            <input type="hidden" name="next" value={next} />
            <Button variant="outline" className="h-12 w-full text-base text-ink">
              <svg width="20" height="20" viewBox="0 0 48 48" aria-hidden="true">
                <path fill="#4285F4" d="M45 24.5c0-1.6-.1-3.1-.4-4.5H24v8.5h11.8c-.5 2.7-2.1 5-4.4 6.6v5.5h7.1c4.2-3.9 6.5-9.6 6.5-16.1z" />
                <path fill="#34A853" d="M24 46c5.9 0 10.9-2 14.5-5.4l-7.1-5.5c-2 1.3-4.5 2.1-7.4 2.1-5.7 0-10.5-3.8-12.2-9H4.5v5.7C8.1 41.1 15.5 46 24 46z" />
                <path fill="#FBBC05" d="M11.8 28.2c-.4-1.3-.7-2.7-.7-4.2s.3-2.9.7-4.2v-5.7H4.5C3 17.1 2 20.4 2 24s1 6.9 2.5 9.9l7.3-5.7z" />
                <path fill="#EA4335" d="M24 10.8c3.2 0 6.1 1.1 8.4 3.3l6.3-6.3C34.9 4.2 29.9 2 24 2 15.5 2 8.1 6.9 4.5 14.1l7.3 5.7c1.7-5.2 6.5-9 12.2-9z" />
              </svg>
              Continue with Google
            </Button>
          </form>
          <div className="flex items-center gap-3 text-sm text-muted">
            <span className="h-px flex-1 bg-line" />
            or
            <span className="h-px flex-1 bg-line" />
          </div>
        </>
      ) : null}

      <form action={pwAction} className="flex flex-col gap-4">
        <input type="hidden" name="next" value={next} />
        <Field label="Email" htmlFor="email">
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={inputClass}
          />
        </Field>
        <div className="flex flex-col gap-1.5">
          <div className="flex items-baseline justify-between">
            <label htmlFor="password" className="text-[15px] font-semibold">
              Password
            </label>
            <Link href="/forgot-password" className="text-sm font-semibold text-brand">
              Forgot password?
            </Link>
          </div>
          <input id="password" name="password" type="password" autoComplete="current-password" className={inputClass} />
        </div>
        <Button className="h-[52px] text-[17px]" disabled={pwPending}>
          {pwPending ? "Signing in…" : "Sign in"}
        </Button>
      </form>

      {linkOn ? (
        <form action={linkAction}>
          <input type="hidden" name="next" value={next} />
          <input type="hidden" name="email" value={email} />
          <Button variant="secondary" className="h-12 w-full text-base" disabled={linkPending}>
            {linkPending ? "Sending…" : "Email me a sign-in link instead"}
          </Button>
        </form>
      ) : null}
    </div>
  );
}
