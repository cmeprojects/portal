// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui";
import { confirmSubmit } from "@/components/confirm";
import { toast } from "@/components/toast";
import { removeAccess } from "./actions";

export function RemoveAccessButton({ id, name, what, passedOn }: { id: string; name: string; what: string; passedOn: number }) {
  const [error, setError] = useState("");
  const [pending, start] = useTransition();
  // The row disappears once removed, so the confirmation is a toast (shown
  // straight from the result, before the row goes).
  const run = (form: FormData) =>
    start(async () => {
      const r = await removeAccess(null, form);
      if (r?.error) setError(r.error);
      else if (r?.message) toast(r.message);
    });
  return (
    <form
      action={run}
      onSubmit={confirmSubmit(
        `Remove ${name}'s ${what} access? It stops straight away${passedOn ? `, and so does the access they passed on to ${passedOn} ${passedOn === 1 ? "person" : "people"}` : ""}. It stays in the history.`,
        { action: "Remove access" },
      )}
      className="flex flex-col items-end gap-1"
    >
      <input type="hidden" name="id" value={id} />
      <Button variant="outline" size="sm" disabled={pending}>
        {pending ? "Removing…" : "Remove"}
      </Button>
      {error ? <span className="text-xs text-danger">{error}</span> : null}
    </form>
  );
}
