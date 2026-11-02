// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice } from "@/components/ui";
import { signOutOtherDevices } from "./device-actions";

// cmeprojects: for a lost phone or a shared computer you forgot to sign out of.
export function OtherDevices() {
  const [state, action, pending] = useActionState(signOutOtherDevices, null);
  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (!confirm("Sign out every other phone and computer? This device stays signed in.")) e.preventDefault();
      }}
      className="flex flex-col gap-3"
    >
      <h2 className="heading-sm">Other devices</h2>
      <p className="text-sm text-muted">
        Lost a phone, or signed in on a computer that isn&apos;t yours? Sign out everywhere else. It takes effect within a minute.
      </p>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending}>
        {pending ? "Signing out…" : "Sign out my other devices"}
      </Button>
    </form>
  );
}
