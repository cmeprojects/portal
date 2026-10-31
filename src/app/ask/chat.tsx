// Staff Portal · © cmeproject. All rights reserved.
"use client";

import Link from "next/link";
import { useRef, useState, useTransition } from "react";
import { Button, inputClass } from "@/components/ui";
import { askQuestion } from "./actions";

type Turn = { q: string; a?: { text: string; sources: string[]; answered: boolean; offerCall: boolean }; error?: string };

const IDEAS = ["What services do you offer?", "What's your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"];

// The conversation lives in the browser; each question is answered on its own.
export function Chat({ heading, intro, offerCall, phone }: { heading: string; intro: string; offerCall: boolean; phone: string }) {
  const [turns, setTurns] = useState<Turn[]>([]);
  const [text, setText] = useState("");
  const [hidden, setHidden] = useState(false);
  const [pending, start] = useTransition();
  const end = useRef<HTMLDivElement>(null);

  const ask = (question: string) => {
    const q = question.trim();
    if (!q || pending) return;
    setText("");
    setTurns((t) => [...t, { q }]);
    start(async () => {
      const r = await askQuestion(q);
      setTurns((t) => t.map((x, i) => (i === t.length - 1 ? ("error" in r ? { q, error: r.error } : { q, a: r }) : x)));
      setTimeout(() => end.current?.scrollIntoView({ behavior: "smooth", block: "end" }), 50);
    });
  };

  const last = turns[turns.length - 1];
  const showOffer = offerCall && !hidden && last?.a?.offerCall;

  return (
    <div className="flex flex-1 flex-col gap-6">
      {turns.length === 0 ? (
        <div className="flex flex-col gap-3 pt-6 text-center sm:pt-12">
          <h1 className="font-display text-3xl font-semibold tracking-tight sm:text-4xl">{heading}</h1>
          <p className="mx-auto max-w-xl text-muted">{intro}</p>
        </div>
      ) : (
        <ol className="flex flex-col gap-5" aria-live="polite">
          {turns.map((t, i) => (
            <li key={i} className="flex flex-col gap-3">
              <p className="max-w-[85%] self-end rounded-2xl rounded-br-sm bg-brand-soft px-4 py-3">{t.q}</p>
              {t.error ? (
                <p role="alert" className="rounded-lg bg-danger-soft px-4 py-3 text-sm text-danger">
                  {t.error}
                </p>
              ) : t.a ? (
                <div className="flex flex-col gap-3 rounded-lg border border-line bg-surface p-4">
                  <p className="whitespace-pre-line leading-relaxed">{t.a.text}</p>
                  {t.a.sources.length ? (
                    <p className="flex flex-wrap items-center gap-2 border-t border-line pt-3 text-xs text-muted">
                      From our documents:
                      {t.a.sources.map((s) => (
                        <span key={s} className="rounded bg-page px-2 py-1 font-medium text-ink">
                          {s}
                        </span>
                      ))}
                    </p>
                  ) : null}
                </div>
              ) : (
                <p className="text-sm text-muted">Looking through our documents…</p>
              )}
            </li>
          ))}
        </ol>
      )}

      {showOffer ? (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-lg bg-brand p-4 text-brand-fg">
          <div>
            <p className="font-semibold">Would you like to talk to our team?</p>
            <p className="text-sm opacity-90">Leave your name and number and we&apos;ll call you. No obligation{phone ? `, or call ${phone}` : ""}.</p>
          </div>
          <div className="flex gap-2">
            <Link
              href={`/ask/get-started?asked=${encodeURIComponent(last?.q ?? "")}`}
              className="inline-flex min-h-11 items-center rounded-md bg-surface px-4 text-sm font-semibold text-brand"
            >
              Yes, call me
            </Link>
            <button type="button" onClick={() => setHidden(true)} className="min-h-11 rounded-md border border-brand-fg/50 px-4 text-sm">
              No thanks
            </button>
          </div>
        </div>
      ) : null}

      <div ref={end} />
      <div className="sticky bottom-0 -mx-4 mt-auto flex flex-col gap-3 bg-page px-4 pt-2 pb-4">
        {turns.length === 0 ? (
          <div className="flex flex-wrap justify-center gap-2">
            {IDEAS.map((idea) => (
              <button key={idea} type="button" onClick={() => ask(idea)} className="min-h-11 rounded-full border border-line bg-surface px-4 text-sm hover:border-muted">
                {idea}
              </button>
            ))}
          </div>
        ) : null}
        <form
          onSubmit={(e) => {
            e.preventDefault();
            ask(text);
          }}
          className="flex items-center gap-2 rounded-full border border-field bg-surface py-1.5 pr-1.5 pl-4"
        >
          <label htmlFor="ask" className="sr-only">
            Your question
          </label>
          <input
            id="ask"
            value={text}
            onChange={(e) => setText(e.target.value)}
            maxLength={500}
            placeholder={turns.length ? "Ask another question" : "Type your question, for example: How do I start getting support?"}
            className={`${inputClass} h-10 border-0 bg-transparent px-0 focus:ring-0`}
          />
          <Button disabled={pending || text.trim().length < 3} className="rounded-full">
            {pending ? "…" : "Ask"}
          </Button>
        </form>
        <p className="text-center text-xs text-muted">Please don&apos;t type personal or health details here.</p>
      </div>
    </div>
  );
}
