// Staff Portal · © cmeproject. All rights reserved.
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

// Pages anyone can open without signing in.
// /cron checks its own secret.
const PUBLIC_PATHS = ["/login", "/auth", "/forgot-password", "/health", "/cron"];

// Keeps the sign-in session fresh on every request and sends signed-out
// visitors to the sign-in page. Role and two-factor checks happen on each
// page and in the database; this is only the first, quick check.
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll();
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options),
          );
        },
      },
    },
  );

  const { data } = await supabase.auth.getClaims();
  const signedIn = Boolean(data?.claims?.sub);
  const path = request.nextUrl.pathname;
  const isPublic = PUBLIC_PATHS.some((p) => path === p || path.startsWith(`${p}/`));

  // Too long without activity (even with the browser closed): sign out.
  const idleMinutes = Number(request.cookies.get("portal_idle_minutes")?.value ?? 0);
  const lastActive = Number(request.cookies.get("portal_last_active")?.value ?? 0);
  // Only page visits are checked here; inside an open page the browser signs out itself.
  const pageVisit = request.headers.get("sec-fetch-dest") === "document";
  if (signedIn && pageVisit && idleMinutes > 0 && lastActive > 0 && Date.now() - lastActive > idleMinutes * 60_000) {
    await supabase.auth.signOut();
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = "?error=idle";
    const out = NextResponse.redirect(url);
    response.cookies.getAll().forEach((c) => out.cookies.set(c));
    out.cookies.delete("portal_last_active");
    return out;
  }
  // Opening a page counts as activity (background requests don't; clicks and
  // typing are counted in the browser).
  if (signedIn && idleMinutes > 0 && pageVisit) {
    response.cookies.set("portal_last_active", String(Date.now()), { path: "/", maxAge: 31536000, sameSite: "lax" });
  }

  if (!signedIn && !isPublic) {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = path === "/" ? "" : `?next=${encodeURIComponent(path)}`;
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|logo\\.(?:png|svg)|.*\\.(?:png|jpg|jpeg|svg|webp|ico)$).*)"],
};
