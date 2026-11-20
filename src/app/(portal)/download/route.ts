// Staff Portal · © cmeproject. All rights reserved.
import { NextResponse, type NextRequest } from "next/server";
import { getSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { logDownload } from "@/lib/download-log";
import { FILES_BUCKET } from "@/lib/compliance";

// cmeprojects (update 154): documents open through here, so each download is
// recorded in the trail. The row is read as the signed-in person (the database
// decides who may see it), then a one-minute link to the file is handed over.
//   /download?k=client_doc&id=…   client documents
//   /download?k=compliance&id=…   compliance uploads and certificates
//   /download?k=task_file&id=…    task attachments
const UUID = /^[0-9a-f-]{36}$/i;

export async function GET(request: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.redirect(new URL("/login", request.url));
  const k = request.nextUrl.searchParams.get("k") ?? "";
  const id = request.nextUrl.searchParams.get("id") ?? "";
  const supabase = await createClient();
  // Refused (or not there): recorded as denied, against the client the link named, if any.
  const linkClient = request.nextUrl.searchParams.get("c") ?? "";
  const refuse = async () => {
    await logDownload({ kind: "document", action: "download_denied", label: `Refused: ${k || "file"} ${id}`.slice(0, 120), clientId: UUID.test(linkClient) ? linkClient : null, details: { file: id, k, client_from_link: UUID.test(linkClient) } });
    return new NextResponse("This file isn't available, or you don't have access to it.", { status: 404 });
  };

  let bucket = "";
  let path = "";
  let label = "";
  let clientId: string | null = null;
  let personId: string | null = null;
  const details: Record<string, unknown> = { file: id };

  if (k === "client_doc" && UUID.test(id)) {
    const { data } = await supabase.from("client_documents").select("title, file_path, file_name, client_id").eq("id", id).maybeSingle();
    if (!data?.file_path) return refuse();
    [bucket, path, label, clientId] = ["client-docs", data.file_path, `Client document: ${data.title || data.file_name}`, data.client_id];
  } else if (k === "compliance" && /^\d+$/.test(id)) {
    const { data } = await supabase.from("compliance_records").select("file_path, file_name, user_id, item_id").eq("id", Number(id)).maybeSingle();
    if (!data?.file_path) return refuse();
    const { data: item } = await supabase.from("compliance_items").select("title").eq("id", data.item_id).maybeSingle();
    [bucket, path, label, personId] = [FILES_BUCKET, data.file_path, `Compliance file: ${item?.title ?? data.file_name ?? "file"}`, data.user_id];
  } else if (k === "task_file" && UUID.test(id)) {
    const { data } = await supabase.from("task_attachments").select("file_path, file_name, task_id").eq("id", id).maybeSingle();
    if (!data?.file_path) return refuse();
    const { data: task } = await supabase.from("tasks").select("client_id").eq("id", data.task_id).maybeSingle();
    [bucket, path, label, clientId] = ["task-files", data.file_path, `Task attachment: ${data.file_name ?? "file"}`, (task?.client_id as string | null) ?? null];
    details.task = data.task_id;
  } else {
    return refuse();
  }

  const { data: signed } = await supabase.storage.from(bucket).createSignedUrl(path, 60);
  if (!signed?.signedUrl) return refuse();
  await logDownload({ kind: "document", label, clientId, personId, details });
  return NextResponse.redirect(signed.signedUrl, { headers: { "Cache-Control": "no-store" } });
}
