// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import QRCode from "qrcode";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { formUrl, formsOn, loadForm } from "@/lib/forms";
import { getBranding } from "@/lib/branding";
import { env } from "@/lib/env";
import { PrintButton } from "@/components/print-button";
import { AutoPrint } from "@/components/auto-print";

export const metadata: Metadata = { title: "Form QR code" };

// A form's QR code to print and stick up: the company logo, the form's name and how to use it.
export default async function FormQrPage({ params, searchParams }: PageProps<"/forms/[id]/qr">) {
  const { features } = await requireSession();
  if (!formsOn(features)) notFound();
  const def = await loadForm((await params).id);
  if (!def) notFound();
  const { data: canManage } = await (await createClient()).rpc("can_manage_form", { p_form: def.form.id });
  if (!canManage) notFound();
  const [brand, query] = await Promise.all([getBranding(), searchParams]);
  const url = formUrl(env.siteUrl, def.form.id);
  const svg = await QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } });
  return (
    <>
      {query.print === "1" ? <AutoPrint /> : null}
      <div className="flex flex-wrap items-center justify-between gap-3 print:hidden">
        <Link href={`/forms?open=${def.form.id}`} className="text-sm font-semibold text-brand underline">
          ‹ Back to Forms
        </Link>
        <PrintButton label="Print the QR code" />
      </div>
      <div className="mx-auto flex w-80 max-w-full break-inside-avoid flex-col items-center gap-2 rounded-xl border-2 border-dashed border-black/40 bg-white p-6 text-center text-black">
        {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
        <img src={brand.logoUrl} alt={brand.companyName} className="h-14 w-auto object-contain" />
        <p className="text-xl leading-tight font-semibold">{def.form.title}</p>
        <div className="w-56" dangerouslySetInnerHTML={{ __html: svg }} />
        <p className="text-sm">Scan with your phone camera to fill in this form</p>
        <p className="text-xs break-all">{url}</p>
      </div>
    </>
  );
}
