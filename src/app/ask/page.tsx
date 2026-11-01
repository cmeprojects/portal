// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { assistantOn, getVisitor, getWebsiteContent, loadSettings } from "@/lib/assistant";
import { createClient } from "@/lib/supabase/server";
import type { Source } from "@/lib/assistant-shared";
import { ROLE_LABELS, type Role } from "@/lib/roles";
import { Chat, type ChatTurn } from "./chat";
import { SiteHeader } from "./site-header";
import { websiteMetadata } from "./seo";

// Answers (with an AI or web search) can take a few seconds: allow up to a minute.
export const maxDuration = 60;

export async function generateMetadata(): Promise<Metadata> {
  return websiteMetadata("/");
}

// cmeprojects: the website's landing page and chat. Answers come only from
// the documents (and listed websites) chosen in Website settings.
export default async function AskPage({ searchParams }: PageProps<"/ask">) {
  const [brand, on, visitor, query] = await Promise.all([getBranding(), assistantOn(), getVisitor(), searchParams]);
  const [site, settings] = await Promise.all([getWebsiteContent(brand.logoUrl), loadSettings()]);
  const me = visitor.userId ? { name: visitor.name, position: visitor.position } : null;

  if (!on) {
    return (
      <>
        <SiteHeader logoUrl={site.logoUrl} companyName={brand.companyName} signedIn={Boolean(me)} />
        <main className="mx-auto flex w-full max-w-xl flex-1 flex-col justify-center gap-3 px-4 py-16 text-center">
          <h1 className="heading">{site.closedTitle}</h1>
          <p className="whitespace-pre-line text-muted">{site.closedText}</p>
        </main>
      </>
    );
  }

  // Signed in: their saved chats, and the one they opened.
  const chatId = typeof query.chat === "string" && /^[0-9a-f-]{36}$/.test(query.chat) ? query.chat : null;
  let chats: { id: string; title: string }[] = [];
  let turns: ChatTurn[] = [];
  let answerers: { id: string; name: string; detail: string }[] = [];
  if (me) {
    const supabase = await createClient();
    const [{ data: list }, { data: messages }, { data: leads }] = await Promise.all([
      supabase.from("assistant_chats").select("id, title").order("updated_at", { ascending: false }).limit(40),
      chatId ? supabase.from("assistant_messages").select("question, answer, sources, answered").eq("chat_id", chatId).order("id") : Promise.resolve({ data: [] }),
      // Who a staff question can go to.
      supabase.from("profiles").select("id, full_name, role").eq("active", true).in("role", ["manager", "team_leader", "staff_admin"]).neq("id", visitor.userId!).order("full_name"),
    ]);
    chats = list ?? [];
    answerers = (leads ?? []).map((p) => ({ id: p.id, name: p.full_name, detail: ROLE_LABELS[p.role as Role] ?? "" }));
    turns = (messages ?? []).map((m) => ({ q: m.question, a: { text: m.answer, sources: (m.sources ?? []) as Source[], answered: m.answered, from: "documents", offerCall: false } }));
  }

  return (
    <Chat
      key={chatId ?? "new"}
      brand={{ logoUrl: site.logoUrl, companyName: brand.companyName }}
      staff={me ? { ...me, answerers } : null}
      heading={settings.heading}
      intro={settings.intro}
      suggestions={settings.suggestions}
      offerCall={settings.offer_call}
      urgentPhone={settings.phone}
      staffPhone={site.staffPhone}
      disclaimer={settings.disclaimer}
      showCredits={settings.show_credits}
      chats={chats}
      chatId={me ? chatId : null}
      initialTurns={turns}
    />
  );
}
