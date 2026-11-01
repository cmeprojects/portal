// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useEffect, useRef, useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { Credits } from "@/components/ui";
import type { Answer } from "@/lib/assistant-shared";
import { askQuestion, deleteChat } from "./actions";
import { ChatHistory, VisitorFooter } from "./chat-history";
import { StaffFooter } from "./raise-question";
import { PanelToggle, SiteHeader } from "./site-header";

export type ChatTurn = { q: string; a?: Answer; error?: string };
type Person = { id: string; name: string; detail: string };
type Staff = { name: string; position: string; answerers: Person[] } | null;
type VisitorChat = { id: string; title: string; turns: ChatTurn[] };

type Props = {
  brand: { logoUrl: string; companyName: string };
  staff: Staff;
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

// Visitors' recent chats live in this browser only (the last 20).
const VISITOR_CHATS = "ask-visitor-chats";
// Whether the side panel is open (remembered on this device).
const PANEL_OPEN = "ask-panel-open";

const telOf = (phone: string) => `tel:${phone.replace(/[^\d+]/g, "")}`;
const newId = () => (typeof crypto !== "undefined" && "randomUUID" in crypto ? crypto.randomUUID() : String(Date.now()));

function readVisitorChats(): VisitorChat[] {
  try {
    const list = JSON.parse(localStorage.getItem(VISITOR_CHATS) ?? "[]");
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

// cmeprojects: the website's chat. It starts as a landing page (big logo,
// question box, suggestions) and becomes a normal chat after the first
// question. Everyone keeps recent chats: on the account for signed-in staff,
// in this browser for visitors.
export function Chat(props: Props) {
  const router = useRouter();
  const signedIn = Boolean(props.staff);
  const [turns, setTurns] = useState<ChatTurn[]>(props.initialTurns);
  const [chatId, setChatId] = useState(props.chatId);
  const [chats, setChats] = useState(props.chats);
  const [panelOpen, setPanelOpen] = useState(false);
  const [offerHidden, setOfferHidden] = useState(false);
  const [pending, start] = useTransition();
  const end = useRef<HTMLDivElement>(null);

  // Read this device's saved state after the first paint, so the server and browser agree.
  useEffect(() => {
    try {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- restoring this device's saved state once
      setPanelOpen(localStorage.getItem(PANEL_OPEN) === "1");
    } catch {}
    if (!signedIn) setChats(readVisitorChats().map((c) => ({ id: c.id, title: c.title })));
  }, [signedIn]);

  // Keep a visitor's chat in this browser as it grows.
  useEffect(() => {
    end.current?.scrollIntoView({ behavior: "smooth", block: "end" });
    if (signedIn || !chatId || !turns.some((t) => t.a)) return;
    const saved = readVisitorChats().filter((c) => c.id !== chatId);
    const title = turns[0]?.q.slice(0, 80) ?? "Chat";
    const next = [{ id: chatId, title, turns: turns.filter((t) => t.a) }, ...saved].slice(0, 20);
    try {
      localStorage.setItem(VISITOR_CHATS, JSON.stringify(next));
    } catch {}
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the list mirrors what was just saved
    setChats(next.map((c) => ({ id: c.id, title: c.title })));
  }, [turns, chatId, signedIn]);

  const setPanel = (open: boolean) => {
    setPanelOpen(open);
    try {
      localStorage.setItem(PANEL_OPEN, open ? "1" : "0");
    } catch {}
  };

  const ask = (question: string) => {
    const q = question.trim();
    if (q.length < 3 || pending) return;
    // Visitors send their earlier turns; staff's come from the saved chat.
    const history = signedIn ? [] : turns.filter((t) => t.a).map((t) => ({ question: t.q, answer: t.a!.text }));
    if (!signedIn && !chatId) setChatId(newId());
    setTurns((t) => [...t, { q }]);
    start(async () => {
      const result = await askQuestion(q, signedIn ? chatId : null, history).catch(() => ({ error: "Sorry, we couldn't reach the server. Please check your connection and try again." }));
      setTurns((t) => t.map((turn, i) => (i < t.length - 1 ? turn : "error" in result ? { q, error: result.error } : { q, a: result.answer })));
      if (signedIn && !("error" in result) && result.chatId && result.chatId !== chatId) {
        setChatId(result.chatId);
        setChats((list) => [{ id: result.chatId!, title: q.slice(0, 80) }, ...list]);
        window.history.replaceState(null, "", `/ask?chat=${result.chatId}`);
      }
    });
  };

  const newChat = () => {
    setTurns([]);
    setChatId(null);
    setOfferHidden(false);
    if (signedIn) router.push("/ask");
  };

  const openChat = (id: string) => {
    if (signedIn) return router.push(`/ask?chat=${id}`);
    const chat = readVisitorChats().find((c) => c.id === id);
    if (chat) {
      setChatId(chat.id);
      setTurns(chat.turns);
    }
  };

  const removeChat = async (id: string) => {
    if (signedIn) await deleteChat(id);
    else {
      try {
        localStorage.setItem(VISITOR_CHATS, JSON.stringify(readVisitorChats().filter((c) => c.id !== id)));
      } catch {}
    }
    setChats((list) => list.filter((c) => c.id !== id));
    if (id === chatId) newChat();
  };

  const started = turns.length > 0;
  const last = turns.at(-1);
  const showOffer = props.offerCall && !offerHidden && Boolean(last?.a?.offerCall);

  return (
    <div className="flex min-h-dvh flex-col">
      <SiteHeader
        logoUrl={props.brand.logoUrl}
        companyName={props.brand.companyName}
        signedIn={signedIn}
        toggle={<PanelToggle open={panelOpen} onClick={() => setPanel(!panelOpen)} />}
      />

      <div className="flex flex-1">
        {panelOpen ? (
          <div className="fixed inset-y-0 top-[60px] left-0 z-20 md:sticky md:top-[60px] md:h-[calc(100dvh-60px)]">
            <ChatHistory
              chats={chats}
              current={chatId}
              onClose={() => setPanel(false)}
              onOpen={openChat}
              onNew={newChat}
              onDelete={removeChat}
              footer={props.staff ? <StaffFooter name={props.staff.name} position={props.staff.position} answerers={props.staff.answerers} /> : <VisitorFooter />}
            />
          </div>
        ) : null}

        <div className="flex min-w-0 flex-1 flex-col">
          {!started ? (
            <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col justify-center gap-5 px-4 py-10">
              <div className="flex flex-col items-center gap-4 text-center">
                {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
                <img src={props.brand.logoUrl} alt="" className="h-36 w-auto max-w-[80%] object-contain sm:h-44" />
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
              </div>
            </main>
          )}

          <footer className="flex flex-col items-center gap-1 px-4 pb-4 text-center text-xs text-muted">
            {props.urgentPhone && !signedIn ? (
              <a href={telOf(props.urgentPhone)} className="text-sm text-ink">
                For urgent support please call <strong className="text-brand">{props.urgentPhone}</strong>
              </a>
            ) : null}
            <p>{props.disclaimer} Please don&apos;t type personal or health details.</p>
            {props.showCredits ? <Credits /> : null}
          </footer>
        </div>
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
