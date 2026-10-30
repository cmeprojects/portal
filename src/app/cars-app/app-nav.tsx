// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import type { ReactNode } from "react";
import { lockApp, signOutApp } from "./actions";

// The links at the bottom of the Cars app and the Staff app.
export function AppNav({ base, children }: { base: string; children?: ReactNode }) {
  return (
    <nav className="mt-4 flex flex-wrap items-center justify-center gap-x-5 gap-y-2 border-t border-line pt-4 text-sm">
      {children}
      <Link href={`${base}/unlock?change=1`} className="text-brand underline">
        Change PIN
      </Link>
      <form action={lockApp}>
        <input type="hidden" name="base" value={base} />
        <button className="min-h-11 text-brand underline">Lock</button>
      </form>
      <form action={signOutApp}>
        <input type="hidden" name="base" value={base} />
        <button className="min-h-11 text-muted underline">Sign out</button>
      </form>
    </nav>
  );
}
