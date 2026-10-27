// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata, Viewport } from "next";
import type { CSSProperties } from "react";
import { Figtree } from "next/font/google";
import { getBranding } from "@/lib/branding";
import "./globals.css";

const figtree = Figtree({ variable: "--font-figtree", subsets: ["latin"] });

export async function generateMetadata(): Promise<Metadata> {
  const brand = await getBranding();
  return {
    title: { default: brand.companyName, template: `%s · ${brand.companyName}` },
    description: `${brand.companyName} ${brand.portalName}`,
    authors: [{ name: "cmeproject" }],
    generator: "cmeproject",
    robots: { index: false, follow: false },
  };
}

export const viewport: Viewport = { width: "device-width", initialScale: 1 };

export default async function RootLayout({ children }: LayoutProps<"/">) {
  const brand = await getBranding();
  const style = {
    "--brand-primary": brand.colorPrimary,
    "--brand-dark": brand.colorDark,
    "--brand-accent": brand.colorAccent,
  } as CSSProperties;

  return (
    <html lang="en-AU" className={`${figtree.variable} h-full antialiased`} style={style}>
      <body className="min-h-full font-sans">{children}</body>
    </html>
  );
}
