// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useState } from "react";
import { ArrowUp, List, Pencil } from "lucide-react";
import { FloatIcon } from "@/components/page-save";

// cmeprojects (owner, 20 Nov 2026): floating icons on a client's page (named on
// hover): back to the client list, edit their details, and back to the top.
export function ClientFloat({ editHref }: { editHref?: string }) {
  const [y, setY] = useState(0);
  useEffect(() => {
    const onScroll = () => setY(window.scrollY);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);
  return (
    <div className="fixed right-4 bottom-24 z-30 flex flex-col items-end gap-2 md:right-8 print:hidden">
      <FloatIcon href="/settings/clients" label="Back to client list" icon={<List aria-hidden="true" className="size-4" />} />
      {editHref ? <FloatIcon href={editHref} label="Edit details" icon={<Pencil aria-hidden="true" className="size-4" />} /> : null}
      {y > 400 ? <FloatIcon label="Back to top" icon={<ArrowUp aria-hidden="true" className="size-4" />} onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })} /> : null}
    </div>
  );
}
