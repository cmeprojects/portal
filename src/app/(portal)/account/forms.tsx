// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PasswordFields } from "@/components/password-fields";
import { changePassword, updateMyName } from "@/app/account/actions";

export function NameForm({ name }: { name: string }) {
  const [state, action, pending] = useActionState(updateMyName, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Field label="Your name" htmlFor="full_name">
        <input id="full_name" name="full_name" defaultValue={name} required className={inputClass} />
      </Field>
      <Button variant="outline" className="self-start" disabled={pending}>Save name</Button>
    </form>
  );
}

export function PasswordForm() {
  const [state, action, pending] = useActionState(changePassword, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <PasswordFields label="New password" />
      <Button variant="outline" className="self-start" disabled={pending}>Save password</Button>
    </form>
  );
}
