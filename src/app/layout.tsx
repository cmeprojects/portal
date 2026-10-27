// Staff Portal · © cmeproject. All rights reserved.
import type { Metadata, Viewport } from "next";
import type { CSSProperties } from "react";
import { Figtree, Jost } from "next/font/google";
import { getBranding } from "@/lib/branding";
import "./globals.css";

// Jost for headings (geometric capitals), Figtree for everything you read and type.
const display = Jost({ variable: "--font-display", subsets: ["latin"], weight: ["300", "500", "600"] });
const body = Figtree({ variable: "--font-body", subsets: ["latin"] });

// Applies the saved Light/Dark choice before the page paints (see ThemeSwitch).
const THEME_SCRIPT = `try{var t=localStorage.getItem("portal-theme");if(t==="light"||t==="dark")document.documentElement.dataset.theme=t}catch(e){}`;

export async function generateMetadata(): Promise<Metadata> {
  const brand = await getBranding();
  return {
    title: { default: brand.companyName, template: `%s · ${brand.companyName}` },
    description: `${brand.companyName} ${brand.portalName}`,
    authors: [{ name: "cmeproject" }],
    generator: "cmeproject",
    robots: { index: false, follow: false },
    icons: { icon: brand.logoMarkUrl, apple: brand.logoMarkUrl },
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
    <html lang="en-AU" className={`${display.variable} ${body.variable} h-full antialiased`} style={style} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      <body className="min-h-full font-sans">{children}</body>
    </html>
  );
}
