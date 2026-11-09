// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useRef } from "react";
import { Pencil, X } from "lucide-react";
import type { PersonCard } from "@/lib/profiles";
import { ProfileForm } from "@/components/profile-form";

// cmeprojects: edit someone's profile in a pop-up, without leaving the directory.
export function EditProfileDialog({ person, employment }: { person: PersonCard; employment: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  return (
    <>
      <button
        type="button"
        onClick={() => ref.current?.showModal()}
        className="inline-flex min-h-10 items-center gap-2 rounded-lg border border-line bg-surface px-4 text-sm font-semibold text-ink hover:border-brand hover:text-brand"
      >
        <Pencil aria-hidden="true" className="size-4" />
        Edit details
      </button>
      <dialog
        ref={ref}
        aria-label={`Edit ${person.name}'s details`}
        onClick={(e) => e.target === e.currentTarget && e.currentTarget.close()}
        className="m-auto max-h-[90vh] w-[min(42rem,calc(100vw-2rem))] max-w-none overflow-y-auto rounded-xl border border-line bg-surface p-0 text-ink shadow-xl backdrop:bg-black/40"
      >
        <header className="sticky top-0 z-10 flex items-center gap-3 border-b border-line bg-surface px-5 py-4">
          <h2 className="heading-sm min-w-0 flex-1 truncate">Edit {person.name}&apos;s details</h2>
          <button type="button" onClick={() => ref.current?.close()} aria-label="Close" className="rounded-md p-1.5 text-muted hover:bg-page hover:text-ink">
            <X className="size-5" />
          </button>
        </header>
        <div className="p-5 sm:p-6">
          <ProfileForm person={person} employment={employment} />
        </div>
      </dialog>
    </>
  );
}
