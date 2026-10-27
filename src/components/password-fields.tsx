// Staff Portal · © cmeproject. All rights reserved.
import { Field, inputClass } from "@/components/ui";

export function PasswordFields({ label = "Create a password" }: { label?: string }) {
  return (
    <>
      <Field label={label} htmlFor="password" hint="At least 10 characters. A short sentence works well.">
        <input id="password" name="password" type="password" autoComplete="new-password" minLength={10} className={inputClass} />
      </Field>
      <Field label="Type it again" htmlFor="confirm">
        <input id="confirm" name="confirm" type="password" autoComplete="new-password" minLength={10} className={inputClass} />
      </Field>
    </>
  );
}
