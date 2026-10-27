// Staff Portal · © cmeproject. All rights reserved.

export type FormState = { error?: string; message?: string } | null;

export function text(form: FormData, name: string): string {
  const value = form.get(name);
  return typeof value === "string" ? value.trim() : "";
}

export const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
