// Staff Portal · © cmeproject. All rights reserved.
import Link from "next/link";
import { getBranding } from "@/lib/branding";
import { assistantOn, getVisitor, getWebsiteLook, loadSettings } from "@/lib/assistant";
import { createClient } from "@/lib/supabase/server";
import type { Source } from "@/lib/assistant-shared";
import { Chat, type ChatTurn } from "./chat";
import { SiteHeader } from "./site-header";

// Answers (with an AI or web search) can take a few seconds: allow up to a minute.
export const maxDuration = 60;

// cmeprojects: the website's landing page and chat. Answers come only from
// the documents (and listed websites) the system admin chose.
export default async function AskPage({ searchParams }: PageProps<"/ask">) {
  const [brand, on, visitor, query] = await Promise.all([getBranding(), assistantOn(), getVisitor(), searchParams]);
  const me = visitor.userId ? { name: visitor.name, position: visitor.position } : null;
  const look = await getWebsiteLook(brand.logoUrl);
  if (!on) {
    return (
      <>
        <SiteHeader logoUrl={look.logoUrl} companyName={brand.companyName} signedIn={Boolean(me)} />
        <main className="mx-auto flex w-full max-w-xl flex-1 flex-col justify-center gap-3 px-4 py-16 text-center">
          <h1 className="heading">{look.closedTitle}</h1>
          <p className="whitespace-pre-line text-muted">{look.closedText}</p>
          {me ? null : (
            <Link href="/login" className="mx-auto text-brand underline">
              Sign in
            </Link>
          )}
        </main>
      </>
    );
  }

  const s = await loadSettings();
  // Signed in: their saved chats, and the one they opened.
  let chats: { id: string; title: string }[] = [];
  let turns: ChatTurn[] = [];
  const chatId = typeof query.chat === "string" && /^[0-9a-f-]{36}$/.test(query.chat) ? query.chat : null;
  if (me) {
    const supabase = await createClient();
    const [{ data: list }, { data: msgs }] = await Promise.all([
      supabase.from("assistant_chats").select("id, title").order("updated_at", { ascending: false }).limit(40),
      chatId ? supabase.from("assistant_messages").select("question, answer, sources, answered").eq("chat_id", chatId).order("id") : Promise.resolve({ data: [] }),
    ]);
    chats = list ?? [];
    turns = (msgs ?? []).map((m) => ({ q: m.question, a: { text: m.answer, sources: (m.sources ?? []) as Source[], answered: m.answered, from: "documents", offerCall: false } }));
  }

  return (
    <Chat
      key={chatId ?? "new"}
      brand={{ logoUrl: look.logoUrl, companyName: brand.companyName }}
      visitor={me}
      heading={s.heading}
      intro={s.intro}
      suggestions={s.suggestions}
      offerCall={s.offer_call}
      phone={s.phone}
      disclaimer={s.disclaimer}
      showCredits={s.show_credits}
      chats={chats}
      chatId={me ? chatId : null}
      initialTurns={turns}
    />
  );
}
