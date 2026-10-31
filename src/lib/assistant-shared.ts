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
};

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
};

export const AUDIENCES = ["public", "staff", "managers"] as const;
export type Audience = (typeof AUDIENCES)[number];
export const AUDIENCE_LABELS: Record<Audience, string> = { public: "Public", staff: "Staff only", managers: "Managers only" };

// The exchange rate used for the monthly limit.
export const AUD_PER_USD = 1.6;
