import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { metrics } from "@/lib/metrics";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://privepal.com"),
  // every served page declares the commit it was built from
  other: {
    "privepal-commit": process.env.RAILWAY_GIT_COMMIT_SHA ?? "dev",
  },
  title: "Privepal",
  description:
    "Fast, private AI chat. Confidential compute, no accounts, no stored chats.",
  openGraph: {
    title: "Privepal",
    description:
      "Fast, private AI chat. Confidential compute, no accounts, no stored chats.",
    url: "https://privepal.com",
    siteName: "Privepal",
    images: [{ url: "/logo.png", width: 256, height: 256 }],
    locale: "de_DE",
    type: "website",
  },
  twitter: {
    card: "summary",
    title: "Privepal",
    description:
      "Fast, private AI chat. Confidential compute, no accounts, no stored chats.",
    images: ["/logo.png"],
  },
};

// nonce-based CSP requires per-request rendering
export const dynamic = "force-dynamic";

export const viewport: Viewport = {
  themeColor: "#000000",
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  metrics.pageLoad();
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
