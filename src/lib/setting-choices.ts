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
  // The weekly mileage report (cmeprojects). Stored as text; the database reads them as numbers.
  "vehicles.weekly_day": [
    { value: "1", label: "Monday" },
    { value: "2", label: "Tuesday" },
    { value: "3", label: "Wednesday" },
    { value: "4", label: "Thursday" },
    { value: "5", label: "Friday" },
    { value: "6", label: "Saturday" },
    { value: "7", label: "Sunday" },
  ],
  "vehicles.weekly_period": [
    { value: "last_7_days", label: "The last 7 days" },
    { value: "previous_week", label: "Last week, Monday to Sunday" },
    { value: "last_14_days", label: "The last 14 days" },
    { value: "month_to_date", label: "This month so far" },
  ],
  "vehicles.odo_photo": [
    { value: "off", label: "Off" },
    { value: "optional", label: "Optional" },
    { value: "required", label: "Required" },
  ],
};
