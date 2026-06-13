import type { Metadata } from "next";
import { ContactPage } from "@/features/contact/ContactPage";

export const metadata: Metadata = {
  title: "Entre em contato | Pedro Portella",
  description: "Entre em contato com Pedro Portella sobre projetos e colaboracoes."
};

export default function EntreEmContatoPage() {
  return <ContactPage locale="pt-br" />;
}
