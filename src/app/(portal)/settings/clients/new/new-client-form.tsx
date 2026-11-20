// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { startTransition, useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, ArrowRight, Save } from "lucide-react";
import { useClientTab, wordForTab } from "../client-tab";
import { Notice, inputClass } from "@/components/ui";
import { askConfirm } from "@/components/confirm";
import { useDirty } from "@/components/use-dirty";
import { Req, RequiredLegend } from "@/components/required";
import { IdInput } from "@/components/id-input";
import { GENDERS, MAC_SCHEMES, STATES, TITLES } from "@/lib/client-sections";
import { createClientFull } from "../actions";
import { DateInput } from "@/components/date-input";

const lab = "flex flex-col gap-1 text-xs font-medium";
const DRAFT = "portal.newClientDraft";

// cmeprojects (owner, 19 Nov 2026): the full New participant form. What was
// typed in the pop-up comes in already filled; nothing is saved until Save.
export function NewClientFullForm({ initial, schemes, staff, word }: { initial: Record<string, string>; schemes: [string, string][]; staff: { id: string; name: string }[] | null; word: string }) {
  const [state, action, pending] = useActionState(createClientFull, null);
  const [scheme, setScheme] = useState(initial.scheme ?? "");
  const [then, setThen] = useState<"continue" | "later">("continue");
  const { ref, dirty, markClean } = useDirty();
  const router = useRouter();
  // The name typed in the pop-up: everything but the last word is the first name.
  const parts = (initial.name ?? "").trim().split(/\s+/).filter(Boolean);
  const given = parts.length > 1 ? parts.slice(0, -1).join(" ") : (parts[0] ?? "");
  const family = parts.length > 1 ? parts[parts.length - 1] : "";

  useEffect(() => {
    if (!state?.spotlight) return;
    markClean();
    try {
      window.localStorage.removeItem(DRAFT);
    } catch {
      /* nothing to clear */
    }
    router.push(then === "continue" && !state.error ? `/settings/clients/${state.spotlight}?edit=basic#locations` : `/settings/clients/${state.spotlight}`);
  }, [state, then, router, markClean]);

  return (
    <form
      ref={ref}
      onSubmit={(e) => {
        e.preventDefault();
        const data = new FormData(e.currentTarget);
        startTransition(() => action(data));
      }}
      className="flex flex-col gap-4"
    >
      <RequiredLegend />
      <section className="shadow-card flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="heading-sm">Name</h2>
        <div className="grid gap-3 sm:grid-cols-[6rem_1fr_1fr_1fr]">
          <label className={lab}>
            Title
            <select name="title" defaultValue="" className={inputClass}>
              {TITLES.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className={lab}>
            <span>
              First name
              <Req />
            </span>
            <input name="given_name" required maxLength={40} defaultValue={given} className={inputClass} />
          </label>
          <label className={lab}>
            Middle name (optional)
            <input name="middle_name" maxLength={40} className={inputClass} />
          </label>
          <label className={lab}>
            <span>
              Last name
              <Req />
            </span>
            <input name="family_name" required maxLength={40} defaultValue={family} className={inputClass} />
          </label>
        </div>
        <label className={`${lab} sm:max-w-sm`}>
          Preferred name (optional)
          <input name="preferred_name" maxLength={80} className={inputClass} />
        </label>
      </section>

      <section className="shadow-card flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="heading-sm">Funding</h2>
        <div className="grid gap-3 sm:grid-cols-2">
          <label className={lab}>
            <span>
              Funded by
              <Req />
            </span>
            <select name="scheme" required value={scheme} onChange={(e) => setScheme(e.target.value)} className={inputClass}>
              <option value="" disabled>
                Choose the scheme
              </option>
              {schemes.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          {/* Both IDs show; the one that doesn't apply is greyed out (owner, 19 Nov 2026). */}
          <label className={lab}>
            <span>
              NDIS number
              {scheme === "ndis" ? <Req /> : <NotApplicable chosen={Boolean(scheme)} />}
            </span>
            <IdInput kind="ndis" name="ndis_number" required={scheme === "ndis"} disabled={scheme !== "ndis"} placeholder={scheme === "ndis" ? "9 digits" : ""} defaultValue={initial.ndis_number ?? ""} />
          </label>
          <label className={lab}>
            <span>
              My Aged Care ID
              {MAC_SCHEMES.includes(scheme) ? <Req /> : <NotApplicable chosen={Boolean(scheme)} />}
            </span>
            <IdInput kind="mac" name="aged_care_id" required={MAC_SCHEMES.includes(scheme)} disabled={!MAC_SCHEMES.includes(scheme)} placeholder={MAC_SCHEMES.includes(scheme) ? "AC12345678" : ""} defaultValue={initial.aged_care_id ?? ""} />
            <span className="font-normal text-muted">For Support at Home and CHSP</span>
          </label>
          <label className={`${lab} sm:col-span-2`}>
            ID from another system (optional)
            <input name="reference" maxLength={60} defaultValue={initial.reference ?? ""} placeholder="e.g. their number in your accounting or old client system" className={inputClass} />
            <span className="font-normal text-muted">The portal gives them a CL- number anyway.</span>
          </label>
        </div>
      </section>

      <section className="shadow-card flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
        <h2 className="heading-sm">Contact details</h2>
        <div className="grid gap-3 sm:grid-cols-2">
          <label className={lab}>
            <span>
              Date of birth
              <Req />
            </span>
            <DateInput name="date_of_birth" required max={new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" })} className={inputClass} />
          </label>
          <label className={lab}>
            Gender (optional)
            <select name="gender" defaultValue="" className={inputClass}>
              {GENDERS.map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className={lab}>
            <span>
              Mobile
              <Req />
            </span>
            <IdInput kind="phone" name="phone" required placeholder="0412 345 678" />
            <span className="font-normal text-muted">If they don&apos;t have one, enter the mobile of the family carer or person assisting them.</span>
          </label>
          <label className={lab}>
            <span>
              Email
              <Req />
            </span>
            <IdInput kind="email" name="email" required placeholder="name@example.com" />
            <span className="font-normal text-muted">If they don&apos;t have one, enter the email of the family carer or person assisting them.</span>
          </label>
          <label className={`${lab} sm:col-span-2`}>
            <span>
              Street address
              <Req />
            </span>
            <input name="home_street" required maxLength={200} placeholder="Unit 3/22 Banksia Road" className={inputClass} />
          </label>
          <label className={lab}>
            <span>
              Suburb
              <Req />
            </span>
            <input name="home_suburb" required maxLength={60} placeholder="Dulwich Hill" className={inputClass} />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className={lab}>
              <span>
                State
                <Req />
              </span>
              <select name="state" required defaultValue="" className={inputClass}>
                {STATES.map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </label>
            <label className={lab}>
              <span>
                Postcode
                <Req />
              </span>
              <input name="home_postcode" required inputMode="numeric" pattern="\d{4}" maxLength={4} placeholder="2203" title="4 numbers" className={inputClass} />
            </label>
          </div>
        </div>
      </section>

      {staff ? (
        <section className="shadow-card flex flex-col gap-3 rounded-xl border border-line bg-surface p-4">
          <h2 className="heading-sm">Who manages them</h2>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className={lab}>
              Managed by
              <select name="manager_id" defaultValue={initial.manager_id ?? ""} className={inputClass}>
                <option value="">Choose later</option>
                {staff.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
            <label className={lab}>
              As
              <select name="assigned_as" defaultValue={initial.assigned_as ?? "case_manager"} className={inputClass}>
                <option value="case_manager">Care manager</option>
                <option value="support_coordinator">Support coordinator</option>
              </select>
            </label>
          </div>
        </section>
      ) : null}

      <div className="sticky bottom-0 z-30 -mx-4 border-t border-line bg-surface/95 px-4 py-3 shadow-[0_-4px_12px_rgb(0_0_0/0.06)] backdrop-blur md:-mx-8 md:px-8">
        <div className="flex flex-wrap items-center gap-2">
          <p className="min-w-0 flex-1 text-sm text-muted">Not saved yet. They&apos;re added as &ldquo;To check&rdquo; when you save.</p>
          <button
            type="button"
            onClick={async () => {
              if (!dirty || (await askConfirm(`Leave without adding this ${word.toLowerCase()}? What you typed here isn't saved.`, { action: "Leave" }))) {
                markClean();
                router.push("/settings/clients");
              }
            }}
            className="inline-flex items-center gap-1.5 rounded-lg px-4 py-2 text-sm font-semibold text-muted hover:bg-page hover:text-ink"
          >
            <ArrowLeft aria-hidden="true" className="size-4" /> Back to client list
          </button>
          <button type="submit" onClick={() => setThen("later")} disabled={pending} className="inline-flex items-center gap-1.5 rounded-lg border border-field bg-surface px-4 py-2 text-sm font-semibold text-ink shadow-sm hover:bg-page disabled:opacity-50">
            <Save aria-hidden="true" className="size-4" /> {pending && then === "later" ? "Saving…" : "Save for later"}
          </button>
          <button type="submit" onClick={() => setThen("continue")} disabled={pending} className="inline-flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-brand-fg shadow-sm hover:opacity-90 disabled:opacity-50">
            {pending && then === "continue" ? "Saving…" : "Save and continue"} <ArrowRight aria-hidden="true" className="size-4" />
          </button>
        </div>
        {state?.error ? (
          <div className="mt-2">
            <Notice tone="error">{state.error}</Notice>
          </div>
        ) : null}
      </div>
    </form>
  );
}

// cmeprojects (owner, 19 Nov 2026): the page heading follows the client list's tab:
// New participant (NDIS), New client (Support at Home, CHSP), otherwise the organisation's word.
export function NewClientHeading({ word, schemes, schemeWords = {} }: { word: string; schemes: [string, string][]; schemeWords?: Record<string, string> }) {
  const tab = useClientTab(schemes);
  return <>New {wordForTab(tab, word, schemeWords).toLowerCase()}</>;
}

// Shown on the ID that doesn't apply to the chosen scheme (or until one is chosen).
function NotApplicable({ chosen }: { chosen: boolean }) {
  return <span className="ml-1.5 rounded-full bg-line px-1.5 py-0.5 text-[10px] font-semibold text-muted">{chosen ? "Not applicable" : "Choose Funded by first"}</span>;
}
