// Staff Portal · © cmeproject. All rights reserved.
import type { Branding } from "@/lib/branding";

// The company's small logo with its name, for the sidebar.
export function BrandMark({ brand }: { brand: Branding }) {
  return (
    <div className="flex min-w-0 items-center gap-2.5">
      <span className="flex size-10 shrink-0 items-center justify-center rounded-md bg-white p-1">
        {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
        <img src={brand.logoMarkUrl} alt="" className="max-h-full max-w-full object-contain" />
      </span>
      <span className="min-w-0 leading-tight">
        <span className="block font-display text-sm leading-tight font-semibold tracking-wider text-balance text-side-fg uppercase">{brand.companyName}</span>
        <span className="block truncate font-display text-[11px] font-light tracking-[0.25em] text-side-muted uppercase">{brand.portalName}</span>
      </span>
    </div>
  );
}
