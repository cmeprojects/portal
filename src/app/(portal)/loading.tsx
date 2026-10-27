// Staff Portal · © cmeproject. All rights reserved.

// Shown straight away while a page loads, so a tap never looks ignored.
export default function Loading() {
  return (
    <div role="status" aria-live="polite" className="flex flex-col gap-4">
      <span className="sr-only">Loading…</span>
      <div className="h-8 w-56 animate-pulse rounded-full bg-line" />
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className="h-24 animate-pulse rounded-[20px] bg-white" />
        ))}
      </div>
      <div className="h-64 animate-pulse rounded-[20px] bg-white" />
    </div>
  );
}
