// Staff Portal · © cmeproject. All rights reserved.
// Website and Assistant: what the portal pages and the website share (safe in the browser).

export type AssistantSettings = {
  model: "haiku" | "sonnet";
  heading: string;
  intro: string;
  disclaimer: string;
  fallback: string;
  phone: string;
  offer_call: boolean;
  log_questions: boolean;
  monthly_limit_aud: number;
  hourly_limit: number;
  suggestions: string[];
  show_credits: boolean;
  scope_public: Scope;
  scope_staff: Scope;
  scope_managers: Scope;
  trusted_sites: string[];
};

// Where the assistant looks for each group.
export type Scope = "documents" | "web" | "both";
export const SCOPE_LABELS: Record<Scope, string> = { documents: "Our documents only", web: "Listed websites only", both: "Documents first, then listed websites" };

// One source shown under an answer.
export type Source = { title: string; url?: string };
export type Answer = { text: string; sources: Source[]; from: "documents" | "web" | "none"; answered: boolean; offerCall: boolean };

export const DEFAULT_SETTINGS: AssistantSettings = {
  model: "haiku",
  heading: "How can we help today?",
  intro: "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.",
  disclaimer: "General information only, not official NDIS advice.",
  fallback: "I can't find that in our documents. Please call us or leave your details and we'll call you.",
  phone: "",
  offer_call: true,
  log_questions: true,
  monthly_limit_aud: 50,
  hourly_limit: 60,
  suggestions: ["What services do you offer?", "What's your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"],
  show_credits: true,
  scope_public: "documents",
  scope_staff: "documents",
  scope_managers: "documents",
  trusted_sites: ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"],
};

export const AUDIENCES = ["public", "staff", "managers"] as const;
export type Audience = (typeof AUDIENCES)[number];
export const AUDIENCE_LABELS: Record<Audience, string> = { public: "Public", staff: "Staff only", managers: "Managers only" };

// The exchange rate used for the monthly limit.
export const AUD_PER_USD = 1.6;
