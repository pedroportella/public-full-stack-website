import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const FIELD_LIMITS = {
  name: 120,
  email: 254,
  phone: 40,
  message: 5000
} as const;

const MIN_SUBMIT_MS = 1200;
const RATE_LIMIT_WINDOW_MS =
  Number(process.env.CONTACT_RATE_LIMIT_WINDOW_SECONDS ?? 60) * 1000;
const RATE_LIMIT_MAX = Number(process.env.CONTACT_RATE_LIMIT_MAX ?? 5);

const requestLog = new Map<string, number[]>();

interface ContactPayload {
  name?: unknown;
  email?: unknown;
  phone?: unknown;
  message?: unknown;
  locale?: unknown;
  company?: unknown;
  startedAt?: unknown;
}

interface ValidContactPayload {
  name: string;
  email: string;
  phone: string;
  message: string;
  locale: "en" | "pt-br";
}

export async function POST(request: Request) {
  const correlationId = crypto.randomUUID();
  const clientKey = getClientKey(request);

  if (isRateLimited(clientKey)) {
    return NextResponse.json(
      { ok: false, error: "rate_limited", id: correlationId },
      { status: 429 }
    );
  }

  let payload: ContactPayload;

  try {
    payload = (await request.json()) as ContactPayload;
  } catch {
    return validationError(correlationId);
  }

  const validated = validatePayload(payload);

  if (!validated.ok) {
    return validationError(correlationId);
  }

  await deliverContactMessage(validated.value, correlationId);

  return NextResponse.json({ ok: true, id: correlationId });
}

function validatePayload(
  payload: ContactPayload
): { ok: true; value: ValidContactPayload } | { ok: false } {
  if (typeof payload.company === "string" && payload.company.trim() !== "") {
    return { ok: false };
  }

  if (
    typeof payload.startedAt !== "number" ||
    Date.now() - payload.startedAt < MIN_SUBMIT_MS
  ) {
    return { ok: false };
  }

  const name = cleanString(payload.name);
  const email = cleanString(payload.email).toLowerCase();
  const phone = cleanString(payload.phone);
  const message = cleanString(payload.message);

  if (!name || !email || !message) {
    return { ok: false };
  }

  if (
    name.length > FIELD_LIMITS.name ||
    email.length > FIELD_LIMITS.email ||
    phone.length > FIELD_LIMITS.phone ||
    message.length > FIELD_LIMITS.message
  ) {
    return { ok: false };
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return { ok: false };
  }

  if (containsMarkup(name) || containsMarkup(phone) || containsMarkup(message)) {
    return { ok: false };
  }

  if (payload.locale !== "en" && payload.locale !== "pt-br") {
    return { ok: false };
  }

  return {
    ok: true,
    value: {
      name,
      email,
      phone,
      message,
      locale: payload.locale
    }
  };
}

function cleanString(value: unknown): string {
  return typeof value === "string" ? value.trim().replace(/\s+/g, " ") : "";
}

function containsMarkup(value: string): boolean {
  return /<[^>]*>|javascript:/i.test(value);
}

function validationError(correlationId: string) {
  return NextResponse.json(
    { ok: false, error: "validation_failed", id: correlationId },
    { status: 400 }
  );
}

function getClientKey(request: Request): string {
  return (
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ||
    request.headers.get("x-real-ip") ||
    "local"
  );
}

function isRateLimited(clientKey: string): boolean {
  const now = Date.now();
  const activeHits = (requestLog.get(clientKey) ?? []).filter(
    (timestamp) => now - timestamp < RATE_LIMIT_WINDOW_MS
  );

  activeHits.push(now);
  requestLog.set(clientKey, activeHits);

  return activeHits.length > RATE_LIMIT_MAX;
}

async function deliverContactMessage(
  payload: ValidContactPayload,
  correlationId: string
) {
  const deliveryMode = process.env.CONTACT_PROVIDER ?? "development-log";

  if (deliveryMode === "development-log") {
    console.info("contact.delivery.accepted", {
      id: correlationId,
      locale: payload.locale,
      hasPhone: payload.phone.length > 0
    });
    return;
  }

  console.info("contact.delivery.pending-provider", {
    id: correlationId,
    provider: deliveryMode,
    locale: payload.locale,
    hasPhone: payload.phone.length > 0
  });
}
