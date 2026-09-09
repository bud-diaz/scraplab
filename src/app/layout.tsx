import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AuthProvider } from "@/lib/auth-context";
import { NativeBootstrap } from "@/components/native/NativeBootstrap";

export const metadata: Metadata = {
  title: "ScrapLab — Build More. Buy Less.",
  description: "Turn everyday household materials into safe, age-appropriate kid build projects.",
};

export const viewport: Viewport = {
  // Lets content extend under the notch/Dynamic Island and home indicator on
  // iOS so the safe-area CSS in AppShell/BottomNav can pad around them.
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@500;600;700;800&family=Inter:wght@400;500;600&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="antialiased">
        <NativeBootstrap />
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
