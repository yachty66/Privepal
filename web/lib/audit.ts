// One-click "audit us with your own AI" deep links, shared between the
// home empty state and the shield page.

export const AUDIT_PROMPT = `privepal.com is a private AI chat that claims: chat history is stored only client-side in the browser, no tracking and no analytics scripts, a CSP blocks all third-party network connections, and messages are relayed to confidential-compute inference without being logged or stored.

Fetch https://privepal.com/audit-bundle.txt : it contains the complete source code of the privacy-critical files of the running app, stamped with the git commit it was built from (cross-checkable against the public repo https://github.com/yachty66/Privepal and https://privepal.com/api/version).

Verify each claim against the actual code. Look for logging of message content, analytics, data exfiltration, or anything contradicting the privacy claims. Give an honest verdict, including what cannot be verified from source code alone. If you cannot fetch URLs, say so and ask the user to paste the bundle contents instead.`;

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
