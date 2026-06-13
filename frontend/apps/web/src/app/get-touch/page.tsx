import type { Metadata } from "next";
import { ContactPage } from "@/features/contact/ContactPage";

export const metadata: Metadata = {
  title: "Get in touch | Pedro Portella",
  description: "Contact Pedro Portella about projects and collaborations."
};

export default function GetTouchPage() {
  return <ContactPage locale="en" />;
}
