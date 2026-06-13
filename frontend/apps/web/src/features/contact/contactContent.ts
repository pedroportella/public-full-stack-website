export type ContactLocale = "en" | "pt-br";

export interface ContactPageContent {
  locale: ContactLocale;
  eyebrow: string;
  title: string;
  intro: string;
  fields: {
    name: string;
    email: string;
    phone: string;
    message: string;
  };
  optionalLabel: string;
  submitLabel: string;
  submittingLabel: string;
  successTitle: string;
  successBody: string;
  errorTitle: string;
  errorBody: string;
}

export const contactPages: Record<ContactLocale, ContactPageContent> = {
  en: {
    locale: "en",
    eyebrow: "Contact",
    title: "Get in touch",
    intro:
      "Send a quick note about a project, collaboration or speaking opportunity.",
    fields: {
      name: "Your name",
      email: "Your email",
      phone: "Your phone",
      message: "Your message"
    },
    optionalLabel: "optional",
    submitLabel: "Send message",
    submittingLabel: "Sending",
    successTitle: "Message sent",
    successBody: "Thanks. I will read this and get back to you soon.",
    errorTitle: "Message not sent",
    errorBody: "Please check the fields and try again."
  },
  "pt-br": {
    locale: "pt-br",
    eyebrow: "Contato",
    title: "Entre em contato",
    intro:
      "Envie uma mensagem sobre um projeto, colaboracao ou oportunidade de palestra.",
    fields: {
      name: "Seu nome",
      email: "Seu email",
      phone: "Seu telefone",
      message: "Sua mensagem"
    },
    optionalLabel: "opcional",
    submitLabel: "Enviar mensagem",
    submittingLabel: "Enviando",
    successTitle: "Mensagem enviada",
    successBody: "Obrigado. Vou ler sua mensagem e responder em breve.",
    errorTitle: "Mensagem nao enviada",
    errorBody: "Confira os campos e tente novamente."
  }
};
