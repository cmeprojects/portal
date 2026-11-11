// Staff Portal · © cmeproject. All rights reserved.
"use server";

import { headers } from "next/headers";
import { revalidatePath } from "next/cache";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { friendlyError } from "@/lib/db-error";
import { confirmIdentity } from "@/lib/reauth";
import { getBranding } from "@/lib/branding";
import { getTimeZone } from "@/lib/settings";
import type { FormState } from "@/lib/form";
import { CONSENT_TEXT, CONTRACTS_BUCKET, type Contract, type Signature } from "@/lib/contracts";
import { buildSignedPdf, logoForPdf, sha256 } from "@/lib/contract-pdf";
import { env } from "@/lib/env";

const UUID = /^[0-9a-f-]{36}$/;
const str = (f: FormData, k: string, max: number) => String(f.get(k) ?? "").trim().slice(0, max);

function done(id?: string) {
  revalidatePath("/contracts");
  revalidatePath("/account/contracts");
  if (id) {
    revalidatePath(`/contracts/${id}`);
    revalidatePath(`/account/contracts/${id}`);
  }
}

// cmeprojects: a bell (and email) to one person, sent after the database has
// accepted the change. Never includes the contract wording.
async function tell(userId: string | null | undefined, title: string, body: string, href: string) {
  if (!userId) return;
  try {
    await createAdminClient().rpc("notify", { p_user: userId, p_kind: "onboarding_item", p_title: title, p_body: body, p_href: href, p_email: true });
  } catch {
    // The contract still moved on; the bell is a courtesy.
  }
}

// --- Preparing (people with Staff details access) -----------------------------

export async function saveDraft(_: FormState, form: FormData): Promise<FormState> {
  await requireSession();
  const id = str(form, "id", 40);
  const userId = str(form, "user_id", 40);
  const title = str(form, "title", 200);
  const body = String(form.get("body") ?? "").slice(0, 100000);
  const signBy = str(form, "sign_by", 10);
  const supersedes = str(form, "supersedes", 40);
  if (title.length < 2) return { error: "Give the contract a title." };
  if (body.trim().length < 20) return { error: "Add the contract wording." };
  if (signBy && !/^\d{4}-\d{2}-\d{2}$/.test(signBy)) return { error: "Choose a valid sign-by date." };
  const supabase = await createClient();
  if (id) {
    if (!UUID.test(id)) return { error: "Something went wrong." };
    const { data, error } = await supabase.from("contracts").update({ title, body, sign_by: signBy || null, letterhead: form.get("letterhead") === "on" }).eq("id", id).eq("status", "draft").select("id");
    if (error) return { error: friendlyError(error) };
    if (!data?.length) return { error: "Only drafts can be changed. Make a new version instead." };
    done(id);
    return { message: "Draft saved." };
  }
  if (!UUID.test(userId)) return { error: "Choose the employee." };
  const { data, error } = await supabase
    .from("contracts")
    .insert({ user_id: userId, title, body, sign_by: signBy || null, letterhead: form.get("letterhead") === "on", supersedes: UUID.test(supersedes) ? supersedes : null })
    .select("id")
    .single();
  if (error) return { error: error.code === "42501" ? "You don't have access to prepare contracts for this person." : friendlyError(error) };
  done(data.id);
  return { message: `saved:${data.id}` };
}

async function setStatus(id: string, status: string) {
  if (!UUID.test(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("contracts").update({ status }).eq("id", id).select("id, user_id, title, sent_by");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You can't do that to this contract." };
  done(id);
  return { row: data[0] as { id: string; user_id: string; title: string; sent_by: string | null } };
}

export async function sendContract(id: string): Promise<FormState> {
  const r = await setStatus(id, "awaiting_employee");
  if ("error" in r) return { error: r.error };
  await tell(r.row.user_id, `Please read and sign: ${r.row.title}`, "Your contract is ready to sign in the Staff Portal.", `/account/contracts/${id}`);
  return { message: "Sent. They've been asked to sign it." };
}

export async function cancelContract(id: string): Promise<FormState> {
  const r = await setStatus(id, "cancelled");
  return "error" in r ? { error: r.error } : { message: "Contract cancelled. It's kept in the history." };
}

export async function deleteDraft(id: string): Promise<FormState> {
  if (!UUID.test(id)) return { error: "Something went wrong." };
  const { data, error } = await (await createClient()).from("contracts").delete().eq("id", id).eq("status", "draft").select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "Only drafts can be deleted." };
  done();
  return { message: "Draft deleted." };
}

// --- Signing ---------------------------------------------------------------

async function uploadSignature(contract: Contract, party: string, dataUrl: string): Promise<string | null> {
  const m = /^data:image\/png;base64,([A-Za-z0-9+/=]+)$/.exec(dataUrl);
  if (!m) return null;
  const bytes = Buffer.from(m[1], "base64");
  if (bytes.length < 200 || bytes.length > 600_000) return null;
  const path = `${contract.user_id}/${contract.id}/${party}-signature-${Date.now()}.png`;
  const { error } = await (await createClient()).storage.from(CONTRACTS_BUCKET).upload(path, bytes, { contentType: "image/png" });
  return error ? null : path;
}

export async function signContract(_: FormState, form: FormData): Promise<FormState> {
  const { profile } = await requireSession();
  const id = str(form, "id", 40);
  if (!UUID.test(id)) return { error: "Something went wrong." };
  if (form.get("consent") !== "on") return { error: "Tick the box to agree to sign electronically." };
  const name = str(form, "signed_name", 120);
  if (name.length < 2) return { error: "Type your full name." };
  const secret = String(form.get("secret") ?? "");
  const check = await confirmIdentity(secret);
  if (!check.ok) return { error: check.error };

  const supabase = await createClient();
  const { data: c } = await supabase.from("contracts").select("*").eq("id", id).maybeSingle();
  const contract = c as Contract | null;
  if (!contract) return { error: "You don't have access to this contract." };
  const party = contract.user_id === profile.id ? "employee" : "employer";
  if (party === "employee" && contract.status !== "awaiting_employee") return { error: "This contract isn't waiting for your signature." };
  if (party === "employer" && contract.status !== "awaiting_employer") return { error: "This contract isn't waiting for the employer's signature." };
  // The wording on screen must be the wording sent.
  if (str(form, "content_hash", 64) !== contract.content_hash) return { error: "This contract has changed since you opened it. Please reload the page." };

  const path = await uploadSignature(contract, party, String(form.get("signature") ?? ""));
  if (!path) return { error: "Draw your signature in the box, then try again." };
  const h = await headers();
  const { error } = await supabase.from("contract_signatures").insert({
    contract_id: id,
    party,
    signed_name: name,
    signature_path: path,
    consent_text: CONSENT_TEXT,
    content_hash: contract.content_hash,
    identity_check: /^\d{6}$/.test(secret.trim()) ? "authenticator" : "password",
    ip: (h.get("x-forwarded-for") ?? "").split(",")[0].trim().slice(0, 64),
    user_agent: (h.get("user-agent") ?? "").slice(0, 300),
  });
  if (error) return { error: error.code === "42501" ? "This contract can't be signed by you right now." : friendlyError(error) };

  if (party === "employee") {
    await tell(contract.sent_by, `${profile.full_name || "An employee"} signed: ${contract.title}`, "It's ready for the employer's signature.", `/contracts/${id}`);
    done(id);
    return { message: "Signed. Thank you. You'll get the signed copy once the employer has signed too." };
  }
  const r = await finishContract(id);
  if (r?.error) return { error: `Your signature is saved, but the signed copy couldn't be made yet: ${r.error} Use "Finish" to try again.` };
  return { message: "Signed. The contract is fully signed and the signed copy is saved." };
}

// Builds the signed PDF, stores it with its SHA-256, and marks the contract fully signed.
// Safe to run again if an earlier try didn't finish.
export async function finishContract(id: string): Promise<FormState> {
  await requireSession();
  if (!UUID.test(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const [{ data: c }, { data: sigs }] = await Promise.all([
    supabase.from("contracts").select("*").eq("id", id).maybeSingle(),
    supabase.from("contract_signatures").select("*").eq("contract_id", id).order("signed_at"),
  ]);
  const contract = c as Contract | null;
  const signatures = (sigs ?? []) as Signature[];
  if (!contract || contract.status !== "awaiting_employer") return { error: "This contract isn't ready to finish." };
  if (!signatures.some((s) => s.party === "employer") || !signatures.some((s) => s.party === "employee")) return { error: "Both signatures are needed." };
  const ids = [...new Set([contract.user_id, ...signatures.map((s) => s.signer_id)])];
  const [{ data: people }, brand, timeZone] = await Promise.all([supabase.from("profiles").select("id, full_name, email").in("id", ids), getBranding(), getTimeZone()]);
  const nameOf = new Map((people ?? []).map((p) => [p.id, `${p.full_name || p.email} (${p.email})`]));
  const withImages = [];
  for (const s of signatures) {
    const { data: file } = await supabase.storage.from(CONTRACTS_BUCKET).download(s.signature_path);
    if (!file) return { error: "A signature image couldn't be read." };
    withImages.push({ ...s, signerName: nameOf.get(s.signer_id) ?? "Unknown", image: new Uint8Array(await file.arrayBuffer()) });
  }
  const logo = contract.letterhead !== false ? await logoForPdf(brand.logoUrl, env.siteUrl) : null;
  const bytes = await buildSignedPdf({
    logo,
    brandColour: brand.colorPrimary,
    company: brand.companyName,
    contract,
    employeeName: (nameOf.get(contract.user_id) ?? "").replace(/ \(.*\)$/, ""),
    signatures: withImages,
    timeZone,
  });
  const hash = sha256(bytes);
  const path = `${contract.user_id}/${contract.id}/signed-v${contract.version}-${hash.slice(0, 12)}.pdf`;
  const up = await supabase.storage.from(CONTRACTS_BUCKET).upload(path, bytes, { contentType: "application/pdf" });
  if (up.error && !/exists/i.test(up.error.message)) return { error: "The signed copy couldn't be saved." };
  const { data, error } = await supabase.from("contracts").update({ status: "fully_signed", signed_pdf_path: path, signed_pdf_hash: hash }).eq("id", id).select("id");
  if (error) return { error: friendlyError(error) };
  if (!data?.length) return { error: "You don't have access to finish this contract." };
  await tell(contract.user_id, `Fully signed: ${contract.title}`, "Your signed copy is in My account → My contracts.", `/account/contracts/${id}`);
  done(id);
  return { message: "Fully signed." };
}

// A 60-second link to the signed copy.
export async function openSignedCopy(id: string): Promise<{ url?: string; error?: string }> {
  await requireSession();
  if (!UUID.test(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data } = await supabase.from("contracts").select("signed_pdf_path").eq("id", id).maybeSingle();
  if (!data?.signed_pdf_path) return { error: "There's no signed copy yet." };
  const { data: signed } = await supabase.storage.from(CONTRACTS_BUCKET).createSignedUrl(data.signed_pdf_path, 60, { download: true });
  return signed ? { url: signed.signedUrl } : { error: "The signed copy couldn't be opened." };
}

// Checks the stored signed copy still matches the SHA-256 kept when it was signed.
export async function checkSignedCopy(id: string): Promise<{ ok?: boolean; error?: string }> {
  await requireSession();
  if (!UUID.test(id)) return { error: "Something went wrong." };
  const supabase = await createClient();
  const { data } = await supabase.from("contracts").select("signed_pdf_path, signed_pdf_hash").eq("id", id).maybeSingle();
  if (!data?.signed_pdf_path) return { error: "There's no signed copy yet." };
  const { data: file } = await supabase.storage.from(CONTRACTS_BUCKET).download(data.signed_pdf_path);
  if (!file) return { error: "The signed copy couldn't be read." };
  return { ok: sha256(new Uint8Array(await file.arrayBuffer())) === data.signed_pdf_hash };
}
