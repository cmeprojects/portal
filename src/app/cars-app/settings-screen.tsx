// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { cookies } from "next/headers";
import { requireSession } from "@/lib/session";
import { PIN_OFF_COOKIE } from "@/lib/app-lock";
import { ThemeSwitch } from "@/components/theme-switch";
import { Button, Notice, buttonClass } from "@/components/ui";
import { lockApp, setPinOnOpen, signOutApp } from "./actions";

// cmeprojects: each phone app's own settings (this phone only): the PIN, the
// colours, and signing out. Shared by the Cars app and the Staff app.
export async function AppSettingsScreen({ base, saved }: { base: string; saved: boolean }) {
  await requireSession();
  const pinOn = !(await cookies()).has(PIN_OFF_COOKIE);
  return (
    <div className="flex flex-col gap-4">
      <Link href={base} className="self-start text-sm font-semibold text-brand">
        ‹ Back
      </Link>
      <h1 className="heading-sm">Settings</h1>
      {saved ? <Notice tone="success">Saved.</Notice> : null}

      <section className="flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="font-semibold">PIN</h2>
        <p className="text-sm text-muted">
          {pinOn
            ? "The app asks for your PIN each time you open it, and when you come back to it after a minute away."
            : "The app opens without your PIN on this phone. Anyone who picks up your phone can open it."}
        </p>
        <form action={setPinOnOpen} className="flex flex-wrap items-center gap-3">
          <input type="hidden" name="base" value={base} />
          <input type="hidden" name="on" value={pinOn ? "false" : "true"} />
          <span className="text-sm font-semibold">Ask for my PIN when I open the app:</span>
          <button
            role="switch"
            aria-checked={pinOn}
            className={`flex h-9 min-w-20 items-center justify-center gap-2 rounded-md px-3 text-sm font-semibold ${
              pinOn ? "bg-brand text-brand-fg" : "border border-field bg-surface text-muted"
            }`}
          >
            <span aria-hidden="true" className={`h-2.5 w-2.5 rounded-full ${pinOn ? "bg-brand-fg" : "bg-muted"}`} />
            {pinOn ? "On" : "Off"}
          </button>
        </form>
        <Link href={`${base}/unlock?change=1`} className={buttonClass("outline", "self-start", "sm")}>
          Change my PIN
        </Link>
      </section>

      <section className="flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="font-semibold">Colours</h2>
        <p className="text-sm text-muted">Device follows your phone&apos;s light or dark setting.</p>
        <ThemeSwitch onPage />
      </section>

      <section className="flex flex-wrap gap-2">
        <form action={lockApp}>
          <input type="hidden" name="base" value={base} />
          <Button variant="outline" size="sm">
            Lock now
          </Button>
        </form>
        <form action={signOutApp}>
          <input type="hidden" name="base" value={base} />
          <Button variant="outline" size="sm">
            Sign out
          </Button>
        </form>
      </section>
    </div>
  );
}
