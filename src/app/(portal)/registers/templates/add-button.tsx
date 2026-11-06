// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button } from "@/components/ui";
import { addFromTemplate } from "./actions";

export function AddTemplateButton({ templateKey, name }: { templateKey: string; name: string }) {
  const [state, action, pending] = useActionState(addFromTemplate, null);
  if (state?.message) return <p role="status" className="text-sm font-semibold text-good">✓ {state.message}</p>;
  return (
    <form action={action} className="flex flex-col items-end gap-1">
      <input type="hidden" name="key" value={templateKey} />
      <Button size="sm" disabled={pending} aria-label={`Add ${name}`}>
        {pending ? "Adding…" : "Add"}
      </Button>
      {state?.error ? <p className="text-xs text-danger">{state.error}</p> : null}
    </form>
  );
}
