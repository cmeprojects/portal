// Staff Portal · © cmeproject. All rights reserved.
import type { Branding } from "@/lib/branding";

export function BrandMark({ brand, size = 40, onDark = false }: { brand: Branding; size?: number; onDark?: boolean }) {
  return (
    <div className="flex items-center gap-2.5">
      <span
        className="flex shrink-0 items-center justify-center rounded-xl bg-white"
        style={{ width: size, height: size }}
      >
        {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
        <img src={brand.logoMarkUrl} alt="" width={size * 0.7} height={size * 0.7} />
      </span>
      <span className="flex flex-col leading-tight">
        <span className={`text-base font-extrabold ${onDark ? "text-white" : "text-brand-dark"}`}>
          {brand.companyName}
        </span>
        <span className={`text-[13px] ${onDark ? "text-white/75" : "text-muted"}`}>{brand.portalName}</span>
      </span>
    </div>
  );
}
