// Staff Portal · © cmeproject. All rights reserved.
import "server-only";

export type Address = { email: string; name?: string };
export type Message = { to: Address; cc: Address[]; subject: string; html: string; text: string };

function fromAddress(): Address {
  // For example: "Engaged Care <tasks@engagedcare.com.au>"
  const raw = process.env.EMAIL_FROM ?? "Staff Portal <no-reply@example.com>";
  const m = raw.match(/^\s*(.*?)\s*<([^>]+)>\s*$/);
  return m ? { name: m[1], email: m[2] } : { email: raw.trim() };
}

const fmt = (a: Address) => (a.name ? `${a.name.replace(/[<>"]/g, "")} <${a.email}>` : a.email);

// Sends one email. Uses Resend when RESEND_API_KEY is set; on a developer's
// computer it can use the local Supabase test inbox (MAILPIT_URL). With
// neither set it reports "not configured" and the email stays queued.
export async function sendEmail(msg: Message): Promise<void> {
  const from = fromAddress();

  if (process.env.RESEND_API_KEY) {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${process.env.RESEND_API_KEY}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: fmt(from),
        to: [fmt(msg.to)],
        cc: msg.cc.map(fmt),
        subject: msg.subject,
        html: msg.html,
        text: msg.text,
      }),
    });
    if (!res.ok) throw new Error(`Resend ${res.status}: ${(await res.text()).slice(0, 300)}`);
    return;
  }

  if (process.env.MAILPIT_URL) {
    const res = await fetch(`${process.env.MAILPIT_URL.replace(/\/$/, "")}/api/v1/send`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        From: { Email: from.email, Name: from.name ?? "" },
        To: [{ Email: msg.to.email, Name: msg.to.name ?? "" }],
        Cc: msg.cc.map((c) => ({ Email: c.email, Name: c.name ?? "" })),
        Subject: msg.subject,
        HTML: msg.html,
        Text: msg.text,
      }),
    });
    if (!res.ok) throw new Error(`Test inbox ${res.status}`);
    return;
  }

  throw new Error("Email sending is not set up (add RESEND_API_KEY)");
}
