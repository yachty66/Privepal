import { NextRequest } from "next/server";

// Streams chat completions from the Privatemode proxy (OpenAI-compatible).
// The proxy handles attestation + encryption to the confidential-compute
// backend. This route never stores or logs message content: it only
// validates shape and forwards the stream.

const PROXY_URL = process.env.PRIVATEMODE_PROXY_URL ?? "http://localhost:8080";

const ALLOWED_MODELS = new Set(["gpt-oss-120b", "kimi-k2.6"]);

// Abuse limits per IP: enough for heavy personal use, hostile to scripts.
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 20;
const DAY_MS = 86_400_000;
const MAX_PER_DAY = 400;
const MAX_MESSAGES = 80;
const MAX_MESSAGE_CHARS = 8_000;
const MAX_TOTAL_CHARS = 32_000;

const hits = new Map<string, number[]>();

function rateLimited(ip: string): boolean {
  const now = Date.now();
  // occasional sweep so the map cannot grow unbounded
  if (hits.size > 5_000) {
    for (const [k, v] of hits) {
      if (v.length === 0 || now - v[v.length - 1] > DAY_MS) hits.delete(k);
    }
  }
  const recent = (hits.get(ip) ?? []).filter((t) => now - t < DAY_MS);
  const inWindow = recent.filter((t) => now - t < WINDOW_MS).length;
  if (inWindow >= MAX_PER_WINDOW || recent.length >= MAX_PER_DAY) {
    hits.set(ip, recent);
    return true;
  }
  recent.push(now);
  hits.set(ip, recent);
  return false;
}

function badRequest(msg: string, status = 400) {
  return new Response(JSON.stringify({ error: msg }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export async function POST(req: NextRequest) {
  // browsers always send Origin on cross-site POSTs: reject foreign ones
  const origin = req.headers.get("origin");
  const host = req.headers.get("host");
  if (origin && host && new URL(origin).host !== host) {
    return badRequest("forbidden", 403);
  }

  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  if (rateLimited(ip)) {
    return badRequest("rate limit exceeded, slow down", 429);
  }

  let body: { messages?: unknown; model?: unknown };
  try {
    body = await req.json();
  } catch {
    return badRequest("invalid json");
  }
  const { messages, model } = body;

  if (typeof model !== "string" || !ALLOWED_MODELS.has(model)) {
    return badRequest("invalid model");
  }
  if (!Array.isArray(messages) || messages.length === 0) {
    return badRequest("invalid messages");
  }
  if (messages.length > MAX_MESSAGES) {
    return badRequest("conversation too long");
  }
  let total = 0;
  for (const m of messages) {
    if (
      typeof m !== "object" ||
      m === null ||
      !["user", "assistant"].includes((m as { role?: string }).role ?? "") ||
      typeof (m as { content?: unknown }).content !== "string"
    ) {
      return badRequest("invalid message shape");
    }
    const len = (m as { content: string }).content.length;
    if (len > MAX_MESSAGE_CHARS) return badRequest("message too long");
    total += len;
  }
  if (total > MAX_TOTAL_CHARS) return badRequest("conversation too large");

  const upstream = await fetch(`${PROXY_URL}/v1/chat/completions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      // keyless proxy mode: it forwards this header to the Privatemode API
      ...(process.env.PRIVATEMODE_API_KEY
        ? { Authorization: `Bearer ${process.env.PRIVATEMODE_API_KEY}` }
        : {}),
    },
    body: JSON.stringify({
      model,
      messages: (messages as { role: string; content: string }[]).map(
        ({ role, content }) => ({ role, content })
      ),
      stream: true,
      max_tokens: 4096,
      // keep answers snappy: minimize hidden reasoning where supported
      ...(model === "gpt-oss-120b" ? { reasoning_effort: "low" } : {}),
    }),
    signal: req.signal,
  });

  if (!upstream.ok || !upstream.body) {
    // never include upstream body: it can echo message content
    return new Response(
      JSON.stringify({ error: "upstream error", status: upstream.status }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  // Forward the SSE stream untouched: the client parses the chunks.
  return new Response(upstream.body, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-store, no-transform",
      Connection: "keep-alive",
    },
  });
}
