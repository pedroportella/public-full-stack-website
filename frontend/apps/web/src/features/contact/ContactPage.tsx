import { ContactForm } from "./ContactForm";
import type { ContactLocale } from "./contactContent";
import { contactPages } from "./contactContent";

interface ContactPageProps {
  locale: ContactLocale;
}

export function ContactPage({ locale }: ContactPageProps) {
  const content = contactPages[locale];

  return (
    <main className="web26-page-frame web26-contact-page" id="main-content">
      <section className="web26-contact-intro" aria-labelledby="contact-title">
        <p className="web26-eyebrow">{content.eyebrow}</p>
        <h1 id="contact-title">{content.title}</h1>
        <p>{content.intro}</p>
      </section>
      <ContactForm content={content} />
    </main>
  );
}
