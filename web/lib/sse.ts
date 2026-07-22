// Minimal SSE parser for OpenAI-compatible streaming chat completions.

export interface StreamDelta {
  content?: string;
  reasoning?: string;
}

export async function* streamChat(
  res: Response
): AsyncGenerator<StreamDelta> {
  if (!res.body) return;
  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buf = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buf += decoder.decode(value, { stream: true });

    const lines = buf.split("\n");
    buf = lines.pop() ?? "";

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed.startsWith("data:")) continue;
      const data = trimmed.slice(5).trim();
      if (data === "[DONE]") return;
      try {
        const json = JSON.parse(data);
        const delta = json.choices?.[0]?.delta;
        if (!delta) continue;
        const out: StreamDelta = {};
        if (delta.content) out.content = delta.content;
        if (delta.reasoning || delta.reasoning_content) {
          out.reasoning = delta.reasoning ?? delta.reasoning_content;
        }
        if (out.content || out.reasoning) yield out;
      } catch {
        // partial or malformed chunk: skip
      }
    }
  }
}
