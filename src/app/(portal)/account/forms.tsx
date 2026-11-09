// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { useActionState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { PasswordFields } from "@/components/password-fields";
import { FileUpload } from "@/components/file-upload";
import { Avatar } from "@/components/avatar";
import { askConfirm } from "@/components/confirm";
import { toast } from "@/components/toast";
import { changePassword, removeMyPhoto, setMyPhoto, updateMyName } from "@/app/account/actions";

// cmeprojects: my profile photo, shown next to my name for signed-in staff.
export function PhotoForm({ userId, name, src }: { userId: string; name: string; src?: string }) {
  const router = useRouter();
  const [pending, start] = useTransition();
  const done = (r: { error?: string; message?: string }) => {
    toast(r.error ?? r.message ?? "", r.error ? "error" : "success");
    if (!r.error) router.refresh();
  };
  return (
    <div className="flex flex-col gap-3">
      <h2 className="heading-sm">Profile photo</h2>
      <div className="flex flex-wrap items-center gap-4">
        <Avatar name={name} src={src} size={72} className="bg-brand-soft text-brand" />
        <p className="min-w-48 flex-1 text-sm text-muted">A clear, recent photo of your face. Only signed-in staff see it, next to your name.</p>
      </div>
      <FileUpload
        id="photo"
        bucket="avatars"
        folder={userId}
        name="photo"
        accept="image/jpeg,image/png,image/webp"
        maxMb={5}
        onUploaded={(path) => start(async () => done(await setMyPhoto(`avatars/${path}`)))}
      />
      {src ? (
        <Button
          type="button"
          variant="outline"
          className="self-start"
          disabled={pending}
          onClick={() =>
            void askConfirm("Remove your photo? Your initials show instead.", { action: "Remove photo" }).then(
              (ok) => ok && start(async () => done(await removeMyPhoto())),
            )
          }
        >
          {pending ? "Saving…" : "Remove photo"}
        </Button>
      ) : null}
    </div>
  );
}

export function NameForm({ name }: { name: string }) {
  const [state, action, pending] = useActionState(updateMyName, null);
  const { ref: dirtyRef, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  return (
    <form ref={dirtyRef} action={action} className="flex flex-col gap-3">
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Field label="Your name" htmlFor="full_name">
        <input id="full_name" name="full_name" defaultValue={name} required className={inputClass} />
      </Field>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending || !dirty}>{pending ? "Saving…" : "Save name"}</Button>
    </form>
  );
}

export function PasswordForm() {
  const [state, action, pending] = useActionState(changePassword, null);
  return (
    <form action={action} className="flex flex-col gap-3">
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      <Field label="Current password" htmlFor="current-password" hint="Or a 6-digit code from your authenticator app, if you use one.">
        <input id="current-password" name="current" type="password" autoComplete="current-password" required className={inputClass} />
      </Field>
      <PasswordFields label="New password" />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Button variant="outline" className="self-start" disabled={pending}>{pending ? "Saving…" : "Save password"}</Button>
    </form>
  );
}
