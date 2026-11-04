// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects: package presets for the Features tab. Each sets the main
// premium switches in one go, to match the budget; parts stay as they are.
export const PRESETS: Record<string, { label: string; on: string[]; hint: string }> = {
  essentials: { label: "Essentials", on: [], hint: "Tasks, registers, people, dashboard" },
  recommended: { label: "Recommended", on: ["forms", "reports", "staff_app"], hint: "Essentials plus Forms, Reports and the Staff app" },
  everything: { label: "Everything", on: ["compliance", "forms", "vehicles", "staff_app", "assistant", "reports"], hint: "Every module switched on" },
};
export const PRESET_SWITCHES = ["compliance", "forms", "vehicles", "staff_app", "assistant", "reports"];
