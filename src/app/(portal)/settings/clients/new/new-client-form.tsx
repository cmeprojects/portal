// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { startTransition, useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowRight, List, LogOut, Save } from "lucide-react";
import { FloatIcon } from "@/components/page-save";
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
type ProgramChoice = { id: string; name: string; scheme: string; schemeLabel: string };

export function NewClientFullForm({ initial, programs, staff, word }: { initial: Record<string, string>; schemes: [string, string][]; programs: ProgramChoice[]; staff: { id: string; name: string }[] | null; word: string }) {
  const [state, action, pending] = useActionState(createClientFull, null);
  // cmeprojects (update 158): one or more programs; the main one sets "Funded by".
  const [picked, setPicked] = useState<string[]>(() => {
    const first = programs.find((p) => p.scheme === initial.scheme);
    return first ? [first.id] : [];
  });
  const [main, setMain] = useState("");
  const pickedSchemes = programs.filter((p) => picked.includes(p.id)).map((p) => p.scheme);
  const mainId = picked.includes(main) ? main : (picked[0] ?? "");
  // The NDIS number and My Aged Care ID follow the programs ticked (any of them).
  const needsNdis = pickedSchemes.includes("ndis");
  const needsMac = pickedSchemes.some((k) => MAC_SCHEMES.includes(k));
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

  // Leaving without saving asks first (nothing is saved until Save).
  const leave = async () => {
    if (!dirty || (await askConfirm(`Leave without adding this ${word.toLowerCase()}? What you typed here isn't saved.`, { action: "Leave" }))) {
      markClean();
      router.push("/settings/clients");
    }
  };
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
          <fieldset className="flex flex-col gap-2 sm:col-span-2">
            <legend className="mb-1 text-xs font-medium">
              Programs
              <Req />
              <span className="ml-1 font-normal text-muted">Tick every program they&apos;re in.</span>
            </legend>
            {[...new Set(programs.map((p) => p.schemeLabel))].map((label) => (
              <div key={label} className="flex flex-wrap items-center gap-x-4 gap-y-1">
                <span className="w-32 text-xs font-semibold text-muted">{label}</span>
                {programs
                  .filter((p) => p.schemeLabel === label)
                  .map((p) => (
                    <label key={p.id} className="inline-flex min-h-9 items-center gap-2 text-sm">
                      <input
                        type="checkbox"
                        name="program_ids"
                        value={p.id}
                        checked={picked.includes(p.id)}
                        onChange={(e) => setPicked((now) => (e.target.checked ? [...now, p.id] : now.filter((x) => x !== p.id)))}
                        className="size-4 accent-[var(--brand-primary)]"
                      />
                      {p.name}
                    </label>
                  ))}
              </div>
            ))}
            {programs.length === 0 ? <p className="text-sm text-warn">No programs are offered yet. A Manager Administrator sets them up in Portal settings, Programs and schemes.</p> : null}
            <input type="hidden" name="main_program" value={mainId} />
            {picked.length > 1 ? (
              <label className={`${lab} max-w-sm`}>
                Main program
                <select value={mainId} onChange={(e) => setMain(e.target.value)} className={inputClass}>
                  {programs
                    .filter((p) => picked.includes(p.id))
                    .map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.name}
                      </option>
                    ))}
                </select>
                <span className="font-normal text-muted">Shown as &ldquo;Funded by&rdquo; and used for the page wording.</span>
              </label>
            ) : null}
            <label className={`${lab} max-w-xs`}>
              In these programs from
              <DateInput name="programs_from" defaultValue={new Date().toLocaleDateString("en-CA", { timeZone: "Australia/Sydney" })} />
            </label>
          </fieldset>
          {/* Both IDs show; the one that doesn't apply is greyed out (owner, 19 Nov 2026). */}
          <label className={lab}>
            <span>
              NDIS number
              {needsNdis ? <Req /> : <NotApplicable chosen={picked.length > 0} />}
            </span>
            <IdInput kind="ndis" name="ndis_number" required={needsNdis} disabled={!needsNdis} placeholder={needsNdis ? "9 digits" : ""} defaultValue={initial.ndis_number ?? ""} />
          </label>
          <label className={lab}>
            <span>
              My Aged Care ID
              {needsMac ? <Req /> : <NotApplicable chosen={picked.length > 0} />}
            </span>
            <IdInput kind="mac" name="aged_care_id" required={needsMac} disabled={!needsMac} placeholder={needsMac ? "AC12345678" : ""} defaultValue={initial.aged_care_id ?? ""} />
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

      {/* Client list and Exit as floating icons, named on hover (owner, 20 Nov 2026). Both go to the client list here. */}
      <div className="fixed right-4 bottom-24 z-30 flex flex-col items-end gap-2 md:right-8 print:hidden">
        <FloatIcon label="Back to client list" icon={<List aria-hidden="true" className="size-4" />} onClick={leave} />
        <FloatIcon label="Exit without adding" icon={<LogOut aria-hidden="true" className="size-4" />} onClick={leave} />
      </div>
      <div className="sticky bottom-0 z-30 -mx-4 border-t border-line bg-surface/95 px-4 py-3 shadow-[0_-4px_12px_rgb(0_0_0/0.06)] backdrop-blur md:-mx-8 md:px-8">
        <div className="flex flex-wrap items-center gap-2">
          <p className="min-w-0 flex-1 text-sm text-muted">Not saved yet. They&apos;re added as &ldquo;To check&rdquo; when you save.</p>
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
