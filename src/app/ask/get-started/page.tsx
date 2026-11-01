// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { assistantOn, getVisitor, getWebsiteLook, loadSettings } from "@/lib/assistant";
import { SiteHeader } from "../site-header";
import { EnquiryForm } from "./enquiry-form";

export const metadata: Metadata = { title: "Get started" };

// cmeprojects: how new customers leave their details (the enquiry funnel).
export default async function GetStartedPage({ searchParams }: PageProps<"/ask/get-started">) {
  const query = await searchParams;
  const asked = typeof query.asked === "string" ? query.asked.slice(0, 500) : "";
  const [on, s, brand, visitor] = await Promise.all([assistantOn(), loadSettings(), getBranding(), getVisitor()]);
  return (
    <>
    <SiteHeader logoUrl={(await getWebsiteLook(brand.logoUrl)).logoUrl} companyName={brand.companyName} signedIn={Boolean(visitor.userId)} />
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-4 py-10 sm:py-14">
      <div className="flex flex-col gap-2">
        <h1 className="heading">Let&apos;s get you started</h1>
        <p className="text-muted">Tell us a little about you and someone from our team will call you to talk it through. It only takes a minute.</p>
      </div>
      {on ? <EnquiryForm asked={asked} phone={s.phone} /> : <p className="text-muted">This form isn&apos;t available right now. Please call us.</p>}
    </main>
    </>
  );
}
