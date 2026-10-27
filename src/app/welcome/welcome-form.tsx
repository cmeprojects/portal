// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PasswordFields } from "@/components/password-fields";
import { finishWelcome } from "@/app/account/actions";

export function WelcomeForm({ name, email }: { name: string; email: string }) {
  const [state, action, pending] = useActionState(finishWelcome, null);

  return (
    <form action={action} className="flex flex-col gap-4">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Field label="Your name" htmlFor="full_name">
        <input id="full_name" name="full_name" defaultValue={name} autoComplete="name" required className={inputClass} />
      </Field>
      <Field label="Email" htmlFor="email">
        <input id="email" value={email} readOnly className={`${inputClass} border-line bg-page text-muted`} />
      </Field>
      <PasswordFields />
      <Button className="min-h-12 text-base" disabled={pending}>
        {pending ? "Saving…" : "Join the portal"}
      </Button>
      <Button variant="outline" name="skip_password" value="1" className="h-12" disabled={pending}>
        Skip the password: I&apos;ll use Google or email links
      </Button>
    </form>
  );
}
