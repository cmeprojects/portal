// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { safeFileName } from "@/lib/compliance";
import { inputClass } from "@/components/ui";

const MAX_MB = 10;

// Uploads a file straight to private storage (no size limit on the server),
// then puts its path and name in hidden fields for the form to save.
export function FileUpload({
  id,
  bucket,
  folder,
  name,
  accept = "application/pdf,image/*,.doc,.docx",
  required = false,
  maxMb = MAX_MB,
  onReady,
}: {
  id: string;
  bucket: string;
  folder: string;
  name: string;
  accept?: string;
  required?: boolean;
  maxMb?: number;
  onReady?: (ready: boolean) => void;
}) {
  const [state, setState] = useState<{ path: string; file: string } | null>(null);
  const [status, setStatus] = useState<"idle" | "uploading" | "done" | "error">("idle");
  const [message, setMessage] = useState("");

  async function upload(file: File | undefined) {
    setState(null);
    onReady?.(false);
    if (!file) return setStatus("idle");
    if (file.size > maxMb * 1024 * 1024) {
      setStatus("error");
      setMessage(`That file is over ${maxMb} MB. Try a smaller photo or a PDF.`);
      return;
    }
    setStatus("uploading");
    const path = `${folder}/${Date.now()}-${safeFileName(file.name)}`;
    const { error } = await createClient().storage.from(bucket).upload(path, file, { contentType: file.type || undefined });
    if (error) {
      setStatus("error");
      setMessage("The upload didn't work. Check your connection and try again.");
      return;
    }
    setState({ path, file: file.name });
    setStatus("done");
    onReady?.(true);
  }

  return (
    <div className="flex flex-col gap-1.5">
      <input
        id={id}
        type="file"
        accept={accept}
        required={required && !state}
        onChange={(e) => upload(e.target.files?.[0])}
        className={`${inputClass} py-2 file:mr-3 file:rounded-full file:border-0 file:bg-brand-soft file:px-3 file:py-1.5 file:text-sm file:font-semibold file:text-brand`}
      />
      {state ? (
        <>
          <input type="hidden" name={`${name}_path`} value={state.path} />
          <input type="hidden" name={`${name}_name`} value={state.file} />
        </>
      ) : null}
      <p aria-live="polite" className={`text-sm ${status === "error" ? "text-danger" : "text-muted"}`}>
        {status === "uploading" ? "Uploading…" : status === "done" ? `Ready: ${state?.file}` : status === "error" ? message : `Up to ${maxMb} MB.`}
      </p>
    </div>
  );
}
