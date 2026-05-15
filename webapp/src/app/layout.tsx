import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { ThemeProvider } from "@/components/shared/ThemeProvider";
import { QueryProvider } from "@/components/shared/QueryProvider";
import { AuthProvider } from "@/components/shared/AuthProvider";
import { SkipLink } from "@/components/shared/SkipLink";

const inter = Inter({ subsets: ["latin"], variable: "--font-sans", display: "swap" });

export const metadata: Metadata = {
  title: {
    default: "MetroPTY",
    template: "%s | MetroPTY",
  },
  description:
    "Estado del Metro de Panamá en tiempo real. Reportes colaborativos, rutas y ETA.",
  manifest: "/manifest.json",
  icons: {
    icon: [
      { url: "/icons/icon-32.png", sizes: "32x32", type: "image/png" },
      { url: "/icons/icon-96.png", sizes: "96x96", type: "image/png" },
    ],
    apple: "/apple-touch-icon.png",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "MetroPTY",
  },
  applicationName: "MetroPTY",
  keywords: ["metro", "panamá", "transporte", "tiempo real", "reportes"],
  openGraph: {
    type: "website",
    locale: "es_PA",
    title: "MetroPTY — Metro de Panamá en tiempo real",
    description: "Consulta el estado del Metro de Panamá, planifica rutas y reporta incidencias.",
    siteName: "MetroPTY",
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#0066CC" },
    { media: "(prefers-color-scheme: dark)", color: "#0f172a" },
  ],
  width: "device-width",
  initialScale: 1,
  minimumScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es" className={inter.variable} suppressHydrationWarning>
      <body className="min-h-screen bg-[var(--background)] text-[var(--foreground)] antialiased">
        <SkipLink />
        <ThemeProvider>
          <QueryProvider>
            <AuthProvider>{children}</AuthProvider>
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
