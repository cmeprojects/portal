// Staff Portal · © cmeproject. All rights reserved.
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { APP_COOKIE, APP_DAYS_COOKIE, LOCKED_COOKIE, PIN_OFF_COOKIE, PORTAL_LOCK_COOKIE, UNLOCK_COOKIE, UNLOCK_MINUTES, appPathOf, isUnlocked, unlockValue } from "@/lib/app-lock";

// Pages anyone can open without signing in.
// /cron checks its own secret.
const PUBLIC_PATHS = ["/login", "/auth", "/forgot-password", "/health", "/cron", "/robots.txt", "/ask"];

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
  const userId = data?.claims?.sub;
  const signedIn = Boolean(userId);
  const path = request.nextUrl.pathname;
  const appBase = appPathOf(path);
  const app = appBase !== null;
  // The apps' install details and icons are needed before signing in.
  const appPublic = app && (path === `${appBase}/manifest.webmanifest` || path.startsWith(`${appBase}/icon/`));
  const isPublic = appPublic || PUBLIC_PATHS.some((p) => path === p || path.startsWith(`${p}/`));
  // When they last signed in properly (password, link or code), from the session itself.
  const amr = (data?.claims?.amr ?? []) as { timestamp?: number }[];
  const signedInAt = Math.max(0, ...amr.map((a) => (a.timestamp ?? 0) * 1000));
  const now = Date.now();
  // Only page visits are checked here; inside an open page the browser signs out itself.
  const pageVisit = request.headers.get("sec-fetch-dest") === "document";

  const signOutTo = async (search: string) => {
    await supabase.auth.signOut();
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = search;
    const out = NextResponse.redirect(url);
    response.cookies.getAll().forEach((c) => out.cookies.set(c));
    out.cookies.delete("portal_last_active");
    out.cookies.delete(UNLOCK_COOKIE);
    return out;
  };

  if (signedIn && app && !appPublic) {
    // The Cars app stays signed in for the set number of days, then a full sign-in again.
    const appDays = Number(request.cookies.get(APP_DAYS_COOKIE)?.value ?? 90) || 90;
    if (pageVisit && signedInAt > 0 && now - signedInAt > appDays * 86_400_000) {
      return signOutTo(`?error=app&next=${encodeURIComponent(appBase!)}`);
    }
    // Opening it needs the PIN, unless they've just signed in or used it in the last few minutes.
    const unlocked =
      // They turned the PIN off on this phone (and haven't pressed Lock).
      (request.cookies.has(PIN_OFF_COOKIE) && !request.cookies.has(LOCKED_COOKIE)) ||
      (await isUnlocked(request.cookies.get(UNLOCK_COOKIE)?.value, userId!, now)) ||
      (!request.cookies.has(LOCKED_COOKIE) && now - signedInAt < UNLOCK_MINUTES * 60_000);
    if (!unlocked && pageVisit && path !== `${appBase}/unlock`) {
      const url = request.nextUrl.clone();
      url.pathname = `${appBase}/unlock`;
      url.search = "";
      const out = NextResponse.redirect(url);
      response.cookies.getAll().forEach((c) => out.cookies.set(c));
      return out;
    }
    const secure = request.nextUrl.protocol === "https:";
    if (unlocked) {
      response.cookies.set(UNLOCK_COOKIE, await unlockValue(userId!, now), { path: "/", httpOnly: true, sameSite: "lax", secure });
    }
    response.cookies.set(APP_COOKIE, "1", { path: "/", maxAge: 31536000, sameSite: "lax", secure });
    // The app has its own lock, so the portal's activity timer doesn't apply here.
    return response;
  }

  // Too long without activity (even with the browser closed): sign out. A
  // phone that has the Cars app installed always gets this check on portal
  // pages, so the app's longer sign-in never opens the rest of the portal.
  const idleMinutes = Number(request.cookies.get("portal_idle_minutes")?.value ?? 0) || (request.cookies.has(APP_COOKIE) ? 30 : 0);
  const lastActive = Math.max(Number(request.cookies.get("portal_last_active")?.value ?? 0), signedInAt);
  // Locked after a timeout on a phone with an app: the password again for the portal.
  const toLogin = () => {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = `?error=idle&next=${encodeURIComponent(path)}`;
    const out = NextResponse.redirect(url);
    response.cookies.getAll().forEach((c) => out.cookies.set(c));
    out.cookies.set(PORTAL_LOCK_COOKIE, "1", { path: "/", httpOnly: true, sameSite: "lax", maxAge: 31536000 });
    return out;
  };
  if (signedIn && pageVisit && !isPublic && path !== "/mfa" && request.cookies.has(PORTAL_LOCK_COOKIE)) return toLogin();
  if (signedIn && pageVisit && !isPublic && path !== "/mfa" && idleMinutes > 0 && lastActive > 0 && now - lastActive > idleMinutes * 60_000) {
    // On a phone with an app, only lock the portal; the apps stay signed in behind their PIN.
    return request.cookies.has(APP_COOKIE) ? toLogin() : signOutTo("?error=idle");
  }
  // Opening a page counts as activity (background requests don't; clicks and
  // typing are counted in the browser).
  if (signedIn && idleMinutes > 0 && pageVisit) {
    response.cookies.set("portal_last_active", String(now), { path: "/", maxAge: 31536000, sameSite: "lax" });
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
