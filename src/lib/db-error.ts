// Staff Portal · © cmeproject. All rights reserved.
import type { PostgrestError } from "@supabase/supabase-js";

// Turns a database refusal into a plain-English message. Our own rules
// (raised in the database) are already written for people to read.
export function friendlyError(error: PostgrestError | null, fallback = "That didn't save. Please try again."): string {
  if (!error) return fallback;
  if (error.code === "P0001") return error.message;
  if (error.code === "23505") return "That name is already in use.";
  if (error.code === "42501") return "You don't have permission to do that.";
  return fallback;
}
