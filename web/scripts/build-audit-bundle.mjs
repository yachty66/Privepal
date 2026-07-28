// Generates public/audit-bundle.txt at build time: the complete source of
// the privacy-critical files, served from the site itself so any AI (or
// human) can review the running code from a single URL without needing
// GitHub access.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");

const FILES = [
  "app/api/chat/route.ts",
  "proxy.ts",
  "lib/store.ts",
  "lib/metrics.ts",
  "app/api/shield/route.ts",
  "app/api/version/route.ts",
  "app/page.tsx",
  "app/layout.tsx",
  "next.config.ts",
  "package.json",
];

const commit = process.env.RAILWAY_GIT_COMMIT_SHA ?? "local-dev";

let out = `PRIVEPAL AUDIT BUNDLE
Generated at build time from commit: ${commit}
Repository: https://github.com/yachty66/Privepal (web/ directory)
Cross-check any file against the repo at that commit.

The privacy claims to verify:
1. Chat history is stored only client-side in the browser
2. No tracking, no analytics scripts
3. CSP blocks all third-party network connections
4. Messages are relayed to confidential-compute inference without being logged or stored
5. Usage metrics are anonymous aggregate counters only

`;

for (const f of FILES) {
  const content = readFileSync(join(root, f), "utf8");
  out += `\n${"=".repeat(72)}\nFILE: web/${f}\n${"=".repeat(72)}\n${content}`;
}

mkdirSync(join(root, "public"), { recursive: true });
writeFileSync(join(root, "public", "audit-bundle.txt"), out);
console.log(
  `audit-bundle.txt written (${FILES.length} files, commit ${commit.slice(0, 12)})`
);
