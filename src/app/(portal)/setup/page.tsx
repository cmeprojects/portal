// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { requireRole } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { Card, PageHeader } from "@/components/ui";
import { SetupWizard } from "./wizard";
import { skipSetup } from "./actions";
import { FormPending } from "@/components/form-pending";

export const metadata: Metadata = { title: "Set up" };

// cmeprojects: the first-time setup wizard (system admin only). It opens by
// itself in a new copy; it can be opened again at /setup any time.
export default async function SetupPage() {
  await requireRole(["system_admin"]);
  const supabase = await createClient();
  const [{ data: settings }, { data: templates }, { data: registries }] = await Promise.all([
    supabase.from("app_settings").select("key, value").or("key.like.brand.%,key.eq.wording.client,key.eq.region.timezone"),
    supabase.from("register_templates").select("key, name, prefix, description").order("sort_order"),
    supabase.from("registries").select("prefix"),
  ]);
  const get = (k: string, fallback: string) => {
    const v = settings?.find((s) => s.key === k)?.value;
    return typeof v === "string" && v ? v : fallback;
  };
  const used = new Set((registries ?? []).map((r) => r.prefix as string));
  const company = get("brand.company_name", "");

  return (
    <>
      <PageHeader
        title="Set up your portal"
        intro="A few quick steps for a new copy. Everything here can be changed later in Settings."
        action={
          <form action={skipSetup}>
            <button className="text-sm font-semibold text-muted underline">Skip for now<FormPending /></button>
          </form>
        }
      />
      <Card className="max-w-3xl p-5 sm:p-7">
        <SetupWizard
          start={{
            company: company === "My Company" ? "" : company,
            portal: get("brand.portal_name", "Staff Portal"),
            clientWord: get("wording.client", "Client"),
            timezone: get("region.timezone", "Australia/Melbourne"),
            primary: get("brand.color_primary", "#134F8E"),
            dark: get("brand.color_dark", "#0F2F57"),
            accent: get("brand.color_accent", "#6497C8"),
          }}
          templates={(templates ?? []).map((t) => ({ key: t.key, name: t.name, description: t.description, added: used.has(t.prefix) }))}
        />
      </Card>
    </>
  );
}
