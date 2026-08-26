import type { Metadata } from "next";
import { Geist_Mono, Plus_Jakarta_Sans, Quicksand } from "next/font/google";
import { Toaster } from "sonner";

import { CopyrightFooter } from "@/components/layout/copyright-footer";
import { AppProviders } from "@/components/providers/app-providers";
import { env } from "@/lib/env";

import "./globals.css";

const quicksand = Quicksand({
  variable: "--font-quicksand",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const plusJakarta = Plus_Jakarta_Sans({
  variable: "--font-plus-jakarta",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: env.appName,
  description: "Frontend web EMI untuk pembelajaran Bahasa Mekongga.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="id"
      className={`${quicksand.variable} ${plusJakarta.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col" suppressHydrationWarning>
        <AppProviders>{children}</AppProviders>
        <CopyrightFooter />
        <Toaster closeButton position="top-center" richColors />
      </body>
    </html>
  );
}
