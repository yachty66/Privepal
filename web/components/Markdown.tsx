"use client";

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

// Renders assistant messages as markdown. react-markdown builds React
// elements (no innerHTML), so model output cannot inject markup or scripts.
// Images are intentionally rendered as their alt text: loading remote
// images would leak the reader's IP to arbitrary hosts (and the CSP blocks
// them anyway).
export default function Markdown({ children }: { children: string }) {
  return (
    <div className="pp-markdown min-w-0 text-[15px] leading-relaxed">
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          img: ({ alt }) => <span className="italic">[{alt || "image"}]</span>,
          a: ({ href, children }) => (
            <a
              href={href}
              target="_blank"
              rel="noopener noreferrer"
              className="underline decoration-neutral-500 underline-offset-2 hover:decoration-white"
            >
              {children}
            </a>
          ),
          code: (props) => {
            const { children, className } = props;
            const isBlock = className?.includes("language-");
            return isBlock ? (
              <code className={className}>{children}</code>
            ) : (
              <code className="rounded bg-neutral-800 px-1.5 py-0.5 font-mono text-[13px]">
                {children}
              </code>
            );
          },
          pre: ({ children }) => (
            <pre className="my-2 overflow-x-auto rounded-lg bg-neutral-950 p-3 font-mono text-[13px] leading-relaxed">
              {children}
            </pre>
          ),
          table: ({ children }) => (
            <div className="my-2 overflow-x-auto">
              <table className="border-collapse text-[14px]">{children}</table>
            </div>
          ),
          th: ({ children }) => (
            <th className="border border-neutral-700 px-3 py-1.5 text-left font-medium">
              {children}
            </th>
          ),
          td: ({ children }) => (
            <td className="border border-neutral-800 px-3 py-1.5">
              {children}
            </td>
          ),
        }}
      >
        {children}
      </ReactMarkdown>
    </div>
  );
}
