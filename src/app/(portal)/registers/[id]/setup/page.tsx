// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { requireTaskAccess } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { getFields, getPeople, getRegistries } from "@/lib/register-data";
import { FIELD_TYPE_LABELS } from "@/lib/registers";
import { getSla } from "@/lib/settings";
import { Badge, Card, Notice, PageHeader } from "@/components/ui";
import { getCreateRoles } from "@/lib/register-data";
import { AddFieldForm, CreateRolesForm, DeleteRegisterForm, EditFieldForm, ManagersForm, RegistrySettingsForm } from "../../setup-forms";
import { requireSession } from "@/lib/session";
import { getMyAdminAreas } from "@/lib/settings";
import { moveField } from "../../setup-actions";
import { FormPending } from "@/components/form-pending";

export const metadata: Metadata = { title: "Set up register" };

export default async function SetupPage({ params, searchParams }: PageProps<"/registers/[id]/setup">) {
  const { id } = await params;
  const { created } = await searchParams;
  await requireTaskAccess();
  const registry = (await getRegistries()).find((r) => r.id === id);
  if (!registry) notFound();
  const supabase = await createClient();
  // Its managers, or people given "Setting up registers" (cmeprojects; before update 49, managers only).
  const setup = await supabase.rpc("can_setup_registry", { p_registry_id: id });
  const { data: manages } = setup.error ? await supabase.rpc("manages_registry", { p_registry_id: id }) : setup;
  if (!manages) redirect(`/registers/${id}`);

  const [allFields, people, { data: managers }, sla] = await Promise.all([
    getFields(),
    getPeople(),
    supabase.from("registry_managers").select("user_id").eq("registry_id", id),
    getSla(),
  ]);
  const fields = allFields.filter((f) => f.registry_id === id);
  const candidates = people.filter((p) => p.active && (p.role === "manager" || p.role === "system_admin")).map((p) => ({ id: p.id, label: p.name }));

  return (
    <>
      <Link href={`/registers/${id}`} className="text-sm font-semibold text-brand">
        ← {registry.name}
      </Link>
      {created ? <Notice tone="success">Register created. Now add its fields and choose its managers.</Notice> : null}
      <PageHeader eyebrow="Set up" title={registry.name} intro="Changes apply straight away to new and existing entries." />

      <div className="grid items-start gap-4 xl:grid-cols-2">
        <Card className="p-5">
          <h2 className="mb-4 heading-sm">Settings</h2>
          <RegistrySettingsForm registry={registry} companySla={sla.days as Record<string, number>} />
        </Card>
        <Card className="p-5">
          <h2 className="mb-1 heading-sm">Who can create tasks here</h2>
          <p className="mb-3 text-sm text-muted">
            Tick the roles that may create tasks in this register (its managers always can). Nothing ticked: everyone who can raise tasks, as
            before. This is how support workers can use a register besides General.
          </p>
          <CreateRolesForm id={registry.id} current={(await getCreateRoles()).get(registry.id) ?? []} />
        </Card>
        <Card className="p-5">
          <h2 className="mb-1 heading-sm">Managers</h2>
          <p className="mb-3 text-sm text-muted">
            Managers see every entry in this register, get emailed about new ones and can change its set-up.
          </p>
          <ManagersForm registryId={id} managerIds={(managers ?? []).map((m) => m.user_id)} candidates={candidates} />
        </Card>
      </div>

      <Card className="p-5">
        <h2 className="mb-1 heading-sm">Fields</h2>
        <p className="mb-4 text-sm text-muted">
          {registry.kind === "tasks"
            ? "Every task already has a title, description, priority, status, person looking after it, helpers, dates, attachments and comments. Add the extra details this register needs."
            : "Add the details you keep for each item."}
        </p>
        {fields.length === 0 ? <p className="mb-4 text-sm text-muted">No extra fields yet.</p> : null}
        <ol className="mb-5 flex flex-col divide-y divide-line rounded-lg border border-line">
          {fields.map((f, i) => (
            <li key={f.id} className="px-4 py-3">
              <details name="register-field">
                <summary className="flex min-h-11 cursor-pointer list-none flex-wrap items-center gap-x-3 gap-y-1">
                  <span className={`flex-1 font-semibold ${f.active ? "" : "text-muted line-through"}`}>{f.label}</span>
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
                    <FormPending /></button>
                  </form>
                ) : null}
                {i < fields.length - 1 ? (
                  <form action={moveField}>
                    <input type="hidden" name="id" value={f.id} />
                    <input type="hidden" name="registry_id" value={id} />
                    <input type="hidden" name="dir" value="down" />
                    <button className="min-h-11 px-2 text-sm font-semibold text-muted hover:text-brand" aria-label={`Move ${f.label} down`}>
                      ↓ Down
                    <FormPending /></button>
                  </form>
                ) : null}
              </div>
            </li>
          ))}
        </ol>
        <details name="register-field" className="rounded-lg border border-dashed border-field p-4">
          <summary className="flex min-h-11 cursor-pointer list-none items-center font-semibold text-brand">+ Add a field</summary>
          <div className="pt-3">
            <AddFieldForm registryId={id} />
          </div>
        </details>
      </Card>
      {await DeleteSection({ id: registry.id, name: registry.name, isDefault: registry.is_default })}
    </>
  );
}

// cmeprojects: delete an unused register, or explain why a used one is turned off instead.
async function DeleteSection({ id, name, isDefault }: { id: string; name: string; isDefault: boolean }) {
  if (isDefault) return null;
  const { profile } = await requireSession();
  if (profile.role !== "system_admin" && !(await getMyAdminAreas(profile.role)).includes("registers")) return null;
  const supabase = await createClient();
  const [{ count: tasks }, { count: items }] = await Promise.all([
    supabase.from("tasks").select("id", { count: "exact", head: true }).eq("registry_id", id),
    supabase.from("records").select("id", { count: "exact", head: true }).eq("registry_id", id),
  ]);
  const used = (tasks ?? 0) + (items ?? 0);
  return (
    <Card className="border-danger/40 p-5">
      <h2 className="mb-1 heading-sm">Delete this register</h2>
      {used ? (
        <p className="text-sm text-muted">
          It has {(tasks ?? 0) > 0 ? `${tasks} task${tasks === 1 ? "" : "s"}` : `${items} item${items === 1 ? "" : "s"}`}, so it can&apos;t be deleted: the history is kept for audits.
          To stop using it, untick <strong>Register is in use</strong> in Settings above. It&apos;s then hidden and takes no new tasks.
        </p>
      ) : (
        <>
          <p className="mb-3 text-sm text-muted">It has never been used, so it can be deleted with its fields. This can&apos;t be undone (you can add it again from the templates).</p>
          <DeleteRegisterForm id={id} name={name} />
        </>
      )}
    </Card>
  );
}
