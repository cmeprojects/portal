// Staff Portal · © cmeproject. All rights reserved.

// System settings with a fixed set of answers.
export const CHOICES: Record<string, { value: string; label: string }[]> = {
  "tasks.required_fields_when": [
    { value: "complete", label: "Before completing or sending for approval (recommended)" },
    { value: "create", label: "When the task is created and assigned" },
  ],
};
