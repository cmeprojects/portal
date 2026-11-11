// Staff Portal · © cmeproject. All rights reserved.
import "server-only";
import { createClient } from "@/lib/supabase/server";
import type { Contract, Signature } from "@/lib/contracts";

// cmeprojects: a contract with its signatures and the names involved (only
// what the signed-in person may see; the database decides).
export async function loadContract(id: string) {
  if (!/^[0-9a-f-]{36}$/.test(id)) return null;
  const supabase = await createClient();
  const [{ data: c }, { data: s }] = await Promise.all([
    supabase.from("contracts").select("*").eq("id", id).maybeSingle(),
    supabase.from("contract_signatures").select("*").eq("contract_id", id).order("signed_at"),
  ]);
  if (!c) return null;
  const contract = c as Contract;
  const signatures = (s ?? []) as Signature[];
  const ids = [...new Set([contract.user_id, contract.sent_by, contract.created_by, ...signatures.map((x) => x.signer_id)].filter(Boolean) as string[])];
  const { data: people } = await supabase.from("profiles").select("id, full_name, email").in("id", ids);
  const nameOf = (u: string | null) => (u ? (people ?? []).find((p) => p.id === u)?.full_name || (people ?? []).find((p) => p.id === u)?.email || "Someone" : "");
  return { contract, signatures, nameOf };
}

export const fmtDateTime = (iso: string | null, timeZone = "Australia/Sydney") =>
  iso ? new Intl.DateTimeFormat("en-AU", { day: "numeric", month: "short", year: "numeric", hour: "numeric", minute: "2-digit", timeZone }).format(new Date(iso)) : "";
