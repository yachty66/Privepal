import { NextRequest } from "next/server";

// Streams chat completions from the Privatemode proxy (OpenAI-compatible).
// The proxy handles attestation + encryption to the confidential-compute
// backend. This route never stores anything: it only forwards the stream.

const PROXY_URL = process.env.PRIVATEMODE_PROXY_URL ?? "http://localhost:8080";

const ALLOWED_MODELS = new Set(["gpt-oss-120b", "kimi-k2.6"]);

export async function POST(req: NextRequest) {
  const { messages, model } = await req.json();

  if (!Array.isArray(messages) || !ALLOWED_MODELS.has(model)) {
    return new Response(JSON.stringify({ error: "invalid request" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const upstream = await fetch(`${PROXY_URL}/v1/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      messages,
      stream: true,
      max_tokens: 4096,
      // keep answers snappy: minimize hidden reasoning where supported
      ...(model === "gpt-oss-120b" ? { reasoning_effort: "low" } : {}),
    }),
    signal: req.signal,
  });

  if (!upstream.ok || !upstream.body) {
    const detail = await upstream.text().catch(() => "");
    return new Response(
      JSON.stringify({ error: "upstream error", detail: detail.slice(0, 500) }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  // Forward the SSE stream untouched: the client parses the chunks.
  return new Response(upstream.body, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
    },
  });
}
