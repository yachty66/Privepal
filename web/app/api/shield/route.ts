// Live status for the shield screen. Checks that the attested channel to
// confidential compute is up by querying the Privatemode proxy. The proxy
// only completes requests after verifying enclave attestation, so a
// successful round trip means the encrypted channel is live.

const PROXY_URL = process.env.PRIVATEMODE_PROXY_URL ?? "http://localhost:8080";

export async function GET() {
  let proxyOk = false;
  let models: string[] = [];
  try {
    const res = await fetch(`${PROXY_URL}/v1/models`, {
      signal: AbortSignal.timeout(5000),
      cache: "no-store",
      headers: process.env.PRIVATEMODE_API_KEY
        ? { Authorization: `Bearer ${process.env.PRIVATEMODE_API_KEY}` }
        : undefined,
    });
    if (res.ok) {
      proxyOk = true;
      const data = await res.json();
      models = (data.data ?? [])
        .filter((m: { tasks?: string[] }) => m.tasks?.includes("generate"))
        .map((m: { id: string }) => m.id);
    }
  } catch {
    // proxy unreachable
  }
  return Response.json(
    { proxyOk, models, checkedAt: Date.now() },
    { headers: { "Cache-Control": "no-store" } }
  );
}
