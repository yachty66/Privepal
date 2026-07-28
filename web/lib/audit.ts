// One-click "audit us with your own AI" deep links, shared between the
// home empty state and the shield page.

const AUDIT_PROMPT = `Please review the code at https://github.com/yachty66/Privepal (the web/ directory is the live web app). The app claims: chat history is stored only client-side in the browser, there is no tracking and no analytics scripts, no third-party network connections can load (CSP), and messages are relayed to confidential-compute inference without being logged or stored. Check the code critically: are these claims true? Look for logging of message content, analytics, data exfiltration, or anything contradicting the privacy claims, and give an honest verdict.`;

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
