# Contact Flow

## Purpose

The contact flow lets visitors send a message from the Web26 website without carrying legacy Drupal form behavior into the new system.

Drupal owns the editable contact-page content, route aliases and menu placement. Next.js owns the interactive form, server-side validation, spam protection and delivery workflow.

## Architecture Decision

Implement contact as a Next.js-owned feature.

The initial boundary should be:

```txt
frontend/apps/web/src/app/api/contact/route.ts
```

The API route receives form submissions from the public contact page, validates the payload server-side and hands the message to the configured delivery provider.

Drupal should not store contact submissions by default. The CMS remains responsible for content, not operational message intake.

## User-Facing Routes

The frontend should render the contact experience on the migrated contact-page route family.

Expected aliases:

```txt
/get-touch
/entre-em-contato
```

The route resolver can load the Drupal page content for the current alias, then mount the contact form component for the contact page template.

## Form Fields

Required payload:

```txt
name required string
email required email
phone optional string
message required string
locale required en | pt-br
```

Recommended labels:

```txt
en name: Your name
en email: Your email
en phone: Your phone
en message: Your message
pt-br name: Seu nome
pt-br email: Seu email
pt-br phone: Seu telefone
pt-br message: Sua mensagem
```

## Validation

Validate on both client and server. Server validation is authoritative.

Recommended rules:

- trim all string inputs;
- reject empty required fields after trimming;
- validate email format;
- cap field lengths before delivery;
- reject HTML/script payloads as message content;
- return generic error messages that do not expose provider details.

Suggested maximum lengths:

```txt
name 120
email 254
phone 40
message 5000
```

## Spam And Abuse Protection

Use layered protection:

- hidden honeypot field;
- minimum submit timing check;
- per-IP or per-identity rate limiting;
- optional Turnstile or reCAPTCHA if spam volume justifies it;
- provider-side delivery throttling where available.

The endpoint should log only operational metadata such as timestamp, status, route, locale and correlation ID. Avoid logging message bodies or unnecessary personal data.

## Delivery

Configure delivery through environment variables rather than hard-coded addresses.

Recommended variables:

```txt
CONTACT_TO_EMAIL
CONTACT_FROM_EMAIL
CONTACT_PROVIDER
CONTACT_PROVIDER_API_KEY
CONTACT_RATE_LIMIT_WINDOW_SECONDS
CONTACT_RATE_LIMIT_MAX
```

The route handler should return a success response after the provider accepts the message. Provider failures should return a generic failure response and emit an operational log entry.

## Privacy And Retention

Do not persist submissions unless a later requirement explicitly introduces a retention policy.

If persistence is added later, define:

- storage owner;
- retention period;
- deletion process;
- access controls;
- exported fields;
- backup handling.

## Testing

Minimum test coverage:

- payload validation unit tests;
- API route success and provider-failure tests;
- rate-limit and honeypot tests;
- accessibility coverage for labels, errors and focus movement;
- end-to-end form tests for English and Portuguese routes.

## Handover Notes

The contact flow is a new implementation. It is not a migration of legacy form configuration or submissions.

When building the feature, keep the boundary clear:

- Drupal provides content and aliases.
- Next.js provides the interactive form and API endpoint.
- Delivery provider configuration lives in environment variables.
- Historical submissions are not imported into the new runtime.
