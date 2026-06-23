import { type NextRequest, NextResponse } from "next/server";

// Routes accessible without authentication
const PUBLIC_PATHS = ["/login", "/api"];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public assets and Next.js internals
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/favicon") ||
    pathname.startsWith("/icons") ||
    pathname.startsWith("/manifest") ||
    pathname.endsWith(".js") ||
    pathname.endsWith(".js.map")
  ) {
    return NextResponse.next();
  }

  // Session cookie set by Firebase Auth (we use a lightweight check here;
  // full verification happens via Firebase SDK on the client).
  const session = request.cookies.get("__session")?.value;

  const isPublicPath = PUBLIC_PATHS.some((p) => pathname.startsWith(p));

  if (!session && !isPublicPath) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(loginUrl);
  }

  if (session && pathname === "/login") {
    return NextResponse.redirect(new URL("/map", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
