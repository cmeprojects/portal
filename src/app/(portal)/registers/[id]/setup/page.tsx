// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getFields, getPeople, getRegistries } from "@/lib/register-data";
import { FIELD_TYPE_LABELS } from "@/lib/registers";
import { Badge, Card, Notice, PageHeader } from "@/components/ui";
import { AddFieldForm, EditFieldForm, ManagersForm, RegistrySettingsForm } from "../../setup-forms";
import { moveField } from "../../setup-actions";

export const metadata: Metadata = { title: "Set up register" };

export default async function SetupPage({ params, searchParams }: PageProps<"/registers/[id]/setup">) {
  const { id } = await params;
  const { created } = await searchParams;
  await requireSession();
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) notFound();
  const supabase = await createClient();
  const { data: manages } = await supabase.rpc("manages_registry", { p_registry_id: id });
  if (!manages) redirect(`/registers/${id}`);

  const [allFields, people, { data: managers }] = await Promise.all([
    getFields(),
    getPeople(),
    supabase.from("registry_managers").select("user_id").eq("registry_id", id),
  ]);
  const fields = allFields.filter((f) => f.registry_id === id);
  const candidates = people.filter((p) => p.active && (p.role === "manager" || p.role === "system_admin")).map((p) => ({ id: p.id, label: p.name }));

  return (
    <>
      <Link href={`/registers/${id}`} className="text-[15px] font-semibold text-brand">
        ← {registry.name}
      </Link>
      {created ? <Notice tone="success">Register created. Now add its fields and choose its managers.</Notice> : null}
      <PageHeader eyebrow="Set up" title={registry.name} intro="Changes apply straight away to new and existing entries." />

      <div className="grid items-start gap-4 xl:grid-cols-2">
        <Card className="p-5">
          <h2 className="mb-4 text-lg font-bold">Settings</h2>
          <RegistrySettingsForm registry={registry} />
        </Card>
        <Card className="p-5">
          <h2 className="mb-1 text-lg font-bold">Managers</h2>
          <p className="mb-3 text-[15px] text-muted">
            Managers see every entry in this register, get emailed about new ones and can change its set-up.
          </p>
          <ManagersForm registryId={id} managerIds={(managers ?? []).map((m) => m.user_id)} candidates={candidates} />
        </Card>
      </div>

      <Card className="p-5">
        <h2 className="mb-1 text-lg font-bold">Fields</h2>
        <p className="mb-4 text-[15px] text-muted">
          {registry.kind === "tasks"
            ? "Every task already has a title, description, priority, status, person looking after it, helpers, dates, attachments and comments. Add the extra details this register needs."
            : "Add the details you keep for each item."}
        </p>
        {fields.length === 0 ? <p className="mb-4 text-[15px] text-muted">No extra fields yet.</p> : null}
        <ol className="mb-5 flex flex-col divide-y divide-line rounded-2xl border border-line">
          {fields.map((f, i) => (
            <li key={f.id} className="px-4 py-3">
              <details>
                <summary className="flex min-h-11 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1">
                  <span className={`flex-1 font-bold ${f.active ? "" : "text-muted line-through"}`}>{f.label}</span>
                  <Badge tone="grey">{FIELD_TYPE_LABELS[f.type]}</Badge>
                  {f.required ? <Badge>Required</Badge> : null}
                  {!f.active ? <Badge tone="grey">Retired</Badge> : null}
                  <span className="text-sm font-semibold text-brand">Edit</span>
                </summary>
                <div className="pt-3">
                  <EditFieldForm field={f} />
                </div>
              </details>
              <div className="mt-1 flex gap-2">
                {i > 0 ? (
                  <form action={moveField}>
                    <input type="hidden" name="id" value={f.id} />
                    <input type="hidden" name="registry_id" value={id} />
                    <input type="hidden" name="dir" value="up" />
                    <button className="min-h-11 px-2 text-sm font-semibold text-muted hover:text-brand" aria-label={`Move ${f.label} up`}>
                      ↑ Up
                    </button>
                  </form>
                ) : null}
                {i < fields.length - 1 ? (
                  <form action={moveField}>
                    <input type="hidden" name="id" value={f.id} />
                    <input type="hidden" name="registry_id" value={id} />
                    <input type="hidden" name="dir" value="down" />
                    <button className="min-h-11 px-2 text-sm font-semibold text-muted hover:text-brand" aria-label={`Move ${f.label} down`}>
                      ↓ Down
                    </button>
                  </form>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
        <details className="rounded-2xl border border-dashed border-field p-4">
          <summary className="flex min-h-11 cursor-pointer list-none items-center font-bold text-brand">+ Add a field</summary>
          <div className="pt-3">
            <AddFieldForm registryId={id} />
          </div>
        </details>
      </Card>
    </>
  );
}
