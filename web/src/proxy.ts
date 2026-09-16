import { NextResponse, type NextRequest } from "next/server";

const SESSION_COOKIE = "masroof_session";
const AUTH_PAGES = ["/login", "/register", "/forgot-password", "/reset-password"];
/** Reachable whether or not the visitor is signed in (e.g. opened from an e-mail). */
const PUBLIC_PAGES = ["/verify-email"];

/** Redirects between the signed-in app and the auth pages based on the session cookie. */
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  if (PUBLIC_PAGES.includes(pathname)) return NextResponse.next();
  const signedIn = request.cookies.has(SESSION_COOKIE);
  const onAuthPage = AUTH_PAGES.some((page) => pathname === page || pathname.startsWith(`${page}/`));

  if (!signedIn && !onAuthPage) {
    const url = new URL("/login", request.url);
    if (pathname !== "/") url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }
  if (signedIn && onAuthPage && pathname !== "/reset-password") {
    return NextResponse.redirect(new URL("/", request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|icon|apple-touch-icon|logo-tile|manifest.webmanifest|.*\\.(?:png|svg|ico|webmanifest)$).*)",
  ],
};
