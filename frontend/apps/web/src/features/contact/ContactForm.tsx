"use client";

import { useMemo, useState } from "react";
import type { ContactPageContent } from "./contactContent";

interface ContactFormProps {
  content: ContactPageContent;
}

type SubmitState = "idle" | "submitting" | "success" | "error";

interface ContactFormPayload {
  name: string;
  email: string;
  phone: string;
  message: string;
  locale: ContactPageContent["locale"];
  company: string;
  startedAt: number;
}

export function ContactForm({ content }: ContactFormProps) {
  const startedAt = useMemo(() => Date.now(), []);
  const [state, setState] = useState<SubmitState>("idle");

  async function handleSubmit(formData: FormData) {
    setState("submitting");

    const payload: ContactFormPayload = {
      name: String(formData.get("name") ?? ""),
      email: String(formData.get("email") ?? ""),
      phone: String(formData.get("phone") ?? ""),
      message: String(formData.get("message") ?? ""),
      locale: content.locale,
      company: String(formData.get("company") ?? ""),
      startedAt
    };

    try {
      const response = await fetch("/api/contact", {
        method: "POST",
        headers: {
          "content-type": "application/json"
        },
        body: JSON.stringify(payload)
      });

      setState(response.ok ? "success" : "error");
    } catch {
      setState("error");
    }
  }

  const disabled = state === "submitting" || state === "success";
  const statusTitle =
    state === "success"
      ? content.successTitle
      : state === "error"
        ? content.errorTitle
        : "";
  const statusBody =
    state === "success"
      ? content.successBody
      : state === "error"
        ? content.errorBody
        : "";

  return (
    <form action={handleSubmit} className="web26-contact-form">
      <div className="web26-form-row">
        <label className="web26-field">
          <span>{content.fields.name}</span>
          <input
            autoComplete="name"
            disabled={disabled}
            maxLength={120}
            name="name"
            required
            type="text"
          />
        </label>
        <label className="web26-field">
          <span>{content.fields.email}</span>
          <input
            autoComplete="email"
            disabled={disabled}
            maxLength={254}
            name="email"
            required
            type="email"
          />
        </label>
      </div>
      <label className="web26-field">
        <span>
          {content.fields.phone}
          <small>{content.optionalLabel}</small>
        </span>
        <input
          autoComplete="tel"
          disabled={disabled}
          maxLength={40}
          name="phone"
          type="tel"
        />
      </label>
      <label className="web26-field">
        <span>{content.fields.message}</span>
        <textarea
          disabled={disabled}
          maxLength={5000}
          name="message"
          required
          rows={8}
        />
      </label>
      <label className="web26-honeypot">
        Company
        <input autoComplete="off" name="company" tabIndex={-1} type="text" />
      </label>
      <button className="web26-button" disabled={disabled} type="submit">
        {state === "submitting" ? content.submittingLabel : content.submitLabel}
      </button>
      {statusTitle ? (
        <p className={`web26-form-status web26-form-status--${state}`} role="status">
          <strong>{statusTitle}</strong>
          <span>{statusBody}</span>
        </p>
      ) : null}
    </form>
  );
}
