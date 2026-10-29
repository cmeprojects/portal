// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { cookies } from "next/headers";
import { requireSession } from "@/lib/session";
import { hasPin } from "@/lib/car-pin";
import { UNLOCK_COOKIE, isUnlocked } from "@/lib/app-lock";
import { PinPad, SetPinForm } from "./pin-forms";
import { forgotPin, signOutApp } from "../actions";

export const metadata: Metadata = { title: "Unlock" };

export default async function UnlockPage({ searchParams }: PageProps<"/cars-app/unlock">) {
  const { profile } = await requireSession();
  const first = (profile.full_name || "").split(" ")[0];
  const pinSet = await hasPin(profile.id);
  const changing = (await searchParams).change === "1" && (await isUnlocked((await cookies()).get(UNLOCK_COOKIE)?.value, profile.id));

  if (!pinSet || changing) {
    return (
      <section className="flex flex-col gap-4 rounded-xl border border-line bg-surface p-5">
        <h1 className="heading-sm">{changing ? "Change your PIN" : `Choose a PIN${first ? `, ${first}` : ""}`}</h1>
        <p className="text-sm text-muted">
          {changing
            ? "Choose 4 new numbers."
            : "Choose 4 numbers. Next time you open the app, you only need your PIN, not your email and password."}
        </p>
        <SetPinForm />
      </section>
    );
  }

  return (
    <section className="flex flex-col items-center gap-5 py-4">
      <h1 className="heading-sm">Welcome back{first ? `, ${first}` : ""}</h1>
      <p className="text-sm text-muted">Enter your PIN</p>
      <PinPad />
      <div className="flex flex-wrap justify-center gap-x-5 text-sm">
        <form action={forgotPin}>
          <button className="min-h-11 text-brand underline">Forgot your PIN?</button>
        </form>
        <form action={signOutApp}>
          <button className="min-h-11 text-muted underline">Not {first || "you"}? Sign out</button>
        </form>
      </div>
    </section>
  );
}
