// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useActionState, useRef, useState } from "react";
import { Button, Notice, inputClass } from "@/components/ui";
import { addSignature } from "./actions";

const KIND_LABEL: Record<string, string> = {
  worker_in: "Clock-in signature (you)",
  worker_out: "Clock-out signature (you)",
  client: "Client signature",
  representative: "Client representative signature",
};

// cmeprojects (update 128): sign with a finger, mouse or pen. Saved as a small
// picture on the shift; a wrong one is voided by the roster team, never replaced.
export function SignaturePad({ shiftId, kind, defaultName = "" }: { shiftId: string; kind: string; defaultName?: string }) {
  const [state, action, pending] = useActionState(addSignature, null);
  const canvas = useRef<HTMLCanvasElement>(null);
  const drawing = useRef(false);
  const [data, setData] = useState("");
  const point = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const c = canvas.current!;
    const r = c.getBoundingClientRect();
    return [((e.clientX - r.left) * c.width) / r.width, ((e.clientY - r.top) * c.height) / r.height] as const;
  };
  const down = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const ctx = canvas.current!.getContext("2d")!;
    drawing.current = true;
    canvas.current!.setPointerCapture(e.pointerId);
    ctx.lineWidth = 2.5;
    ctx.lineCap = "round";
    ctx.strokeStyle = "#0f1f3d";
    ctx.beginPath();
    ctx.moveTo(...point(e));
  };
  const move = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!drawing.current) return;
    const ctx = canvas.current!.getContext("2d")!;
    ctx.lineTo(...point(e));
    ctx.stroke();
  };
  const up = () => {
    if (!drawing.current) return;
    drawing.current = false;
    setData(canvas.current!.toDataURL("image/png"));
  };
  const clear = () => {
    const c = canvas.current!;
    c.getContext("2d")!.clearRect(0, 0, c.width, c.height);
    setData("");
  };
  if (state?.message) return <Notice tone="success">{state.message}</Notice>;
  return (
    <form action={action} className="flex flex-col gap-2">
      <input type="hidden" name="shift_id" value={shiftId} />
      <input type="hidden" name="kind" value={kind} />
      <input type="hidden" name="signature" value={data} />
      <p className="text-xs font-medium">{KIND_LABEL[kind] ?? "Signature"}</p>
      <canvas
        ref={canvas}
        width={480}
        height={160}
        onPointerDown={down}
        onPointerMove={move}
        onPointerUp={up}
        onPointerLeave={up}
        className="h-32 w-full max-w-md touch-none rounded-md border border-line bg-white"
        aria-label="Sign here"
      />
      <div className="grid max-w-md gap-2 sm:grid-cols-2">
        <input name="signer_name" required maxLength={100} defaultValue={defaultName} placeholder="Name of the person signing" className={inputClass} />
        {kind === "representative" ? <input name="signer_role" maxLength={60} placeholder="Relationship (e.g. daughter)" className={inputClass} /> : null}
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <Button size="sm" disabled={pending || !data}>
          {pending ? "Saving…" : "Save signature"}
        </Button>
        <button type="button" onClick={clear} className="text-xs font-semibold text-brand underline">
          Clear
        </button>
        {state?.error ? <Notice tone="error">{state.error}</Notice> : null}
      </div>
    </form>
  );
}
