// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { buttonClass } from "@/components/ui";

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-6 text-center">
      <h1 className="text-2xl font-extrabold">We can&apos;t find that page</h1>
      <p className="max-w-md text-[15px] text-muted">
        It may have moved, or you may not have access to it. If someone sent you a link to a task, ask them to check
        you&apos;re assigned to it or helping on it.
      </p>
      <Link href="/" className={buttonClass("primary")}>
        Go to My tasks
      </Link>
    </div>
  );
}
