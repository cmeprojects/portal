// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (owner, 19 Nov 2026): how a mandatory field is shown. A red star
// means it must be filled to save; the amber tag means it can wait, but the
// client can't have services (or be rostered) until it's filled.
export function Req() {
  return (
    <>
      <span aria-hidden="true" className="ml-0.5 font-bold text-danger">
        *
      </span>
      <span className="sr-only"> (required)</span>
    </>
  );
}

export function NeededTag() {
  return <span className="ml-1.5 rounded-full bg-warn-soft px-1.5 py-0.5 text-[10px] font-semibold text-ink">Needed before services start</span>;
}

export function RequiredLegend() {
  return (
    <p className="text-xs text-muted">
      <span className="font-bold text-danger">*</span> Required to save. <span className="rounded-full bg-warn-soft px-1.5 py-0.5 text-[10px] font-semibold text-ink">Needed before services start</span> can be left for now, but they can&apos;t be rostered until it&apos;s filled.
    </p>
  );
}
