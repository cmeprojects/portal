// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import Link from "next/link";
import { Button, Notice, buttonClass } from "@/components/ui";
import { PasswordFields } from "@/components/password-fields";
import { changePassword } from "@/app/account/actions";

export function SetPasswordForm() {
  const [state, action, pending] = useActionState(changePassword, null);
  if (state?.message) {
    return (
      <div className="flex flex-col gap-4">
        <Notice tone="success">Your new password is saved.</Notice>
        <Link href="/" className={buttonClass("primary")}>
          Go to the portal
        </Link>
      </div>
    );
  }
  return (
    <form action={action} className="flex flex-col gap-4">
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <PasswordFields label="New password" />
      <Button className="min-h-12 text-base" disabled={pending}>
        {pending ? "Saving…" : "Save new password"}
      </Button>
    </form>
  );
}
