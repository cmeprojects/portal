// Staff Portal · © cmeproject. All rights reserved.
import { STATUS_LABELS, type Status } from "@/lib/tasks";

export type TaskEvent = {
  type: string;
  actor_id: string | null;
  from_value: string | null;
  to_value: string | null;
  comment: string | null;
};

// A task's history in plain words ("Sam started working on it").
export function describeEvent(e: TaskEvent, nameOf: (id: string | null) => string, actionTitle?: (id: string | null) => string | undefined): string {
  switch (e.type) {
    case "created":
      return `created the task and asked ${nameOf(e.to_value)} to look after it`;
    case "helper_added":
      return `added ${nameOf(e.to_value)} as a helper`;
    case "details_changed":
      return `updated ${e.comment}`;
    case "action_added": {
      const title = actionTitle?.(e.to_value);
      return title ? `added a follow-up action: ${title}` : "added a follow-up action";
    }
    case "comment":
      return "commented";
    case "status_changed": {
      const to = e.to_value as Status;
      if (to === "awaiting_approval") return "finished it and sent it for approval";
      if (to === "escalated") return "escalated it";
      if (to === "closed") return "closed it";
      if (to === "completed") return e.from_value === "awaiting_approval" ? "approved it" : "marked it as completed";
      if (to === "in_progress") {
        if (e.from_value === "awaiting_approval") return "sent it back";
        if (e.from_value === "completed" || e.from_value === "closed") return "reopened it";
        if (e.from_value === "escalated") return "dealt with the escalation";
        return "started working on it";
      }
      return `changed the status to ${STATUS_LABELS[to] ?? to}`;
    }
    case "reassigned":
      return e.to_value === e.actor_id
        ? `took it over from ${nameOf(e.from_value)}`
        : `reassigned it from ${nameOf(e.from_value)} to ${nameOf(e.to_value)}`;
    case "attachment_added":
      return `added a file: ${e.comment}`;
    default:
      return e.type.replace(/_/g, " ");
  }
}

// Comments and reasons shown under an event (not for detail changes or files).
export function eventNote(e: TaskEvent): string | null {
  if (!e.comment || e.type === "details_changed" || e.type === "attachment_added") return null;
  return e.comment;
}
