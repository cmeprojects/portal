// Staff Portal · © cmeproject. All rights reserved.
import { createClient } from "@/lib/supabase/server";
import { Card } from "@/components/ui";
import { WORK_STATUS, maskAccount, type Bank, type Super, type WorkRights } from "@/lib/staff-records";
import { OpenFile, RevealAccount, VerifyRecord } from "./records-buttons";
import { TaxAdmin, type Tax } from "./tax-forms";

const fmt = (d: string | null) => (d ? new Date(`${d.slice(0, 10)}T12:00:00Z`).toLocaleDateString("en-AU", { day: "numeric", month: "short", year: "numeric" }) : "");

function Checked({ at, subject, table, what, canCheck }: { at: string | null; subject: string; table: "staff_bank" | "staff_super" | "staff_work_rights"; what: string; canCheck: boolean }) {
  if (at) return <span className="rounded-full bg-good-soft px-2.5 py-0.5 text-xs font-semibold text-good">Checked {fmt(at)}</span>;
  return canCheck ? <VerifyRecord subject={subject} table={table} what={what} /> : <span className="text-xs text-warn">Not checked yet</span>;
}

// cmeprojects Phase 3: someone's bank, super and work rights, only for people
// whose access covers them (and only what that access allows). Opening it is
// recorded in the access log. Never shown to anyone else.
export async function SensitiveRecords({ subject, viewer }: { subject: string; viewer: string }) {
  if (subject === viewer) return null;
  const supabase = await createClient();
  const [{ data: pay }, { data: ids }, { data: tfn }] = await Promise.all([
    supabase.rpc("has_access", { p_area: "payroll_tax", p_person: subject }),
    supabase.rpc("has_access", { p_area: "identity_docs", p_person: subject }),
    supabase.rpc("has_tfn_access", { p_person: subject }),
  ]);
  if (pay !== true && ids !== true && tfn !== true) return null;
  const { data: taxRow } = tfn === true ? await supabase.from("staff_tax").select("*").eq("user_id", subject).maybeSingle() : { data: null };
  const tax = taxRow as Tax | null;
  const [bank, sup, wr] = await Promise.all([
    pay === true ? supabase.from("staff_bank").select("*").eq("user_id", subject).maybeSingle() : Promise.resolve({ data: null }),
    pay === true ? supabase.from("staff_super").select("*").eq("user_id", subject).maybeSingle() : Promise.resolve({ data: null }),
    ids === true ? supabase.from("staff_work_rights").select("*").eq("user_id", subject).maybeSingle() : Promise.resolve({ data: null }),
  ]);
  const b = bank.data as Bank | null;
  const s = sup.data as Super | null;
  const w = wr.data as WorkRights | null;
  // Recorded before anything is shown.
  const log = [
    ...(pay === true && (b || s) ? [{ subject_id: subject, area: "payroll_tax", action: "view", detail: "Bank and super (masked)" }] : []),
    ...(ids === true && w ? [{ subject_id: subject, area: "identity_docs", action: "view", detail: "Work rights" }] : []),
    ...(tfn === true && tax ? [{ subject_id: subject, area: "payroll_tax", action: "view", detail: "TFN declaration (details)" }] : []),
  ];
  if (log.length) await supabase.from("sensitive_access_log").insert(log);

  return (
    <Card className="flex flex-col gap-4 p-5">
      <div>
        <h2 className="heading-sm">Private records</h2>
        <p className="text-xs text-muted">Only people with access see this. Opening, revealing and downloading are recorded.</p>
      </div>
      {pay === true ? (
        <div className="flex flex-col gap-3 text-sm">
          <div className="flex flex-col gap-1">
            <div className="flex items-center justify-between gap-2">
              <p className="font-semibold">Bank account</p>
              {b ? <Checked at={b.verified_at} subject={subject} table="staff_bank" what="bank details" canCheck /> : null}
            </div>
            {b && b.account_number ? (
              <p>
                {b.account_name} · BSB {b.bsb} · <RevealAccount subject={subject} masked={maskAccount(b.account_number)} />
              </p>
            ) : (
              <p className="text-muted">Not given yet.</p>
            )}
          </div>
          <div className="flex flex-col gap-1">
            <div className="flex items-center justify-between gap-2">
              <p className="font-semibold">Super</p>
              {s ? <Checked at={s.verified_at} subject={subject} table="staff_super" what="super details" canCheck /> : null}
            </div>
            {s && s.fund_name ? (
              <p>
                {s.fund_name}
                {s.member_number ? ` · member ${s.member_number}` : ""}
                {s.usi ? ` · USI ${s.usi}` : ""}
                {s.fund_abn ? ` · ABN ${s.fund_abn}` : ""}
              </p>
            ) : (
              <p className="text-muted">Not given yet.</p>
            )}
            {s?.choice_doc ? <OpenFile subject={subject} which="choice" label="Open choice of fund form" /> : null}
          </div>
        </div>
      ) : null}
      {tfn === true ? (
        <div className="flex flex-col gap-1 text-sm">
          <p className="font-semibold">Tax file number declaration</p>
          {tax?.form_path ? <TaxAdmin subject={subject} tax={tax} /> : <p className="text-muted">Not uploaded yet.</p>}
        </div>
      ) : null}
      {ids === true ? (
        <div className="flex flex-col gap-1 text-sm">
          <div className="flex items-center justify-between gap-2">
            <p className="font-semibold">Right to work</p>
            {w?.status ? <Checked at={w.verified_at} subject={subject} table="staff_work_rights" what="work rights" canCheck /> : null}
          </div>
          {w?.status ? (
            <>
              <p>
                {WORK_STATUS[w.status as keyof typeof WORK_STATUS]}
                {w.status === "visa" ? ` · subclass ${w.visa_subclass}${w.visa_expiry ? ` · expires ${fmt(w.visa_expiry)}` : " · no expiry date given"}` : ""}
              </p>
              {w.visa_conditions ? <p className="text-muted">Conditions: {w.visa_conditions}</p> : null}
              {w.vevo_checked_on ? <p className="text-muted">VEVO checked {fmt(w.vevo_checked_on)}</p> : null}
              <div className="flex flex-wrap gap-2">
                {w.visa_doc ? <OpenFile subject={subject} which="visa" label="Open visa grant notice" /> : null}
                {w.vevo_doc ? <OpenFile subject={subject} which="vevo" label="Open VEVO check" /> : null}
              </div>
            </>
          ) : (
            <p className="text-muted">Not given yet.</p>
          )}
        </div>
      ) : null}
    </Card>
  );
}
