// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: a person's photo, or their initials when there isn't one.
export function initialsOf(name: string) {
  return name
    .split(/[\s@.]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]!.toUpperCase())
    .join("");
}

export function Avatar({ name, src, size = 40, className = "" }: { name: string; src?: string; size?: number; className?: string }) {
  const box = { width: size, height: size };
  if (src) {
    // eslint-disable-next-line @next/next/no-img-element -- short-lived private links, not suited to image optimisation
    return <img src={src} alt="" style={box} className={`shrink-0 rounded-full object-cover ${className}`} />;
  }
  return (
    <span aria-hidden="true" style={{ ...box, fontSize: Math.round(size * 0.34) }} className={`flex shrink-0 items-center justify-center rounded-full font-semibold ${className}`}>
      {initialsOf(name)}
    </span>
  );
}
