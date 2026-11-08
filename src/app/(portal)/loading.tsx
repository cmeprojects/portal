// Staff Portal · © cmeproject. All rights reserved.

// Shown straight away while a page loads, so a tap never looks ignored.
// cmeprojects: grey shapes in the page's layout (title, number tiles, a list),
// gently pulsing, instead of a blank screen.
export default function Loading() {
  const block = "animate-pulse rounded-xl bg-line/60 motion-reduce:animate-none";
  return (
    <div role="status" aria-live="polite" className="flex flex-col gap-6">
      <span className="sr-only">Loading…</span>
      <div className="flex flex-col gap-2">
        <div className={`${block} h-8 w-48`} />
        <div className={`${block} h-4 w-72 max-w-full`} />
      </div>
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[0, 1, 2, 3].map((i) => (
          <div key={i} className="shadow-card flex h-24 flex-col justify-center gap-2 rounded-xl border border-line bg-surface px-4">
            <div className={`${block} h-3 w-20`} />
            <div className={`${block} h-6 w-12`} />
          </div>
        ))}
      </div>
      <div className="shadow-card flex flex-col gap-4 rounded-xl border border-line bg-surface p-5">
        <div className={`${block} h-4 w-40`} />
        {[0, 1, 2, 3, 4].map((i) => (
          <div key={i} className="flex items-center gap-4">
            <div className={`${block} h-4 flex-1`} />
            <div className={`${block} h-4 w-20`} />
          </div>
        ))}
      </div>
    </div>
  );
}
