// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState } from "react";
import Link from "next/link";
import { Button, Notice } from "@/components/ui";
import { useOneTimeLink } from "./actions";

export function OneTimeLinkForm({ tokenHash, type, next, label }: { tokenHash: string; type: string; next: string; label: string }) {
  const [state, action, pending] = useActionState(useOneTimeLink, null);
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="token_hash" value={tokenHash} />
      <input type="hidden" name="type" value={type} />
      <input type="hidden" name="next" value={next} />
      {state?.error ? (
        <Notice tone="error">
          {state.error}{" "}
          <Link href="/login?error=link" className="font-semibold underline">
            Get a new link
          </Link>
        </Notice>
      ) : null}
      <Button disabled={pending}>{pending ? "Opening…" : label}</Button>
    </form>
  );
}
