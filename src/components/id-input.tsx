// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { inputClass } from "@/components/ui";
import { checkAuPhone, checkEmail } from "@/lib/validate";

// cmeprojects (owner, 20 Nov 2026): an NDIS number (9 digits) or a My Aged Care
// ID (AC and 8 digits), checked as it's typed: a wrong one stops the form being
// sent and says why under the field. The server checks again when it's saved.
const RULES = {
  ndis: { test: (v: string) => /^\d{9}$/.test(v.replace(/\s/g, "")), message: "An NDIS number is 9 digits, for example 430 123 456." },
  mac: { test: (v: string) => /^AC\d{8}$/i.test(v.replace(/\s/g, "")), message: "A My Aged Care ID is AC followed by 8 numbers, for example AC12345678." },
  // Australian numbers (standing rule): mobiles, landlines with the area code, 13/1300/1800.
  phone: { test: (v: string) => checkAuPhone(v).ok, message: "Enter an Australian number, for example 0412 345 678 or 02 9876 5432." },
  email: { test: (v: string) => checkEmail(v).ok, message: "Enter a valid email address, for example name@example.com." },
};

export function IdInput({ kind, name, required, disabled, defaultValue = "", placeholder, id }: { kind: keyof typeof RULES; name: string; required?: boolean; disabled?: boolean; defaultValue?: string; placeholder?: string; id?: string }) {
  const [error, setError] = useState("");
  const check = (el: HTMLInputElement, show: boolean) => {
    const v = el.value.trim();
    const bad = v !== "" && !RULES[kind].test(v);
    el.setCustomValidity(bad ? RULES[kind].message : "");
    if (show || !bad) setError(bad ? RULES[kind].message : "");
  };
  return (
    <>
      <input
        id={id}
        name={name}
        type={kind === "email" ? "email" : kind === "phone" ? "tel" : "text"}
        required={required}
        disabled={disabled}
        inputMode={kind === "ndis" ? "numeric" : kind === "phone" ? "tel" : kind === "email" ? "email" : "text"}
        maxLength={kind === "ndis" ? 11 : kind === "mac" ? 12 : kind === "phone" ? 20 : 120}
        placeholder={placeholder}
        defaultValue={defaultValue}
        aria-invalid={error ? true : undefined}
        onChange={(e) => check(e.currentTarget, false)}
        onBlur={(e) => check(e.currentTarget, true)}
        onInvalid={(e) => check(e.currentTarget, true)}
        className={`${inputClass} ${error ? "border-danger" : ""}`}
      />
      {error && !disabled ? <span className="font-normal text-danger">{error}</span> : null}
    </>
  );
}
