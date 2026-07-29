import type { NextConfig } from "next";

// Strict security headers. The CSP lives in proxy.ts (per-request nonce);
// everything here is static. No external host can ever be loaded:
// enforced privacy, not just promised privacy.
const securityHeaders = [
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Referrer-Policy", value: "no-referrer" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
  { key: "Cross-Origin-Resource-Policy", value: "same-origin" },
  // HSTS in prod only: on localhost it poisons the browser's HSTS cache and
  // force-upgrades all dev requests to https, breaking every asset load
  ...(process.env.NODE_ENV === "production"
    ? [
        {
          key: "Strict-Transport-Security",
          value: "max-age=63072000; includeSubDomains; preload",
        },
      ]
    : []),
];

const nextConfig: NextConfig = {
  // tie the build id (and thus asset hashes) to the exact git commit
  generateBuildId: async () =>
    process.env.RAILWAY_GIT_COMMIT_SHA ?? null,
  async headers() {
    return [
      // share assets must be embeddable by other sites (og cards, previews)
      {
        source: "/(og.png|logo.png|icon.png)",
        headers: [
          { key: "Cross-Origin-Resource-Policy", value: "cross-origin" },
          { key: "Cache-Control", value: "public, max-age=3600" },
        ],
      },
      {
        source: "/((?!og.png|logo.png|icon.png).*)",
        headers: securityHeaders,
      },
    ];
  },
};

export default nextConfig;
