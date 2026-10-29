// Staff Portal · © cmeproject. All rights reserved.

// System settings with a fixed set of answers.
export const CHOICES: Record<string, { value: string; label: string }[]> = {
  "tasks.required_fields_when": [
    { value: "complete", label: "Before completing or sending for approval (recommended)" },
    { value: "create", label: "When the task is created and assigned" },
  ],
  "vehicles.client_field": [
    { value: "off", label: "Off (no client on trips)" },
    { value: "optional", label: "Optional" },
    { value: "required", label: "Required" },
  ],
  "system.hosting_plan": [
    { value: "free", label: "Free" },
    { value: "pro", label: "Pro" },
  ],
  "vehicles.odo_photo": [
    { value: "off", label: "Off" },
    { value: "optional", label: "Optional" },
    { value: "required", label: "Required" },
  ],
};
