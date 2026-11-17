// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { useAfterSuccess } from "@/components/use-after-success";
import { useDirty } from "@/components/use-dirty";
import { saveFunctionGroup } from "./actions";

type Group = { id: string; key: string; name: string; description: string; active: boolean };
export type Part = { id: string; label: string; category: string };

// cmeprojects (function-based access, Stage 1): one function group, or a new one.
// Stage 4 (update 104): which parts of the portal belong to it (offered first
// on its screens; gives nobody access).
export function FunctionGroupForm({ group, parts, chosen }: { group?: Group; parts?: Part[] | null; chosen?: string[] }) {
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
      {group && parts ? (
        <fieldset className="flex flex-col gap-1.5">
          <legend className="text-xs font-medium">Parts of the portal this group looks after</legend>
          <p className="text-xs text-muted">Shown first when you set this group&apos;s access. Choosing a part here gives nobody access.</p>
          <input type="hidden" name="parts_shown" value="1" />
          <div className="grid gap-x-4 gap-y-1 sm:grid-cols-2">
            {parts.map((p) => (
              <label key={p.id} className="flex min-h-8 items-center gap-2 text-sm">
                <input type="checkbox" name="parts" value={p.id} defaultChecked={(chosen ?? []).includes(p.id)} className="h-4 w-4 accent-[var(--brand-primary)]" />
                {p.label}
              </label>
            ))}
          </div>
        </fieldset>
      ) : null}
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
