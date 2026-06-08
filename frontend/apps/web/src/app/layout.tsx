import type { Metadata } from "next";
import { AppShell } from "@web26/ui-library";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pedro Portella",
  description: "Web26 rebuild of pedroportella.com"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        <AppShell>{children}</AppShell>
      </body>
    </html>
  );
}
