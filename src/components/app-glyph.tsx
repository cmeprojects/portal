// Staff Portal · © cmeproject. All rights reserved.
import { APP_ICONS } from "@/lib/feature-types";

const CAR = "M3 16v-4l2.5-5h13L21 12v4zM7.5 18.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4zM16.5 18.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4z";

// A Staff app icon's drawing (Cars, or a built feature's chosen icon).
export function AppGlyph({ icon, className = "size-9" }: { icon: string; className?: string }) {
  const path = icon === "car" ? CAR : (APP_ICONS[icon] ?? APP_ICONS.clipboard).path;
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden="true">
      <path d={path} />
    </svg>
  );
}

// The rounded, coloured square with the drawing, as on a phone's home screen.
export function AppSquare({ icon, colour, size = "size-[4.5rem]" }: { icon: string; colour: string; size?: string }) {
  return (
    <span className={`grid ${size} place-items-center rounded-[1.25rem] text-white shadow-md`} style={{ background: colour }}>
      <AppGlyph icon={icon} />
    </span>
  );
}
