// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, useTransition } from "react";
import { Credits } from "@/components/ui";
import type { Answer } from "@/lib/assistant-shared";
import { askQuestion } from "./actions";
import { ChatHistory } from "./chat-history";
import { SiteHeader, type HeaderVisitor } from "./site-header";

export type ChatTurn = { q: string; a?: Answer; error?: string };

type Props = {
  brand: { logoUrl: string; companyName: string };
  visitor: HeaderVisitor;
  heading: string;
  intro: string;
  suggestions: string[];
  offerCall: boolean;
  urgentPhone: string;
  staffPhone: string;
  disclaimer: string;
  showCredits: boolean;
  chats: { id: string; title: string }[];
  chatId: string | null;
  initialTurns: ChatTurn[];
};

// Visitors' chats are kept in this browser tab until it's closed.
const VISITOR_CHAT = "ask-chat";
// Whether a signed-in person keeps their chat history open (this device only).
const HISTORY_OPEN = "ask-history-open";

const telOf = (phone: string) => `tel:${phone.replace(/[^\d+]/g, "")}`;

// cmeprojects: the website's chat. It starts as a landing page (big logo,
// question box, suggestions) and becomes a normal chat after the first
// question. Signed-in staff have their chats saved, in a History panel.
export function Chat(props: Props) {
  const signedIn = Boolean(props.visitor);
  const [turns, setTurns] = useState<ChatTurn[]>(props.initialTurns);
  const [chatId, setChatId] = useState(props.chatId);
  const [chats, setChats] = useState(props.chats);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [offerHidden, setOfferHidden] = useState(false);
  const [pending, start] = useTransition();
  const end = useRef<HTMLDivElement>(null);

  // Read saved choices after the first paint, so the server and browser agree.
  useEffect(() => {
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- restoring this device's saved state once
      if (signedIn && localStorage.getItem(HISTORY_OPEN) === "1") setHistoryOpen(true);
      if (!signedIn) {
        const saved = JSON.parse(sessionStorage.getItem(VISITOR_CHAT) ?? "[]") as ChatTurn[];
        if (saved.length) setTurns(saved);
      }
    } catch {}
  }, [signedIn]);

  useEffect(() => {
    if (!signedIn) {
      try {
        sessionStorage.setItem(VISITOR_CHAT, JSON.stringify(turns.filter((t) => t.a)));
      } catch {}
    }
    end.current?.scrollIntoView({ behavior: "smooth", block: "end" });
  }, [turns, signedIn]);

  const toggleHistory = (open: boolean) => {
    setHistoryOpen(open);
    try {
      localStorage.setItem(HISTORY_OPEN, open ? "1" : "0");
    } catch {}
  };

  const ask = (question: string) => {
    const q = question.trim();
    if (q.length < 3 || pending) return;
    // Signed in: the server reads earlier turns from the saved chat.
    const history = signedIn ? [] : turns.filter((t) => t.a).map((t) => ({ question: t.q, answer: t.a!.text }));
    setTurns((t) => [...t, { q }]);
    start(async () => {
      const result = await askQuestion(q, chatId, history).catch(() => ({ error: "Sorry, we couldn't reach the server. Please check your connection and try again." }));
      setTurns((t) => t.map((turn, i) => (i < t.length - 1 ? turn : "error" in result ? { q, error: result.error } : { q, a: result.answer })));
      if (!("error" in result) && result.chatId && result.chatId !== chatId) {
        setChatId(result.chatId);
        setChats((list) => [{ id: result.chatId!, title: q.slice(0, 80) }, ...list]);
        window.history.replaceState(null, "", `/ask?chat=${result.chatId}`);
      }
    });
  };

  const startAgain = () => {
    try {
      sessionStorage.removeItem(VISITOR_CHAT);
    } catch {}
    setTurns([]);
    setChatId(null);
    window.history.replaceState(null, "", "/ask");
  };

  const started = turns.length > 0;
  const last = turns.at(-1);
  const showOffer = props.offerCall && !offerHidden && Boolean(last?.a?.offerCall);

  return (
    <div className="flex min-h-dvh">
      {signedIn && historyOpen ? (
        <>
          {/* On a phone the panel sits over the page; on a computer, beside it. */}
          <button type="button" aria-label="Close your chats" onClick={() => toggleHistory(false)} className="fixed inset-0 z-30 bg-black/30 md:hidden" />
          <div className="fixed inset-y-0 left-0 z-40 md:sticky md:top-0 md:h-dvh">
            <ChatHistory
              chats={chats}
              current={chatId}
              onClose={() => toggleHistory(false)}
              onDeleted={(id) => {
                setChats((list) => list.filter((c) => c.id !== id));
                if (id === chatId) startAgain();
              }}
            />
          </div>
        </>
      ) : null}

      <div className="flex min-w-0 flex-1 flex-col">
        <SiteHeader
          logoUrl={props.brand.logoUrl}
          companyName={props.brand.companyName}
          urgentPhone={props.urgentPhone}
          visitor={props.visitor}
          leading={
            signedIn && !historyOpen ? (
              <button type="button" onClick={() => toggleHistory(true)} className="inline-flex min-h-10 items-center gap-2 rounded-full border border-line px-3 text-sm font-semibold hover:bg-page">
                <HistoryIcon /> History
              </button>
            ) : null
          }
        />

        {!started ? (
          <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col justify-center gap-5 px-4 pb-16">
            <div className="flex flex-col items-center gap-4 text-center">
              {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
              <img src={props.brand.logoUrl} alt="" className="h-24 w-auto max-w-[70%] object-contain sm:h-28" />
              <h1 className="font-display text-3xl font-semibold tracking-tight sm:text-4xl">{props.heading}</h1>
              {props.intro ? <p className="max-w-xl text-muted">{props.intro}</p> : null}
            </div>
            <Composer onAsk={ask} pending={pending} placeholder="Ask anything" />
            {props.suggestions.length ? (
              <div className="flex flex-wrap justify-center gap-2">
                {props.suggestions.map((idea) => (
                  <button key={idea} type="button" onClick={() => ask(idea)} className="min-h-10 rounded-full border border-line bg-surface px-4 text-sm hover:border-muted">
                    {idea}
                  </button>
                ))}
              </div>
            ) : null}
          </main>
        ) : (
          <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-4 pt-6">
            <ol className="flex flex-col gap-6" aria-live="polite">
              {turns.map((t, i) => (
                <li key={i} className="ask-rise flex flex-col gap-3">
                  <p className="max-w-[85%] self-end rounded-3xl rounded-br-md bg-brand-soft px-4 py-3">{t.q}</p>
                  {t.error ? (
                    <p role="alert" className="rounded-lg bg-danger-soft px-4 py-3 text-sm text-danger">
                      {t.error}
                    </p>
                  ) : t.a ? (
                    <AnswerView answer={t.a} showSources={signedIn} />
                  ) : (
                    <p className="animate-pulse text-sm text-muted">Looking that up…</p>
                  )}
                </li>
              ))}
            </ol>

            {showOffer ? (
              signedIn ? (
                <OfferCard
                  title="Can't find an answer?"
                  text="Contact your manager."
                  action={props.staffPhone ? { href: telOf(props.staffPhone), label: `Call ${props.staffPhone}` } : null}
                  onHide={() => setOfferHidden(true)}
                />
              ) : (
                <OfferCard
                  title="Would you like to talk to our team?"
                  text={`Leave your name and number and we'll call you${props.urgentPhone ? `, or call ${props.urgentPhone}` : ""}.`}
                  action={{ href: `/ask/get-started?asked=${encodeURIComponent(last?.q ?? "")}`, label: "Yes, call me" }}
                  onHide={() => setOfferHidden(true)}
                />
              )
            ) : null}
            <div ref={end} />
            <div className="sticky bottom-0 mt-auto bg-page pt-2 pb-3">
              <Composer onAsk={ask} pending={pending} placeholder="Ask a follow-up question" />
              {!signedIn ? (
                <button type="button" onClick={startAgain} className="mt-2 text-xs text-muted underline">
                  Start again
                </button>
              ) : null}
            </div>
          </main>
        )}

        <footer className="flex flex-col items-center gap-1 px-4 pb-4 text-center text-xs text-muted">
          <p>{props.disclaimer} Please don&apos;t type personal or health details.</p>
          {props.showCredits ? <Credits /> : null}
        </footer>
      </div>
    </div>
  );
}

// The question box: one line, a round send button, Enter to send.
function Composer({ onAsk, pending, placeholder }: { onAsk: (q: string) => void; pending: boolean; placeholder: string }) {
  const [text, setText] = useState("");
  const send = () => {
    if (text.trim().length < 3 || pending) return;
    onAsk(text);
    setText("");
  };
  return (
    <form
      onSubmit={(e) => {
        e.preventDefault();
        send();
      }}
      className="flex items-end gap-2 rounded-full border border-line bg-surface py-1.5 pr-1.5 pl-5 shadow-sm"
    >
      <label htmlFor="ask-box" className="sr-only">
        Your question
      </label>
      <textarea
        id="ask-box"
        rows={1}
        value={text}
        maxLength={500}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" && !e.shiftKey) {
            e.preventDefault();
            send();
          }
        }}
        placeholder={placeholder}
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
}

// An answer. Signed-in staff also see where to read more.
function AnswerView({ answer, showSources }: { answer: Answer; showSources: boolean }) {
  return (
    <div className="flex flex-col gap-3">
      <p className="leading-relaxed whitespace-pre-line">{answer.text}</p>
      {showSources && answer.sources.length ? (
        <p className="flex flex-wrap items-center gap-2 text-xs text-muted">
          Further information can be found in:
          {answer.sources.map((s) =>
            s.url ? (
              <a key={s.url} href={s.url} target="_blank" rel="noopener noreferrer" className="rounded-full border border-line bg-surface px-3 py-1 font-medium text-ink hover:underline">
                {s.title}
              </a>
            ) : (
              <span key={s.title} className="rounded-full border border-line bg-surface px-3 py-1 font-medium text-ink">
                {s.title}
              </span>
            ),
          )}
        </p>
      ) : null}
    </div>
  );
}

function OfferCard({ title, text, action, onHide }: { title: string; text: string; action: { href: string; label: string } | null; onHide: () => void }) {
  return (
    <div className="ask-rise flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-brand p-4 text-brand-fg">
      <div>
        <p className="font-semibold">{title}</p>
        <p className="text-sm opacity-90">{text}</p>
      </div>
      <div className="flex gap-2">
        {action ? (
          <a href={action.href} className="inline-flex min-h-11 items-center rounded-full bg-surface px-4 text-sm font-semibold text-brand">
            {action.label}
          </a>
        ) : null}
        <button type="button" onClick={onHide} className="min-h-11 rounded-full border border-brand-fg/50 px-4 text-sm">
          No thanks
        </button>
      </div>
    </div>
  );
}

function HistoryIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-4" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M3 12a9 9 0 1 0 3-6.7L3 8" />
      <path d="M3 3v5h5M12 7v5l3 2" />
    </svg>
  );
}
