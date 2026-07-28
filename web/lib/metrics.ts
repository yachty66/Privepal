// Aggregate, anonymous usage counters. Numbers only: no IPs, no cookies,
// no identifiers, nothing per-user. This keeps the shield-page claims true
// while still telling us whether anyone is using the product.
// In-memory: resets on each deploy, which is fine for launch-phase insight.

interface Metrics {
  startedAt: number;
  pageLoads: number;
  shieldChecks: number;
  chatRequests: number;
  chatByModel: Record<string, number>;
  rateLimited: number;
  invalidRequests: number;
  upstreamErrors: number;
  upstreamHeaderMsTotal: number;
  upstreamHeaderMsCount: number;
}

// globalThis so route handlers and server components share one instance
const g = globalThis as unknown as { __privepalMetrics?: Metrics };

function m(): Metrics {
  if (!g.__privepalMetrics) {
    g.__privepalMetrics = {
      startedAt: Date.now(),
      pageLoads: 0,
      shieldChecks: 0,
      chatRequests: 0,
      chatByModel: {},
      rateLimited: 0,
      invalidRequests: 0,
      upstreamErrors: 0,
      upstreamHeaderMsTotal: 0,
      upstreamHeaderMsCount: 0,
    };
  }
  return g.__privepalMetrics;
}

export const metrics = {
  pageLoad: () => void m().pageLoads++,
  shieldCheck: () => void m().shieldChecks++,
  chatRequest: (model: string) => {
    const s = m();
    s.chatRequests++;
    s.chatByModel[model] = (s.chatByModel[model] ?? 0) + 1;
  },
  rateLimited: () => void m().rateLimited++,
  invalidRequest: () => void m().invalidRequests++,
  upstreamError: () => void m().upstreamErrors++,
  upstreamHeaderMs: (ms: number) => {
    const s = m();
    s.upstreamHeaderMsTotal += ms;
    s.upstreamHeaderMsCount++;
  },
  snapshot: () => {
    const s = m();
    return {
      ...s,
      uptimeHours:
        Math.round(((Date.now() - s.startedAt) / 3_600_000) * 10) / 10,
      avgUpstreamHeaderMs: s.upstreamHeaderMsCount
        ? Math.round(s.upstreamHeaderMsTotal / s.upstreamHeaderMsCount)
        : null,
    };
  },
};
