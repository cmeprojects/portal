// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { assistantOn, loadSettings } from "@/lib/assistant";
import { Chat } from "./chat";

// cmeprojects: the "ask anything" page. Looks like a chat; answers come only
// from the documents the system admin uploaded.
export default async function AskPage() {
  if (!(await assistantOn())) {
    return (
      <main className="mx-auto flex w-full max-w-xl flex-1 flex-col justify-center gap-3 px-4 py-16 text-center">
        <h1 className="heading">Our website is coming soon</h1>
        <p className="text-muted">In the meantime, please call us or sign in if you&apos;re part of the team.</p>
        <Link href="/login" className="mx-auto text-brand underline">
          Sign in
        </Link>
      </main>
    );
  }
  const s = await loadSettings();
  return (
    <>
      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-4 py-10 sm:py-14">
        <Chat heading={s.heading} intro={s.intro} offerCall={s.offer_call} phone={s.phone} />
      </main>
      <footer className="border-t border-line px-4 py-4 text-center text-xs leading-relaxed text-muted">
        {s.disclaimer}
        {s.phone ? ` Prefer a person? Call ${s.phone} or ` : " Prefer a person? "}
        <Link href="/ask/get-started" className="underline">
          ask us to call you
        </Link>
        .
      </footer>
    </>
  );
}
