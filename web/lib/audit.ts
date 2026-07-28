// One-click "audit us with your own AI" deep links, shared between the
// home empty state and the shield page.

const RAW = "https://raw.githubusercontent.com/yachty66/Privepal/main/web";

const AUDIT_PROMPT = `privepal.com is a private AI chat that claims: chat history is stored only client-side in the browser, no tracking and no analytics scripts, a CSP blocks all third-party network connections, and messages are relayed to confidential-compute inference without being logged or stored.

Fetch and critically review these source files of the live app (the repo is public at https://github.com/yachty66/Privepal, deploys build from it, running commit shown at https://privepal.com/api/version):

${RAW}/app/api/chat/route.ts (the message relay)
${RAW}/proxy.ts (the CSP)
${RAW}/lib/store.ts (chat storage)
${RAW}/lib/metrics.ts (what usage data is collected)
${RAW}/app/api/shield/route.ts (the live verification check)
${RAW}/app/page.tsx (the chat UI)

Verify each claim against the actual code. Look for logging of message content, analytics, data exfiltration, or anything contradicting the privacy claims. Give an honest verdict, including what cannot be verified from source code alone.`;

export const AUDIT_LINKS = [
  {
    name: "Claude",
    href: `https://claude.ai/new?q=${encodeURIComponent(AUDIT_PROMPT)}`,
  },
  {
    name: "ChatGPT",
    href: `https://chatgpt.com/?q=${encodeURIComponent(AUDIT_PROMPT)}`,
  },
  {
    name: "Perplexity",
    href: `https://www.perplexity.ai/search?q=${encodeURIComponent(AUDIT_PROMPT)}`,
  },
];
