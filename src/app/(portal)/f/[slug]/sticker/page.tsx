// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import QRCode from "qrcode";
import { requireSession } from "@/lib/session";
import { createClient } from "@/lib/supabase/server";
import { loadFeature } from "@/lib/custom-features";
import { getBranding, getStaffAppLook } from "@/lib/branding";
import { staffAppOn } from "@/lib/staff-app";
import { env } from "@/lib/env";
import { Card, PageHeader, buttonClass, inputClass } from "@/components/ui";
import { PrintButton } from "@/components/print-button";
import { AppSquare } from "@/components/app-glyph";

export const metadata: Metadata = { title: "QR sticker for a client" };

// cmeprojects: a manager makes a QR sticker for one client when it's needed
// (for example on their bedroom door). Scanning it opens the feature with that
// client already chosen, in the Staff app if the feature is in it.
export default async function ClientStickerPage({ params, searchParams }: PageProps<"/f/[slug]/sticker">) {
  const { profile, features } = await requireSession();
  if (profile.role !== "manager" && profile.role !== "system_admin") notFound();
  const def = await loadFeature({ slug: (await params).slug });
  if (!def || def.feature.status !== "published" || !def.feature.enabled) notFound();
  const { feature, fields } = def;
  const clientField = fields.find((f) => f.type === "client" && !f.archived);
  const supabase = await createClient();
  const [{ data: clients }, brand, look, query] = await Promise.all([supabase.rpc("client_options"), getBranding(), getStaffAppLook(), searchParams]);
  const list = (clients ?? []) as { id: string; name: string }[];
  const chosen = typeof query.client === "string" ? list.find((c) => c.id === query.client) : undefined;
  const inApp = staffAppOn(features) && feature.in_app;
  const url = chosen ? `${env.siteUrl}${inApp ? "/app" : ""}/f/${feature.slug}?client=${chosen.id}` : "";
  const svg = url ? await QRCode.toString(url, { type: "svg", margin: 1, errorCorrectionLevel: "M", color: { dark: "#000000", light: "#ffffff" } }) : "";

  return (
    <div className="flex w-full max-w-2xl flex-col gap-4">
      <div className="print:hidden">
        <p className="text-xs text-muted">
          <Link href={`/f/${feature.slug}`} className="underline">
            {feature.name}
          </Link>{" "}
          › QR sticker for a client
        </p>
        <PageHeader
          title="QR sticker for a client"
          intro={`For a client's room or folder. Scanning it opens ${feature.name} with that client already chosen, so staff only fill in the rest.`}
        />
      </div>
      {!clientField ? (
        <Card className="p-5 text-sm text-muted print:hidden">This feature has no Client question, so there&apos;s nothing to choose ahead.</Card>
      ) : (
        <form className="flex flex-wrap items-end gap-3 print:hidden">
          <label className="flex min-w-56 flex-1 flex-col gap-1 text-sm">
            <span className="font-semibold">Client</span>
            <select name="client" defaultValue={chosen?.id ?? ""} required className={inputClass}>
              <option value="" disabled>
                Choose a client
              </option>
              {list.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <button className={buttonClass("primary", "", "sm")}>Make the sticker</button>
        </form>
      )}
      {chosen ? (
        <>
          <div className="mx-auto flex w-80 max-w-full break-inside-avoid flex-col items-center gap-2 rounded-xl border-2 border-dashed border-black/40 bg-white p-6 text-center text-black">
            {/* eslint-disable-next-line @next/next/no-img-element -- the company's own logo */}
            <img src={brand.logoUrl} alt={brand.companyName} className="h-14 w-auto object-contain" />
            <div className="flex items-center gap-2">
              <AppSquare icon={feature.app_icon} colour={feature.app_colour} size="size-12" />
              <span className="text-left">
                <span className="block text-xl leading-tight font-semibold">{chosen.name}</span>
                <span className="block text-sm font-semibold">{feature.name}</span>
              </span>
            </div>
            <div className="w-56" dangerouslySetInnerHTML={{ __html: svg }} />
            <p className="text-sm">
              Scan to record {feature.menu_label.toLowerCase()} for {chosen.name}
            </p>
            {inApp ? (
              <span className="flex items-center gap-1.5 rounded-full border border-black/30 py-0.5 pr-3 pl-0.5 text-xs font-semibold">
                {/* eslint-disable-next-line @next/next/no-img-element -- the app's own icon */}
                <img src="/app/icon/192" alt="" className="size-5 rounded-full" />
                {look.name}
              </span>
            ) : null}
          </div>
          <div className="flex justify-center print:hidden">
            <PrintButton label="Print the sticker" />
          </div>
        </>
      ) : null}
    </div>
  );
}
