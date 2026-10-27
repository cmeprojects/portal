// Staff Portal · © cmeproject. All rights reserved.
import type { Branding } from "@/lib/branding";

// Only on paper: the company's logo and name, what this is, and when it was printed.
export function PrintHeader({ brand, title, subtitle, printedAt }: { brand: Branding; title: string; subtitle: string; printedAt: string }) {
  return (
    <div className="hidden items-center gap-4 border-b-2 border-black pb-3 print:flex">
      {/* eslint-disable-next-line @next/next/no-img-element -- logo address is set per company */}
      <img src={brand.logoUrl} alt="" className="h-16 w-auto object-contain" />
      <div className="flex-1">
        <p className="text-lg font-semibold">{brand.companyName}</p>
        <p className="text-sm">{title}</p>
        <p className="text-xs">{subtitle}</p>
      </div>
      <p className="text-right text-xs">Printed {printedAt}</p>
    </div>
  );
}
