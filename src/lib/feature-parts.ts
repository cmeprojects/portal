// Staff Portal · © cmeproject. All rights reserved.

// cmeprojects settings revamp: rules that follow the feature switches. A part
// that doesn't exist yet (before live update 46) counts as on.
type Features = Record<string, boolean>;
const on = (f: Features, key: string) => f[key] !== false;

// Compliance parts by item kind.
export const COMPLIANCE_PART: Record<string, string> = {
  read: "compliance_read",
  training: "compliance_training",
  upload: "compliance_upload",
  form: "compliance_forms",
};

export const compliancePartOn = (f: Features, kind: string) => on(f, "compliance") && on(f, COMPLIANCE_PART[kind] ?? "compliance");

// My onboarding shows only while at least one compliance part is on.
export function onboardingOn(f: Features): boolean {
  return on(f, "compliance") && (["read", "training", "upload"].some((k) => compliancePartOn(f, k)) || formsInOnboarding(f));
}

// Forms to fill in appear in My onboarding when Forms is on (and onboarding is).
export function formsInOnboarding(f: Features): boolean {
  return f.forms === true && on(f, "compliance") && ["read", "training", "upload", "form"].some((k) => compliancePartOn(f, k));
}

export const teamsOn = (f: Features) => on(f, "teams");
export const rolesOn = (f: Features) => on(f, "roles");
export const formBuilderOn = (f: Features) => f.forms === true && on(f, "form_builder");
