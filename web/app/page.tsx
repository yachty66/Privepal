"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import Link from "next/link";
import { Chat, Message, loadChats, newChat, saveChats } from "@/lib/store";
import { streamChat } from "@/lib/sse";
import Markdown from "@/components/Markdown";
import { AUDIT_LINKS } from "@/lib/audit";

const MODELS = [
  { id: "gpt-oss-120b", label: "Fast" },
  { id: "kimi-k2.6", label: "Smart" },
] as const;

function CopyButton({
  text,
  className = "",
}: {
  text: string;
  className?: string;
}) {
  const [copied, setCopied] = useState(false);
  return (
    <button
      onClick={() => {
        navigator.clipboard.writeText(text).then(() => {
          setCopied(true);
          setTimeout(() => setCopied(false), 1500);
        });
      }}
      title="Copy"
      className={`mt-1 flex items-center gap-1 text-[11px] text-neutral-600 opacity-60 transition-opacity hover:text-neutral-300 focus:opacity-100 sm:opacity-0 sm:group-hover:opacity-100 ${className}`}
    >
      {copied ? (
        <>
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M20 6L9 17l-5-5" />
          </svg>
          copied
        </>
      ) : (
        <>
          <svg
            viewBox="0 0 24 24"
            className="h-3.5 w-3.5"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <rect x="9" y="9" width="13" height="13" rx="2" />
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
          </svg>
          copy
        </>
      )}
    </button>
  );
}

const VERIFY_STEPS = [
  "Connecting securely",
  "Verifying sealed hardware",
  "Locking encrypted channel",
];

export default function Home() {
  const [chats, setChats] = useState<Chat[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [input, setInput] = useState("");
  const [model, setModel] = useState<string>("gpt-oss-120b");
  const [busy, setBusy] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [desktopSidebar, setDesktopSidebar] = useState(true);
  const [thinking, setThinking] = useState(false);
  const [channelOk, setChannelOk] = useState<boolean | null>(null);
  const [verifyStep, setVerifyStep] = useState(0);
  const bottomRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    const raw = loadChats();
    // drop empty chats left over from repeated "+ New" clicks
    const loaded = raw.filter((c) => c.messages.length > 0);
    if (loaded.length !== raw.length) saveChats(loaded);
    setChats(loaded);
    if (loaded.length > 0) setActiveId(loaded[0].id);
    // each step completes on a real network event, with a minimum display
    // time so the sequence stays readable on fast connections
    const minStep = (ms: number) =>
      new Promise((resolve) => setTimeout(resolve, ms));
    (async () => {
      // step 1: reach our server and learn which commit it runs
      const reach = fetch("/api/version").then((r) => r.ok);
      await Promise.all([reach.catch(() => false), minStep(700)]);
      setVerifyStep(1);
      // step 2: confirm the proxy's attested channel to the enclave is live
      const shield = fetch("/api/shield")
        .then((r) => r.json())
        .then((s) => !!s.proxyOk)
        .catch(() => false);
      const [ok] = await Promise.all([shield, minStep(900)]);
      setVerifyStep(2);
      // step 3: lock in the result
      await minStep(700);
      setChannelOk(ok);
      setVerifyStep(3);
    })();
  }, []);

  const active = chats.find((c) => c.id === activeId) ?? null;

  const persist = useCallback((next: Chat[]) => {
    setChats(next);
    saveChats(next);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [active?.messages.length, busy]);

  function createChat() {
    // reuse an existing empty chat instead of stacking up "New chat" entries
    const empty = chats.find((c) => c.messages.length === 0);
    if (empty) {
      setActiveId(empty.id);
    } else {
      const c = newChat(model);
      persist([c, ...chats]);
      setActiveId(c.id);
    }
    setSidebarOpen(false);
  }

  function deleteChat(id: string) {
    const chat = chats.find((c) => c.id === id);
    if (
      !confirm(
        `Delete "${chat?.title ?? "this chat"}"? This cannot be undone.`
      )
    )
      return;
    const next = chats.filter((c) => c.id !== id);
    persist(next);
    if (activeId === id) setActiveId(next[0]?.id ?? null);
  }

  const ready = verifyStep === 3 && channelOk === true;

  async function send() {
    const text = input.trim();
    if (!text || busy || !ready) return;

    let chat = active;
    let base = chats;
    if (!chat) {
      chat = newChat(model);
      base = [chat, ...chats];
      setActiveId(chat.id);
    }

    const userMsg: Message = { role: "user", content: text };
    const title =
      chat.messages.length === 0
        ? text.slice(0, 40) + (text.length > 40 ? "..." : "")
        : chat.title;

    let working: Chat = {
      ...chat,
      title,
      model,
      messages: [...chat.messages, userMsg],
      updatedAt: Date.now(),
    };
    const updateWorking = (w: Chat) => {
      working = w;
      persist(base.map((c) => (c.id === w.id ? w : c)));
    };
    updateWorking(working);
    setInput("");
    setBusy(true);
    setThinking(false);

    const controller = new AbortController();
    abortRef.current = controller;
    const t0 = performance.now();
    let ttftMs: number | undefined;
    let acc = "";

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model,
          messages: working.messages.map(({ role, content }) => ({
            role,
            content,
          })),
        }),
        signal: controller.signal,
      });

      if (!res.ok) throw new Error(`HTTP ${res.status}`);

      updateWorking({
        ...working,
        messages: [...working.messages, { role: "assistant", content: "" }],
      });

      for await (const delta of streamChat(res)) {
        if (delta.reasoning && !acc) setThinking(true);
        if (delta.content) {
          if (ttftMs === undefined) {
            ttftMs = Math.round(performance.now() - t0);
            setThinking(false);
          }
          acc += delta.content;
          const msgs = [...working.messages];
          msgs[msgs.length - 1] = { role: "assistant", content: acc, ttftMs };
          updateWorking({ ...working, messages: msgs, updatedAt: Date.now() });
        }
      }
    } catch (err) {
      if ((err as Error).name !== "AbortError") {
        const msgs = [...working.messages];
        const last = msgs[msgs.length - 1];
        const errText =
          "Something went wrong. Is the Privatemode proxy running?";
        if (last?.role === "assistant" && !last.content) {
          msgs[msgs.length - 1] = { role: "assistant", content: errText };
        } else {
          msgs.push({ role: "assistant", content: errText });
        }
        updateWorking({ ...working, messages: msgs });
      }
    } finally {
      setBusy(false);
      setThinking(false);
      abortRef.current = null;
    }
  }

  function stop() {
    abortRef.current?.abort();
  }

  const sidebarContent = (
    <>
      <div className="flex items-center justify-between p-4">
        <span className="flex items-center gap-2">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.png" alt="" className="h-6 w-6 rounded-md" />
          <span className="text-lg font-semibold tracking-tight">
            Privepal
          </span>
          <span className="rounded-full border border-neutral-700 px-1.5 py-0.5 text-[9px] uppercase tracking-wider text-neutral-400">
            beta
          </span>
        </span>
        <span className="flex items-center gap-1">
          <button
            onClick={createChat}
            className="rounded-md bg-neutral-800 px-2.5 py-1 text-sm hover:bg-neutral-700"
          >
            + New
          </button>
          <button
            onClick={() => {
              setDesktopSidebar(false);
              setSidebarOpen(false);
            }}
            aria-label="Hide sidebar"
            title="Hide sidebar"
            className="rounded-md p-1 text-neutral-500 hover:bg-neutral-900 hover:text-neutral-200"
          >
            <svg
              viewBox="0 0 24 24"
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <rect x="3" y="4" width="18" height="16" rx="2" />
              <path d="M9 4v16" />
            </svg>
          </button>
        </span>
      </div>
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2">
        {chats.map((c) => (
          <div
            key={c.id}
            className={`group flex cursor-pointer items-center justify-between rounded-md px-3 py-2 text-sm ${
              c.id === activeId ? "bg-neutral-800" : "hover:bg-neutral-900"
            }`}
            onClick={() => {
              setActiveId(c.id);
              setSidebarOpen(false);
            }}
          >
            <span className="truncate">{c.title}</span>
            <button
              onClick={(e) => {
                e.stopPropagation();
                deleteChat(c.id);
              }}
              className="text-neutral-500 hover:text-neutral-200 sm:hidden sm:group-hover:block"
            >
              ×
            </button>
          </div>
        ))}
      </nav>
      <div className="p-4 text-xs leading-relaxed text-neutral-500">
        <p>
          Private by design. Chats are stored only on this device. Inference
          runs in confidential compute, unreadable even to the operator.
        </p>
        <button
          onClick={() => {
            if (confirm("Delete all chats from this device? This cannot be undone.")) {
              persist([]);
              setActiveId(null);
            }
          }}
          className="mt-3 w-full rounded-md border border-neutral-800 px-2 py-1.5 text-left text-xs text-neutral-400 hover:border-neutral-600 hover:text-neutral-200"
        >
          Wipe all chats from this device
        </button>
        <p className="mt-2 space-x-3">
          <Link href="/shield" className="hover:text-neutral-300">
            Security
          </Link>
          <Link href="/privacy" className="hover:text-neutral-300">
            Privacy
          </Link>
        </p>
      </div>
    </>
  );

  return (
    <div className="flex h-dvh bg-black text-neutral-100">
      {/* Sidebar (desktop) */}
      {desktopSidebar && (
        <aside className="hidden w-64 shrink-0 flex-col border-r border-neutral-800 sm:flex">
          {sidebarContent}
        </aside>
      )}

      {/* Sidebar (mobile drawer) */}
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 sm:hidden">
          <div
            className="absolute inset-0 bg-black/60"
            onClick={() => setSidebarOpen(false)}
          />
          <aside className="absolute inset-y-0 left-0 flex w-72 max-w-[85vw] flex-col border-r border-neutral-800 bg-black pb-[env(safe-area-inset-bottom)]">
            {sidebarContent}
          </aside>
        </div>
      )}

      {/* Main */}
      <main className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-neutral-800 px-4 py-3">
          <button
            onClick={() => {
              setSidebarOpen(true);
              setDesktopSidebar(true);
            }}
            aria-label="Open chats"
            className={`-ml-1 p-1 text-neutral-400 hover:text-neutral-200 ${
              desktopSidebar ? "sm:hidden" : ""
            }`}
          >
            <svg
              viewBox="0 0 24 24"
              className="h-5 w-5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
            >
              <path d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <div className="flex gap-1 rounded-lg bg-neutral-900 p-1">
            {MODELS.map((m) => (
              <button
                key={m.id}
                onClick={() => setModel(m.id)}
                className={`rounded-md px-3 py-1 text-sm ${
                  model === m.id
                    ? "bg-neutral-700 text-white"
                    : "text-neutral-400 hover:text-neutral-200"
                }`}
              >
                {m.label}
              </button>
            ))}
          </div>
          <div className="flex items-center gap-3">
          <span className="hidden items-center gap-1 rounded-full border border-neutral-800 px-2 py-0.5 text-[10px] uppercase tracking-wider text-neutral-500 sm:flex">
            <svg
              viewBox="0 0 24 24"
              className="h-3 w-3"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <rect x="6" y="2" width="12" height="20" rx="2.5" />
              <path d="M11 18h2" />
            </svg>
            iOS soon
          </span>
          <Link
            href="/shield"
            className="flex items-center gap-1.5 text-xs text-neutral-500 hover:text-neutral-200"
            title="How your privacy is protected"
          >
            <svg
              viewBox="0 0 24 24"
              className="h-3.5 w-3.5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M12 2l8 4v6c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V6l8-4z" />
            </svg>
            confidential
          </Link>
          </div>
        </header>

        <div className="flex-1 overflow-y-auto">
          <div className="mx-auto max-w-2xl px-4 py-6">
            {!active || active.messages.length === 0 ? (
              <div className="mt-3 flex flex-col items-center text-center text-neutral-500 sm:mt-24">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src="/logo.png"
                  alt="Privepal"
                  className={`mb-4 h-14 w-14 sm:mb-6 sm:h-20 sm:w-20 ${
                    verifyStep < 3 ? "animate-pulse" : ""
                  }`}
                />
                <p className="text-xl font-medium text-neutral-300 sm:text-2xl">
                  Fast. Private. Yours.
                </p>
                <p className="mt-2 text-sm">
                  Ask anything. Nobody can read it, not even us.
                </p>
                <Link
                  href="/shield"
                  className="mt-5 block w-full max-w-md rounded-xl border border-neutral-800 p-4 sm:mt-8 text-left transition-colors hover:border-neutral-600"
                >
                  <div className="flex flex-col items-center">
                    <div className="relative h-16 w-16 sm:h-24 sm:w-24">
                      <svg viewBox="0 0 100 100" className="h-16 w-16 -rotate-90 sm:h-24 sm:w-24">
                        {/* track */}
                        <circle
                          cx="50"
                          cy="50"
                          r="45"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="5"
                          className="text-neutral-800"
                        />
                        {/* progress */}
                        <circle
                          cx="50"
                          cy="50"
                          r="45"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="5"
                          strokeLinecap="round"
                          strokeDasharray={2 * Math.PI * 45}
                          strokeDashoffset={
                            2 * Math.PI * 45 * (1 - Math.min(verifyStep, 3) / 3)
                          }
                          className={`transition-all duration-700 ease-out ${
                            verifyStep === 3
                              ? channelOk
                                ? "text-green-500"
                                : "text-neutral-600"
                              : "text-white"
                          }`}
                        />
                      </svg>
                      {verifyStep === 3 && channelOk && (
                        <svg
                          viewBox="0 0 24 24"
                          className="absolute inset-0 m-auto h-7 w-7 text-green-500 sm:h-10 sm:w-10"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2.5"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          <path
                            d="M20 6L9 17l-5-5"
                            pathLength="100"
                            className="animate-draw-check"
                          />
                        </svg>
                      )}
                      {verifyStep === 3 && !channelOk && (
                        <span className="absolute inset-0 flex items-center justify-center text-2xl text-neutral-500">
                          ×
                        </span>
                      )}
                    </div>

                    {verifyStep < 3 ? (
                      <div className="mt-4 text-center text-[13px]">
                        <div className="mb-1 text-[11px] uppercase tracking-widest text-neutral-500">
                          Verifying private channel
                        </div>
                        <span className="text-neutral-300">
                          {VERIFY_STEPS[Math.min(verifyStep, 2)]}...
                        </span>
                      </div>
                    ) : null}
                  </div>

                  {verifyStep === 3 && (
                    <div className="animate-pop-in mt-5">
                      <div className="space-y-2.5 text-[13px]">
                        <div className="flex items-center gap-2.5">
                          <span
                            className={`h-2 w-2 shrink-0 rounded-full ${
                              channelOk ? "bg-white" : "bg-neutral-700"
                            }`}
                          />
                          <span className="text-neutral-300">
                            {channelOk
                              ? "Encrypted channel to sealed AI hardware: live"
                              : "Encrypted channel down. Chat is disabled, no unencrypted fallback."}
                          </span>
                        </div>
                        <div className="flex items-center gap-2.5">
                          <span className="h-2 w-2 shrink-0 rounded-full bg-white" />
                          <span className="text-neutral-300">
                            Chats stored only on this device
                          </span>
                        </div>
                        <div className="flex items-center gap-2.5">
                          <span className="h-2 w-2 shrink-0 rounded-full bg-white" />
                          <span className="text-neutral-300">
                            No account, no tracking
                          </span>
                        </div>
                      </div>
                      <div className="mt-3 flex items-center gap-1 text-xs text-neutral-500">
                        See what is proven vs. what you take on trust
                        <svg
                          viewBox="0 0 24 24"
                          className="h-3 w-3"
                          fill="none"
                          stroke="currentColor"
                          strokeWidth="2.5"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                        >
                          <path d="M9 18l6-6-6-6" />
                        </svg>
                      </div>
                    </div>
                  )}
                </Link>
                {verifyStep === 3 && (
                  <div className="animate-pop-in mt-4 text-xs text-neutral-500">
                    Open source. Don&apos;t trust us? Audit the code with{" "}
                    {AUDIT_LINKS.map((l, i) => (
                      <span key={l.name}>
                        <a
                          href={l.href}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="underline decoration-neutral-600 underline-offset-2 hover:text-neutral-300"
                        >
                          {l.name}
                        </a>
                        {i < AUDIT_LINKS.length - 1 ? " · " : ""}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              active.messages.map((m, i) => (
                <div
                  key={i}
                  className={`group mb-4 flex flex-col ${
                    m.role === "user" ? "items-end" : "items-start"
                  }`}
                >
                  <div
                    className={`max-w-[85%] rounded-2xl px-4 py-2.5 ${
                      m.role === "user"
                        ? "whitespace-pre-wrap bg-white text-[15px] leading-relaxed text-black"
                        : "bg-neutral-900 text-neutral-100"
                    }`}
                  >
                    {m.role === "assistant" ? (
                      m.content ? (
                        <Markdown>{m.content}</Markdown>
                      ) : busy && i === active.messages.length - 1 ? (
                        "..."
                      ) : (
                        ""
                      )
                    ) : (
                      m.content
                    )}
                  </div>
                  {m.content && (
                    <CopyButton
                      text={m.content}
                      className={m.role === "user" ? "mr-1" : "ml-1"}
                    />
                  )}
                </div>
              ))
            )}
            {thinking && (
              <div className="mb-4 text-sm text-neutral-500">thinking...</div>
            )}
            <div ref={bottomRef} />
          </div>
        </div>

        <footer className="border-t border-neutral-800 p-4 pb-[max(1rem,env(safe-area-inset-bottom))]">
          <div className="mx-auto flex max-w-2xl items-end gap-2">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  send();
                }
              }}
              rows={1}
              placeholder={
                ready
                  ? "Message Privepal"
                  : channelOk === false && verifyStep === 3
                    ? "Encrypted channel down"
                    : "Verifying private channel..."
              }
              className="max-h-40 flex-1 resize-none rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-3 text-base outline-none placeholder:text-neutral-600 focus:border-neutral-600 sm:text-[15px]"
            />
            {busy ? (
              <button
                onClick={stop}
                className="self-stretch rounded-xl bg-neutral-800 px-4 text-sm hover:bg-neutral-700"
              >
                Stop
              </button>
            ) : (
              <button
                onClick={send}
                disabled={!input.trim() || !ready}
                className="self-stretch rounded-xl bg-white px-4 text-sm font-medium text-black hover:bg-neutral-200 disabled:opacity-40"
              >
                Send
              </button>
            )}
          </div>
        </footer>
      </main>
    </div>
  );
}
