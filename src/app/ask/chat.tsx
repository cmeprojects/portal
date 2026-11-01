// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useEffect, useRef, useState, useTransition } from "react";
import { Credits } from "@/components/ui";
import type { Answer } from "@/lib/assistant-shared";
import { askQuestion, deleteChat, signOutWebsite } from "./actions";
import { SiteHeader } from "./site-header";

export type ChatTurn = { q: string; a?: Answer; error?: string };

type Props = {
  brand: { logoUrl: string; companyName: string };
  visitor: { name: string; position: string } | null;
  heading: string;
  intro: string;
  suggestions: string[];
  offerCall: boolean;
  phone: string;
  disclaimer: string;
  showCredits: boolean;
  chats: { id: string; title: string }[];
  chatId: string | null;
  initialTurns: ChatTurn[];
};

// Not signed in: the chat is kept in this browser tab until it's closed.
const STORE = "ask-chat";

// cmeprojects: the website's chat. First a landing page (big logo, question
// box, suggestions); after the first question it becomes a normal chat with
// the logo in the corner. Signed-in staff get their saved chats on the side.
export function Chat(p: Props) {
  const [turns, setTurns] = useState<ChatTurn[]>(p.initialTurns);
  const [chatId, setChatId] = useState(p.chatId);
  const [chats, setChats] = useState(p.chats);
  const [text, setText] = useState("");
  const [hideOffer, setHideOffer] = useState(false);
  const [sideOpen, setSideOpen] = useState(false);
  // Signed in: they can hide the whole side panel, like Claude (remembered on this device).
  const [panelHidden, setPanelHidden] = useState(false);
  const togglePanel = (hide: boolean) => {
    setPanelHidden(hide);
    try {
      localStorage.setItem("ask-panel-hidden", hide ? "1" : "0");
    } catch {}
  };
  const [pending, start] = useTransition();
  const end = useRef<HTMLDivElement>(null);
  const signedIn = Boolean(p.visitor);

  // Bring back this tab's chat for visitors who aren't signed in.
  useEffect(() => {
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- a remembered choice on this device
      if (localStorage.getItem("ask-panel-hidden") === "1") setPanelHidden(true);
    } catch {}
    if (signedIn) return;
    try {
      const saved = JSON.parse(sessionStorage.getItem(STORE) ?? "[]") as ChatTurn[];
      // Read after the first paint so the server and browser agree on the page.
       
      if (saved.length) setTurns(saved);
    } catch {}
  }, [signedIn]);
  useEffect(() => {
    if (!signedIn) {
      try {
        sessionStorage.setItem(STORE, JSON.stringify(turns.filter((t) => t.a)));
      } catch {}
    }
    end.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [turns, signedIn]);

  const ask = (question: string) => {
    const q = question.trim();
    if (q.length < 3 || pending) return;
    setText("");
    const history = turns.filter((t) => t.a).map((t) => ({ question: t.q, answer: t.a!.text }));
    setTurns((t) => [...t, { q }]);
    start(async () => {
      const r = await askQuestion(q, chatId, signedIn ? [] : history).catch(() => ({ error: "Sorry, we couldn't reach the server. Please check your connection and try again." }));
      setTurns((t) => t.map((x, i) => (i === t.length - 1 ? ("error" in r ? { q, error: r.error } : { q, a: r.answer }) : x)));
      if (!("error" in r) && r.chatId && r.chatId !== chatId) {
        setChatId(r.chatId);
        setChats((c) => [{ id: r.chatId!, title: q.slice(0, 80) }, ...c]);
        window.history.replaceState(null, "", `/ask?chat=${r.chatId}`);
      }
    });
  };

  const newChat = () => {
    try {
      sessionStorage.removeItem(STORE);
    } catch {}
    setTurns([]);
    setChatId(null);
    window.history.replaceState(null, "", "/ask");
  };

  const started = turns.length > 0;
  const last = turns.at(-1);
  const showOffer = p.offerCall && !hideOffer && last?.a?.offerCall;

  const composer = (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        ask(text);
      }}
      className="flex items-end gap-2 rounded-full border border-line bg-surface py-1.5 pr-1.5 pl-5 shadow-sm"
    >
      <label htmlFor="ask" className="sr-only">
        Your question
      </label>
      <textarea
        id="ask"
        rows={1}
        value={text}
        maxLength={500}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            ask(text);
          }
        }}
        placeholder={started ? "Ask a follow-up question" : "Ask anything"}
        className="max-h-32 min-h-9 flex-1 resize-none border-0 bg-transparent py-1.5 text-base text-ink shadow-none ring-0 outline-none placeholder:text-muted/70 focus:border-0 focus:ring-0 focus:outline-none"
      />
      <button
        type="submit"
        aria-label="Send question"
        disabled={pending || text.trim().length < 3}
        className="flex size-9 shrink-0 items-center justify-center rounded-full bg-brand text-brand-fg transition-opacity disabled:opacity-40"
      >
        <svg viewBox="0 0 24 24" className="size-4" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M12 19V5M5 12l7-7 7 7" />
        </svg>
      </button>
    </form>
  );

  return (
    <div className="flex min-h-dvh">
      {signedIn ? (
        <aside
          aria-label="Your chats"
          className={`${sideOpen ? "fixed inset-0 z-40 flex" : "hidden"} w-full flex-col gap-2 bg-[var(--side-bg)] p-3 text-side-fg md:sticky md:top-0 md:h-dvh md:w-64 md:shrink-0 ${panelHidden ? "md:hidden" : "md:flex"}`}
        >
          <div className="flex items-center justify-between gap-2 px-1 pb-1">
            <Link href="/ask" onClick={() => setSideOpen(false)} aria-label={`${p.brand.companyName} home`} className="rounded-md bg-white px-2 py-1">
              {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
              <img src={p.brand.logoUrl} alt={p.brand.companyName} className="h-8 w-auto max-w-36 object-contain" />
            </Link>
            <button
              type="button"
              aria-label="Hide the side panel"
              onClick={() => (sideOpen ? setSideOpen(false) : togglePanel(true))}
              className="flex size-10 items-center justify-center rounded-md hover:bg-[var(--side-hover)]"
            >
              <PanelIcon />
            </button>
          </div>
          <Link href="/ask" onClick={() => setSideOpen(false)} className="flex min-h-11 items-center gap-2 rounded-full border border-white/30 px-4 text-sm font-semibold hover:bg-[var(--side-hover)]">
            <span aria-hidden="true">+</span> New chat
          </Link>
          <p className="px-2 pt-2 text-xs font-semibold text-side-muted">Your chats</p>
          <ul className="flex min-h-0 flex-1 flex-col gap-0.5 overflow-y-auto">
            {chats.length === 0 ? <li className="px-2 text-sm text-side-muted">No chats yet. Your questions will be saved here.</li> : null}
            {chats.map((c) => (
              <li key={c.id} className="group flex items-center">
                <Link
                  href={`/ask?chat=${c.id}`}
                  onClick={() => setSideOpen(false)}
                  className={`min-h-10 flex-1 truncate rounded-md px-2 py-2 text-sm ${c.id === chatId ? "bg-[var(--side-active)] font-semibold" : "hover:bg-[var(--side-hover)]"}`}
                >
                  {c.title}
                </Link>
                <button
                  type="button"
                  aria-label={`Delete ${c.title}`}
                  onClick={async () => {
                    if (!confirm("Delete this chat?")) return;
                    await deleteChat(c.id);
                    setChats((list) => list.filter((x) => x.id !== c.id));
                    if (c.id === chatId) newChat();
                  }}
                  className="rounded px-2 py-2 text-xs text-side-muted opacity-60 hover:text-side-fg group-hover:opacity-100"
                >
                  ✕
                </button>
              </li>
            ))}
          </ul>
          {/* Who is signed in, like the portal's menu: the portal and Sign out side by side. */}
          <div className="flex flex-col gap-2 border-t border-white/15 pt-3">
            <div className="px-2 leading-tight">
              <p className="truncate text-sm font-semibold">{p.visitor?.name}</p>
              {p.visitor?.position ? <p className="truncate text-xs text-side-muted">{p.visitor.position}</p> : null}
            </div>
            <div className="flex gap-2">
              <Link href="/" className="flex min-h-10 flex-1 items-center justify-center rounded-md bg-white px-3 text-sm font-semibold text-[var(--side-bg)]">
                Open portal
              </Link>
              <form action={signOutWebsite} className="flex-1">
                <button className="min-h-10 w-full rounded-md border border-white/30 px-3 text-sm font-semibold hover:bg-[var(--side-hover)]">Sign out</button>
              </form>
            </div>
          </div>
        </aside>
      ) : null}

      <div className="flex min-w-0 flex-1 flex-col">
        <SiteHeader
          logoUrl={p.brand.logoUrl}
          companyName={p.brand.companyName}
          signedIn={signedIn}
          // The small logo: in the side panel while it's open (on a computer),
          // otherwise here once a chat starts or the panel is hidden.
          showLogo={signedIn ? panelHidden || started : started}
          logoClass={signedIn && !panelHidden ? "md:hidden" : ""}
        >
          {signedIn ? (
            <>
              <button type="button" aria-label="Show your chats" onClick={() => setSideOpen(true)} className="flex size-10 items-center justify-center rounded-md hover:bg-surface md:hidden">
                <PanelIcon />
              </button>
              {panelHidden ? (
                <button type="button" aria-label="Show the side panel" onClick={() => togglePanel(false)} className="hidden size-10 items-center justify-center rounded-md hover:bg-surface md:flex">
                  <PanelIcon />
                </button>
              ) : null}
            </>
          ) : null}
        </SiteHeader>

        {!started ? (
          <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col justify-center gap-5 px-4 pb-16">
            <div className="flex flex-col items-center gap-4 text-center">
              {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
              <img src={p.brand.logoUrl} alt={p.brand.companyName} className="h-24 w-auto max-w-[70%] object-contain sm:h-28" />
              <h1 className="font-display text-3xl font-semibold tracking-tight sm:text-4xl">{p.heading}</h1>
              {p.intro ? <p className="max-w-xl text-muted">{p.intro}</p> : null}
            </div>
            {composer}
            {p.suggestions.length ? (
              <div className="flex flex-wrap justify-center gap-2">
                {p.suggestions.map((idea) => (
                  <button key={idea} type="button" onClick={() => ask(idea)} className="min-h-10 rounded-full border border-line bg-surface px-4 text-sm hover:border-muted">
                    {idea}
                  </button>
                ))}
              </div>
            ) : null}
          </main>
        ) : (
          <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-4 pt-4">
            <ol className="flex flex-col gap-6" aria-live="polite">
              {turns.map((t, i) => (
                <li key={i} className="ask-rise flex flex-col gap-3">
                  <p className="max-w-[85%] self-end rounded-3xl rounded-br-md bg-brand-soft px-4 py-3">{t.q}</p>
                  {t.error ? (
                    <p role="alert" className="rounded-lg bg-danger-soft px-4 py-3 text-sm text-danger">
                      {t.error}
                    </p>
                  ) : t.a ? (
                    <div className="flex flex-col gap-3">
                      <p className="leading-relaxed whitespace-pre-line">{t.a.text}</p>
                      {t.a.sources.length ? (
                        <div className="flex flex-wrap items-center gap-2 text-xs text-muted">
                          {t.a.from === "web" ? "From the web:" : "From our documents:"}
                          {t.a.sources.map((s) =>
                            s.url ? (
                              <a key={s.url} href={s.url} target="_blank" rel="noopener noreferrer" className="rounded-full border border-line bg-surface px-3 py-1 font-medium text-ink underline-offset-2 hover:underline">
                                {s.title}
                              </a>
                            ) : (
                              <span key={s.title} className="rounded-full border border-line bg-surface px-3 py-1 font-medium text-ink">
                                {s.title}
                              </span>
                            ),
                          )}
                        </div>
                      ) : null}
                    </div>
                  ) : (
                    <p className="animate-pulse text-sm text-muted">Looking that up…</p>
                  )}
                </li>
              ))}
            </ol>

            {showOffer ? (
              <div className="ask-rise flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-brand p-4 text-brand-fg">
                <div>
                  <p className="font-semibold">Would you like to talk to our team?</p>
                  <p className="text-sm opacity-90">Leave your name and number and we&apos;ll call you{p.phone ? `, or call ${p.phone}` : ""}.</p>
                </div>
                <div className="flex gap-2">
                  <Link href={`/ask/get-started?asked=${encodeURIComponent(last?.q ?? "")}`} className="inline-flex min-h-11 items-center rounded-full bg-surface px-4 text-sm font-semibold text-brand">
                    Yes, call me
                  </Link>
                  <button type="button" onClick={() => setHideOffer(true)} className="min-h-11 rounded-full border border-brand-fg/50 px-4 text-sm">
                    No thanks
                  </button>
                </div>
              </div>
            ) : null}
            <div ref={end} />
            <div className="sticky bottom-0 mt-auto bg-page pt-2 pb-3">
              {composer}
              {!signedIn ? (
                <button type="button" onClick={newChat} className="mt-2 text-xs text-muted underline">
                  Start again
                </button>
              ) : null}
            </div>
          </main>
        )}

        <footer className="flex flex-col items-center gap-1 px-4 pb-4 text-center text-xs text-muted">
          <p>
            {p.disclaimer} Please don&apos;t type personal or health details.
          </p>
          {p.showCredits ? <Credits /> : null}
        </footer>
      </div>
    </div>
  );
}

function PanelIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="3" y="4" width="18" height="16" rx="2" />
      <path d="M9 4v16" />
    </svg>
  );
}
