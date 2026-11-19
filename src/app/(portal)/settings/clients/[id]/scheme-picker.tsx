// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { setClientScheme } from "./actions";

// cmeprojects: choose who funds the client, right in the To check list.
export function SchemePicker({ clientId, schemes }: { clientId: string; schemes: [string, string][] }) {
  const [state, action, pending] = useActionState(setClientScheme, null);
  return (
    <form action={action} className="flex flex-wrap items-center gap-2">
      <input type="hidden" name="client_id" value={clientId} />
      <select name="scheme" required defaultValue="" aria-label="Funded by" className={`${inputClass} h-8 w-48`}>
        <option value="" disabled>
          Choose
        </option>
        {schemes.map(([v, l]) => (
          <option key={v} value={v}>
            {l}
          </option>
        ))}
      </select>
      <Button size="sm" disabled={pending}>
        {pending ? "Saving…" : "Save"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
    </form>
  );
}
