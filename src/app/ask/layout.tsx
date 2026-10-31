// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata } from "next";
import { getBranding } from "@/lib/branding";

export async function generateMetadata(): Promise<Metadata> {
  const { companyName } = await getBranding();
  return {
    title: { default: `Ask ${companyName}`, template: `%s · ${companyName}` },
    description: `Ask questions about ${companyName}'s support services and the NDIS, or leave your details and we'll call you.`,
    robots: { index: true, follow: true },
  };
}

// cmeprojects: the public website. It uses the portal's own colours and fonts
// (set in System settings), so it always matches.
export default function AskLayout({ children }: LayoutProps<"/ask">) {
  return <div className="flex min-h-dvh flex-col bg-page text-ink">{children}</div>;
}
