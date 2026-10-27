// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";
import { Card, PageHeader } from "@/components/ui";
import pkg from "../../../../package.json";

export const metadata: Metadata = { title: "About" };

export default async function AboutPage() {
  const brand = await getBranding();
  return (
    <>
      <PageHeader title="About" />
      <Card className="flex max-w-2xl flex-col gap-3 p-6">
        <h2 className="text-xl font-extrabold">
          {brand.companyName} {brand.portalName}
        </h2>
        <dl className="grid grid-cols-[max-content_1fr] gap-x-6 gap-y-2 text-[15px]">
          <dt className="font-semibold">Version</dt>
          <dd>{pkg.version}</dd>
          <dt className="font-semibold">Developed by</dt>
          <dd>cmeproject</dd>
          <dt className="font-semibold">Data stored in</dt>
          <dd>Australia (Sydney)</dd>
        </dl>
        <p className="text-sm text-muted">© {new Date().getFullYear()} cmeproject. All rights reserved.</p>
      </Card>
    </>
  );
}
