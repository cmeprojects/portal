// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button, Notice } from "@/components/ui";

// Lets someone whose role doesn't need two-factor login turn it off.
export function TurnOffTwoFactor({ factorIds }: { factorIds: string[] }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function turnOff() {
    if (!confirm("Turn off two-factor login for your account?")) return;
    setBusy(true);
    setError("");
    const supabase = createClient();
    for (const factorId of factorIds) {
      const { error } = await supabase.auth.mfa.unenroll({ factorId });
      if (error) {
        setBusy(false);
        setError("To turn it off, sign out and sign back in with your code first, then try again.");
        return;
      }
    }
    await supabase.auth.refreshSession();
    router.refresh();
  }

  return (
    <div className="flex flex-col gap-2">
      {error ? <Notice tone="error">{error}</Notice> : null}
      <Button type="button" variant="danger" className="self-start" disabled={busy} onClick={turnOff}>
        {busy ? "Turning off…" : "Turn off two-factor login"}
      </Button>
    </div>
  );
}
