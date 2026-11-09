// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { COUNTRIES, checkPhone, splitPhone } from "@/lib/phone";
import { inputClass } from "@/components/ui";

// cmeprojects: a phone number with its country (Australia by default). It says
// straight away if the number doesn't look right; the server checks it again.
// The boxes keep their own value (not React's), so the form's "unsaved changes"
// check can't wipe the first thing typed.
export function PhoneField({ id, name, label, defaultValue = "", optional = true, showOptional = true }: { id: string; name: string; label: string; defaultValue?: string; optional?: boolean; showOptional?: boolean }) {
  const start = splitPhone(defaultValue);
  const [country, setCountry] = useState(start.country);
  const [value, setValue] = useState(start.local);
  const [touched, setTouched] = useState(false);
  const check = checkPhone(country, value);
  const bad = touched && !check.ok;
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={id} className="text-sm font-medium text-ink">
        {label}
        {optional && showOptional ? " (optional)" : ""}
      </label>
      <div className="flex gap-2">
        <select
          name={`${name}_country`}
          defaultValue={start.country}
          onChange={(e) => setCountry(e.target.value)}
          aria-label={`${label}: country`}
          className={`${inputClass} !w-28 shrink-0 !px-2`}
        >
          {COUNTRIES.map((c) => (
            <option key={c.code} value={c.code}>
              {c.code} +{c.dial}
            </option>
          ))}
        </select>
        <input
          id={id}
          name={name}
          type="tel"
          inputMode="tel"
          autoComplete="tel"
          required={!optional}
          maxLength={25}
          defaultValue={start.local}
          onChange={(e) => setValue(e.target.value)}
          onBlur={() => setTouched(true)}
          placeholder={country === "AU" ? "0412 345 678" : "Number"}
          aria-invalid={bad}
          aria-describedby={`${id}-hint`}
          className={`${inputClass} min-w-0 flex-1 ${bad ? "border-danger focus:border-danger focus:ring-danger/15" : ""}`}
        />
      </div>
      <p id={`${id}-hint`} className={`text-xs ${bad ? "text-danger" : "text-muted"}`}>
        {bad && !check.ok ? check.error : check.ok && check.value && touched ? `Saved as ${check.value}` : country === "AU" ? "Mobile (04…) or landline with area code." : "Without the country code."}
      </p>
    </div>
  );
}
