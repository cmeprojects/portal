// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useRef, useState } from "react";
import { Button, Field, Notice, inputClass } from "@/components/ui";
import { savePin, unlockWithPin } from "../actions";

const KEYS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del"];

// A phone-style keypad; it unlocks as soon as the fourth number is tapped.
export function PinPad({ base }: { base: string }) {
  const [state, action, pending] = useActionState(unlockWithPin, null);
  const [pin, setPin] = useState("");
  const form = useRef<HTMLFormElement>(null);

  function press(k: string) {
    if (pending) return;
    if (k === "del") return setPin((p) => p.slice(0, -1));
    if (pin.length >= 4) return;
    const next = pin + k;
    setPin(next);
    if (next.length === 4) {
      // Let the fourth dot show before sending.
      window.setTimeout(() => {
        form.current?.requestSubmit();
        setPin("");
      }, 120);
    }
  }

  return (
    <form ref={form} action={action} className="flex flex-col items-center gap-5">
      <input type="hidden" name="pin" value={pin} />
      <input type="hidden" name="base" value={base} />
      <div className="flex gap-4" aria-label={`${pin.length} of 4 numbers entered`} role="status">
        {[0, 1, 2, 3].map((i) => (
          <span key={i} className={`size-4 rounded-full border-2 border-brand ${i < pin.length ? "bg-brand" : ""}`} />
        ))}
      </div>
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      {pending ? <p className="text-sm text-muted">Checking…</p> : null}
      <div className="grid grid-cols-3 gap-3">
        {KEYS.map((k, i) =>
          k === "" ? (
            <span key={i} />
          ) : (
            <button
              key={i}
              type="button"
              onClick={() => press(k)}
              aria-label={k === "del" ? "Delete" : k}
              className={`size-[4.5rem] rounded-full text-2xl font-semibold ${
                k === "del" ? "text-base text-brand" : "border border-line bg-surface text-ink active:bg-brand-soft"
              }`}
            >
              {k === "del" ? "Delete" : k}
            </button>
          ),
        )}
      </div>
    </form>
  );
}

export function SetPinForm({ base }: { base: string }) {
  const [state, action, pending] = useActionState(savePin, null);
  const pinInput = `${inputClass} h-14 text-center text-2xl tracking-[0.6em]`;
  return (
    <form action={action} className="flex flex-col gap-4">
      <input type="hidden" name="base" value={base} />
      {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      <Field label="New PIN (4 numbers)" htmlFor="pin">
        <input id="pin" name="pin" type="password" inputMode="numeric" pattern="\d{4}" maxLength={4} autoComplete="new-password" required className={pinInput} />
      </Field>
      <Field label="Type it again" htmlFor="pin2">
        <input id="pin2" name="pin2" type="password" inputMode="numeric" pattern="\d{4}" maxLength={4} autoComplete="new-password" required className={pinInput} />
      </Field>
      <Button className="min-h-14 text-lg" disabled={pending}>
        {pending ? "Saving…" : "Save PIN"}
      </Button>
    </form>
  );
}
