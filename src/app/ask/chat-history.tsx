// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import type { ReactNode } from "react";

type Props = {
  chats: { id: string; title: string }[];
  current: string | null;
  onClose: () => void;
  onOpen: (id: string) => void;
  onNew: () => void;
  onDelete: (id: string) => void;
  // What sits at the bottom: Sign in for visitors; name, Portal, Raise a question and Sign out for staff.
  footer: ReactNode;
};

// cmeprojects: the side panel under the top bar: recent chats (saved on the
// account for staff, in this browser for visitors) and the panel's footer.
export function ChatHistory({ chats, current, onClose, onOpen, onNew, onDelete, footer }: Props) {
  return (
    <aside aria-label="Your chats" className="flex h-full w-64 max-w-[85vw] flex-col gap-2 border-r border-line bg-surface p-3">
      <div className="flex items-center justify-between">
        <p className="px-2 text-xs font-semibold text-muted">Your chats</p>
        <button type="button" onClick={onClose} className="rounded px-2 py-1 text-xs text-muted hover:bg-page">
          Close
        </button>
      </div>
      <button type="button" onClick={onNew} className="flex min-h-10 items-center gap-2 rounded-full border border-line px-4 text-sm font-semibold hover:bg-page">
        <span aria-hidden="true">+</span> New chat
      </button>
      <ul className="flex min-h-0 flex-1 flex-col gap-0.5 overflow-y-auto">
        {chats.length === 0 ? <li className="px-2 py-2 text-sm text-muted">No chats yet.</li> : null}
        {chats.map((c) => (
          <li key={c.id} className="group flex items-center">
            <button
              type="button"
              onClick={() => onOpen(c.id)}
              className={`min-h-10 flex-1 truncate rounded-md px-2 py-2 text-left text-sm ${c.id === current ? "bg-brand-soft font-semibold" : "hover:bg-page"}`}
            >
              {c.title}
            </button>
            <button
              type="button"
              aria-label={`Delete ${c.title}`}
              onClick={() => confirm("Delete this chat?") && onDelete(c.id)}
              className="rounded px-2 py-2 text-xs text-muted opacity-60 hover:text-danger group-hover:opacity-100"
            >
              ✕
            </button>
          </li>
        ))}
      </ul>
      <div className="border-t border-line pt-3">{footer}</div>
    </aside>
  );
}

// The panel's footer for visitors.
export function VisitorFooter() {
  return (
    <Link href="/login?next=/ask" className="inline-flex min-h-9 items-center rounded-md border border-line px-4 text-sm font-semibold hover:bg-page">
      Sign in
    </Link>
  );
}
