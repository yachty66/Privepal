import { NextRequest } from "next/server";
import { metrics } from "@/lib/metrics";

// Private aggregate stats. Token-gated; contains no personal data either way.
export async function GET(req: NextRequest) {
  const token = process.env.STATS_TOKEN;
  if (!token || req.headers.get("x-stats-token") !== token) {
    return new Response("not found", { status: 404 });
  }
  return Response.json(metrics.snapshot(), {
    headers: { "Cache-Control": "no-store" },
  });
}
