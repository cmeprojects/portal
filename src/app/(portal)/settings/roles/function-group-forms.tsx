// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { saveFunctionGroup } from "./actions";

type Group = { id: string; key: string; name: string; description: string; active: boolean };

// cmeprojects (function-based access, Stage 1): one function group, or a new one.
export function FunctionGroupForm({ group }: { group?: Group }) {
  const [state, action, pending] = useActionState(saveFunctionGroup, null);
  const { ref, dirty, markClean } = useDirty();
  useAfterSuccess(state, markClean);
  const idp = group?.id ?? "new";
  return (
    <form ref={ref} action={action} className="flex flex-col gap-2">
      {group ? <input type="hidden" name="id" value={group.id} /> : null}
      <div className="grid gap-2 sm:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
        <label htmlFor={`fg-name-${idp}`} className="flex flex-col gap-1 text-xs font-medium">
          Name
          <input id={`fg-name-${idp}`} name="name" required maxLength={80} defaultValue={group?.name ?? ""} className={inputClass} />
        </label>
        <label htmlFor={`fg-desc-${idp}`} className="flex flex-col gap-1 text-xs font-medium">
          Description
          <input id={`fg-desc-${idp}`} name="description" maxLength={500} defaultValue={group?.description ?? ""} className={inputClass} />
        </label>
      </div>
      <div className="flex flex-wrap items-center gap-3">
        {group ? (
          <label className="flex min-h-9 items-center gap-2 text-sm">
            <input type="checkbox" name="active" defaultChecked={group.active} className="h-4 w-4 accent-[var(--brand-primary)]" />
            In use
          </label>
        ) : null}
        <Button size="sm" variant={group ? "outline" : undefined} disabled={pending || (Boolean(group) && !dirty)}>
          {pending ? "Saving…" : group ? "Save" : "Add group"}
        </Button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
        {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
      </div>
    </form>
  );
}
