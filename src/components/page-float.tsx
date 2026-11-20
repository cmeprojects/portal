// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";
import { ArrowUp, List, LogOut, Pencil } from "lucide-react";
import { FloatIcon } from "@/components/page-save";

// cmeprojects (owner, 20 Nov 2026): the floating icons used across the portal
// (named on hover): back to the list, edit, exit, and back to the top once the
// page has scrolled.
export function PageFloat({ list, edit, exit }: { list?: { href: string; label: string }; edit?: { href: string; label: string }; exit?: { href: string; label: string } }) {
  const [y, setY] = useState(0);
  useEffect(() => {
    const onScroll = () => setY(window.scrollY);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);
  if (!list && !edit && !exit && y <= 400) return null;
  return (
    <div className="fixed right-4 bottom-24 z-30 flex flex-col items-end gap-2 md:right-8 print:hidden">
      {list ? <FloatIcon href={list.href} label={list.label} icon={<List aria-hidden="true" className="size-4" />} /> : null}
      {edit ? <FloatIcon href={edit.href} label={edit.label} icon={<Pencil aria-hidden="true" className="size-4" />} /> : null}
      {exit ? <FloatIcon href={exit.href} label={exit.label} icon={<LogOut aria-hidden="true" className="size-4" />} /> : null}
      {y > 400 ? <FloatIcon label="Back to top" icon={<ArrowUp aria-hidden="true" className="size-4" />} onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })} /> : null}
    </div>
  );
}
