// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import { Button, Notice } from "@/components/ui";
import { setClientTeams } from "./actions";

// cmeprojects: tick the team(s) that look after this client.
export function ClientTeamsForm({ clientId, name, teams, chosen }: { clientId: string; name: string; teams: { id: string; name: string }[]; chosen: string[] }) {
  const [state, action, pending] = useActionState(setClientTeams, null);
  return (
    <form action={action} className="flex flex-wrap items-center gap-x-4 gap-y-2 py-2.5">
      <input type="hidden" name="client_id" value={clientId} />
      <span className="w-full font-medium sm:w-48">{name}</span>
      <span className="flex flex-1 flex-wrap gap-x-4 gap-y-1">
        {teams.map((t) => (
          <label key={t.id} className="flex min-h-9 items-center gap-2 text-sm">
            <input type="checkbox" name="team_ids" value={t.id} defaultChecked={chosen.includes(t.id)} className="h-4 w-4 accent-[var(--brand-primary)]" />
            {t.name}
          </label>
        ))}
      </span>
      <Button size="sm" variant="outline" disabled={pending}>
        {pending ? "Saving…" : "Save"}
      </Button>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {state?.message ? <Notice tone="success">{state.message}</Notice> : null}
    </form>
  );
}
