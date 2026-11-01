// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { deleteChat } from "./actions";

type Props = {
  chats: { id: string; title: string }[];
  current: string | null;
  onClose: () => void;
  onDeleted: (id: string) => void;
};

// cmeprojects: a signed-in person's saved chats, in a light panel that opens
// from the History button and closes again.
export function ChatHistory({ chats, current, onClose, onDeleted }: Props) {
  return (
    <aside aria-label="Your chats" className="flex h-full w-72 max-w-[85vw] flex-col gap-2 border-r border-line bg-surface p-3 shadow-lg md:shadow-none">
      <div className="flex items-center justify-between">
        <p className="px-2 text-sm font-semibold">Your chats</p>
        <button type="button" onClick={onClose} className="min-h-10 rounded-md px-3 text-sm text-muted hover:bg-page">
          Close
        </button>
      </div>
      <Link href="/ask" onClick={onClose} className="flex min-h-10 items-center gap-2 rounded-full border border-line px-4 text-sm font-semibold hover:bg-page">
        <span aria-hidden="true">+</span> New chat
      </Link>
      <ul className="flex min-h-0 flex-1 flex-col gap-0.5 overflow-y-auto">
        {chats.length === 0 ? <li className="px-2 py-2 text-sm text-muted">No chats yet. Your questions will be saved here.</li> : null}
        {chats.map((c) => (
          <li key={c.id} className="group flex items-center">
            <Link
              href={`/ask?chat=${c.id}`}
              onClick={onClose}
              className={`min-h-10 flex-1 truncate rounded-md px-2 py-2 text-sm ${c.id === current ? "bg-brand-soft font-semibold" : "hover:bg-page"}`}
            >
              {c.title}
            </Link>
            <button
              type="button"
              aria-label={`Delete ${c.title}`}
              onClick={async () => {
                if (!confirm("Delete this chat?")) return;
                await deleteChat(c.id);
                onDeleted(c.id);
              }}
              className="rounded px-2 py-2 text-xs text-muted opacity-60 hover:text-danger group-hover:opacity-100"
            >
              ✕
            </button>
          </li>
        ))}
      </ul>
    </aside>
  );
}
