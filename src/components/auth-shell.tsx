// Staff Portal · © cmeproject. All rights reserved.
import type { ReactNode } from "react";
import type { Branding } from "@/lib/branding";
import { Credits } from "@/components/ui";

// Layout for the sign-in, invite and two-factor pages: phone-first card.
export function AuthShell({ hero, children }: { brand: Branding; hero?: ReactNode; children: ReactNode }) {
  return (
    <main className="flex min-h-screen flex-col items-center bg-page">
      <div className="flex w-full justify-center rounded-b-[28px] bg-brand-dark px-6 pb-16 pt-12">{hero}</div>
      <div className="-mt-9 w-full max-w-md px-4">
        <div className="flex flex-col gap-5 rounded-[20px] border border-line bg-white px-5 py-6 sm:px-7">
          {children}
        </div>
      </div>
      <footer className="mt-auto py-6">
        <Credits />
      </footer>
    </main>
  );
}
