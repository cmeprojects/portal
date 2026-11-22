// Staff Portal · © cmeproject. All rights reserved.
// cmeprojects (update 163): the business details form's fields (shared by the server page and the form).
export type Business = {
  legal_name: string; trading_name: string; abn: string; address: string; suburb: string; state: string; postcode: string; phone: string; email: string;
  gst_registered: boolean; prices_include_gst: boolean; gst_verified_by_name: string; gst_verified_on: string; gst_evidence: string;
  ndis_registration_number: string; sah_provider_id: string; sah_service_branch: string;
  payment_account_name: string; payment_bsb: string; payment_account_number: string; payment_other: string; payment_terms_days: string; note: string;
};
export const EMPTY_BUSINESS: Business = {
  legal_name: "", trading_name: "", abn: "", address: "", suburb: "", state: "NSW", postcode: "", phone: "", email: "", gst_registered: false, prices_include_gst: true,
  gst_verified_by_name: "", gst_verified_on: "", gst_evidence: "", ndis_registration_number: "", sah_provider_id: "", sah_service_branch: "",
  payment_account_name: "", payment_bsb: "", payment_account_number: "", payment_other: "", payment_terms_days: "14", note: "",
};
// Saved values for the form (nulls become blanks).
export function businessForForm(row: Record<string, unknown> | null): Business {
  if (!row) return { ...EMPTY_BUSINESS };
  const out = { ...EMPTY_BUSINESS } as Record<string, unknown>;
  for (const k of Object.keys(EMPTY_BUSINESS)) {
    const v = row[k];
    out[k] = typeof EMPTY_BUSINESS[k as keyof Business] === "boolean" ? v === true : v === null || v === undefined ? "" : String(v);
  }
  return out as Business;
}
