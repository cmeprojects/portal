// Staff Portal · © cmeproject. All rights reserved.
"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { safeFileName } from "@/lib/compliance";
import { inputClass } from "@/components/ui";

const MAX_MB = 10;
// Photos are resized to this many pixels on the longest side before upload.
const MAX_SIDE = 2000;

// Shrinks a phone photo (often 4-8 MB) to a readable JPEG of a few hundred KB.
// PDFs and other files are left as they are.
async function shrinkPhoto(file: File): Promise<File> {
  if (!/^image\/(jpeg|png|webp)$/.test(file.type) || file.size < 400 * 1024) return file;
  try {
    const bitmap = await createImageBitmap(file, { imageOrientation: "from-image" });
    const scale = Math.min(1, MAX_SIDE / Math.max(bitmap.width, bitmap.height));
    const canvas = document.createElement("canvas");
    canvas.width = Math.round(bitmap.width * scale);
    canvas.height = Math.round(bitmap.height * scale);
    const ctx = canvas.getContext("2d");
    if (!ctx) return file;
    ctx.fillStyle = "#ffffff"; // transparent PNGs become white, not black
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
    bitmap.close();
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.8));
    if (!blob || blob.size >= file.size) return file;
    return new File([blob], file.name.replace(/\.[^.]+$/, "") + ".jpg", { type: "image/jpeg" });
  } catch {
    return file;
  }
}

const kb = (n: number) => (n >= 1024 * 1024 ? `${(n / 1024 / 1024).toFixed(1)} MB` : `${Math.max(1, Math.round(n / 1024))} KB`);

// Uploads a file straight to private storage (no size limit on the server),
// shrinking photos first, then puts its path and name in hidden fields for
// the form to save.
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

  async function upload(picked: File | undefined) {
    setState(null);
    onReady?.(false);
    if (!picked) return setStatus("idle");
    setStatus("uploading");
    const file = await shrinkPhoto(picked);
    const shrunk = file !== picked ? ` (shrunk from ${kb(picked.size)} to ${kb(file.size)})` : "";
    if (file.size > maxMb * 1024 * 1024) {
      setStatus("error");
      setMessage(`That file is over ${maxMb} MB. Try a smaller photo or a PDF.`);
      return;
    }
    const path = `${folder}/${Date.now()}-${safeFileName(file.name)}`;
    const { error } = await createClient().storage.from(bucket).upload(path, file, { contentType: file.type || undefined });
    if (error) {
      setStatus("error");
      setMessage("The upload didn't work. Check your connection and try again.");
      return;
    }
    setState({ path, file: file.name });
    setMessage(shrunk);
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
        {status === "uploading"
          ? "Uploading…"
          : status === "done"
            ? `Ready: ${state?.file}${message}`
            : status === "error"
              ? message
              : `Photos are made smaller automatically. Up to ${maxMb} MB.`}
      </p>
    </div>
  );
}
