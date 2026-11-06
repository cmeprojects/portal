// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { createClient } from "@/lib/supabase/server";
import { Badge, Card, Notice, PageHeader } from "@/components/ui";
import { AddTemplateButton } from "./add-button";

export const metadata: Metadata = { title: "Register templates" };

type Template = { key: string; name: string; prefix: string; description: string; kind: string; fields: { label: string }[] };

// cmeprojects: the standard registers every copy carries. Add the ones you
// want; each can be changed afterwards in Set up.
export default async function RegisterTemplatesPage() {
  const { profile } = await requireTaskAccess();
  if (profile.role !== "system_admin" && !(await getMyAdminAreas(profile.role)).includes("registers")) redirect("/registers");
  const supabase = await createClient();
  const [{ data, error }, { data: existing }] = await Promise.all([
    supabase.from("register_templates").select("key, name, prefix, description, kind, fields").order("sort_order"),
    supabase.from("registries").select("prefix"),
  ]);
  const used = new Set((existing ?? []).map((r) => r.prefix as string));
  const templates = (data ?? []) as Template[];

  return (
    <>
      <Link href="/registers" className="text-sm font-semibold text-brand">
        ← Registers
      </Link>
      <PageHeader
        title="Register templates"
        intro="Standard NDIS registers, ready to use. Add the ones you need; you can rename them and change their fields afterwards in Set up."
      />
      {error ? <Notice tone="error">Run the latest database update (update 51) to use templates.</Notice> : null}
      <div className="grid gap-3 md:grid-cols-2">
        {templates.map((t) => (
          <Card key={t.key} className="flex items-start gap-4 p-4">
            <div className="min-w-0 flex-1">
              <p className="flex flex-wrap items-center gap-2 font-semibold">
                {t.name} <Badge tone="grey">{t.prefix}</Badge>
                {t.kind === "records" ? <Badge tone="soft">List</Badge> : null}
              </p>
              <p className="text-sm text-muted">{t.description}</p>
              <p className="mt-1 text-xs text-muted">Fields: {t.fields.map((f) => f.label).join(", ")}</p>
            </div>
            {used.has(t.prefix) ? <Badge tone="good">Added</Badge> : <AddTemplateButton templateKey={t.key} name={t.name} />}
          </Card>
        ))}
      </div>
    </>
  );
}
