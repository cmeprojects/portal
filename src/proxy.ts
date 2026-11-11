// Staff Portal · © cmeproject. All rights reserved.
import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { APP_COOKIE, APP_DAYS_COOKIE, LOCKED_COOKIE, PIN_OFF_COOKIE, PORTAL_LOCK_COOKIE, UNLOCK_COOKIE, UNLOCK_MINUTES, appPathOf, isUnlocked, unlockValue } from "@/lib/app-lock";

// Pages anyone can open without signing in.
// /cron checks its own secret.
// When this device last checked its sign-in still exists.
const SESSION_CHECK_COOKIE = "portal_session_checked";
const PUBLIC_PATHS = ["/login", "/auth", "/forgot-password", "/health", "/cron", "/robots.txt", "/sitemap.xml", "/ask"];

// Keeps the sign-in session fresh on every request and sends signed-out
// visitors to the sign-in page. Role and two-factor checks happen on each
// page and in the database; this is only the first, quick check.
export async function proxy(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    (process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY)!,
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
    await supabase.auth.signOut({ scope: "local" });
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    url.search = search;
    const out = NextResponse.redirect(url);
    response.cookies.getAll().forEach((c) => out.cookies.set(c));
    out.cookies.delete("portal_last_active");
    out.cookies.delete(UNLOCK_COOKIE);
    out.cookies.delete(SESSION_CHECK_COOKIE);
    return out;
  };

  // cmeprojects: a device signed out from somewhere else (My account, or the
  // system admin) stops here. Checked on page visits, at most once a minute.
  if (signedIn && pageVisit && !appPublic) {
    const checkedAt = Number(request.cookies.get(SESSION_CHECK_COOKIE)?.value ?? 0);
    if (now - checkedAt > 60_000) {
      const { data: active, error } = await supabase.rpc("my_session_active");
      // Before live update 45 the check doesn't exist yet: carry on as before.
      if (!error && active === false) return signOutTo("?error=signed_out");
      response.cookies.set(SESSION_CHECK_COOKIE, String(now), { path: "/", httpOnly: true, sameSite: "lax", secure: request.nextUrl.protocol === "https:" });
    }
  }

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
    // The website can be the front page (Website settings): visitors see it at
    // the main address (yourcompany.com.au/), staff sign in from there.
    if (path === "/" && (await websiteIsFrontPage(supabase))) {
      url.pathname = "/ask";
      const out = NextResponse.rewrite(url);
      response.cookies.getAll().forEach((c) => out.cookies.set(c));
      return out;
    }
    url.pathname = "/login";
    // They had a sign-in on this device that Supabase no longer accepts: say so.
    const hadSession = request.cookies.getAll().some((c) => c.name.includes("-auth-token"));
    const params = new URLSearchParams();
    if (path !== "/") params.set("next", path);
    if (hadSession) params.set("error", "expired");
    url.search = params.size ? `?${params}` : "";
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|logo\\.(?:png|svg)|.*\\.(?:png|jpg|jpeg|svg|webp|ico)$).*)"],
};

// A public check, so it can be read before anyone signs in: the website is the
// front page only while the Assistant is on (cmeprojects; update 46).
async function websiteIsFrontPage(supabase: ReturnType<typeof createServerClient>): Promise<boolean> {
  const { data, error } = await supabase.rpc("website_front_page");
  if (!error) return data === true;
  // Before live update 46: the setting alone.
  const { data: setting } = await supabase.from("app_settings").select("value").eq("key", "website.front_page").maybeSingle();
  return setting?.value === true;
}
