"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Chat, Message, loadChats, newChat, saveChats } from "@/lib/store";
import { streamChat } from "@/lib/sse";

const MODELS = [
  { id: "gpt-oss-120b", label: "Fast" },
  { id: "kimi-k2.6", label: "Smart" },
] as const;

export default function Home() {
  const [chats, setChats] = useState<Chat[]>([]);
  const [activeId, setActiveId] = useState<string | null>(null);
  const [input, setInput] = useState("");
  const [model, setModel] = useState<string>("gpt-oss-120b");
  const [busy, setBusy] = useState(false);
  const [thinking, setThinking] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  useEffect(() => {
    const loaded = loadChats();
    setChats(loaded);
    if (loaded.length > 0) setActiveId(loaded[0].id);
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
    const c = newChat(model);
    persist([c, ...chats]);
    setActiveId(c.id);
  }

  function deleteChat(id: string) {
    const next = chats.filter((c) => c.id !== id);
    persist(next);
    if (activeId === id) setActiveId(next[0]?.id ?? null);
  }

  async function send() {
    const text = input.trim();
    if (!text || busy) return;

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

  return (
    <div className="flex h-dvh bg-zinc-950 text-zinc-100">
      {/* Sidebar */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-zinc-800 sm:flex">
        <div className="flex items-center justify-between p-4">
          <span className="text-lg font-semibold tracking-tight">Privepal</span>
          <button
            onClick={createChat}
            className="rounded-md bg-zinc-800 px-2.5 py-1 text-sm hover:bg-zinc-700"
          >
            + New
          </button>
        </div>
        <nav className="flex-1 space-y-0.5 overflow-y-auto px-2">
          {chats.map((c) => (
            <div
              key={c.id}
              className={`group flex cursor-pointer items-center justify-between rounded-md px-3 py-2 text-sm ${
                c.id === activeId ? "bg-zinc-800" : "hover:bg-zinc-900"
              }`}
              onClick={() => setActiveId(c.id)}
            >
              <span className="truncate">{c.title}</span>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  deleteChat(c.id);
                }}
                className="hidden text-zinc-500 hover:text-zinc-200 group-hover:block"
              >
                ×
              </button>
            </div>
          ))}
        </nav>
        <p className="p-4 text-xs leading-relaxed text-zinc-500">
          Private by design. Chats are stored only on this device. Inference
          runs in confidential compute, unreadable even to the operator.
        </p>
      </aside>

      {/* Main */}
      <main className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-zinc-800 px-4 py-3">
          <span className="text-sm text-zinc-400 sm:hidden">Privepal</span>
          <div className="flex gap-1 rounded-lg bg-zinc-900 p-1">
            {MODELS.map((m) => (
              <button
                key={m.id}
                onClick={() => setModel(m.id)}
                className={`rounded-md px-3 py-1 text-sm ${
                  model === m.id
                    ? "bg-zinc-700 text-white"
                    : "text-zinc-400 hover:text-zinc-200"
                }`}
              >
                {m.label}
              </button>
            ))}
          </div>
          <span className="text-xs text-zinc-600">🔒 confidential</span>
        </header>

        <div className="flex-1 overflow-y-auto">
          <div className="mx-auto max-w-2xl px-4 py-6">
            {!active || active.messages.length === 0 ? (
              <div className="mt-24 text-center text-zinc-500">
                <p className="text-2xl font-medium text-zinc-300">
                  Fast. Private. Yours.
                </p>
                <p className="mt-2 text-sm">
                  Ask anything. Nobody can read it, not even us.
                </p>
              </div>
            ) : (
              active.messages.map((m, i) => (
                <div
                  key={i}
                  className={`mb-4 flex ${
                    m.role === "user" ? "justify-end" : "justify-start"
                  }`}
                >
                  <div
                    className={`max-w-[85%] whitespace-pre-wrap rounded-2xl px-4 py-2.5 text-[15px] leading-relaxed ${
                      m.role === "user"
                        ? "bg-emerald-700 text-white"
                        : "bg-zinc-900 text-zinc-100"
                    }`}
                  >
                    {m.content ||
                      (busy && i === active.messages.length - 1 ? "..." : "")}
                    {m.role === "assistant" && m.ttftMs !== undefined && (
                      <div className="mt-1 text-[10px] text-zinc-500">
                        first token {m.ttftMs}ms
                      </div>
                    )}
                  </div>
                </div>
              ))
            )}
            {thinking && (
              <div className="mb-4 text-sm text-zinc-500">thinking...</div>
            )}
            <div ref={bottomRef} />
          </div>
        </div>

        <footer className="border-t border-zinc-800 p-4">
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
              placeholder="Message Privepal"
              className="max-h-40 flex-1 resize-none rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-3 text-[15px] outline-none placeholder:text-zinc-600 focus:border-zinc-600"
            />
            {busy ? (
              <button
                onClick={stop}
                className="rounded-xl bg-zinc-800 px-4 py-3 text-sm hover:bg-zinc-700"
              >
                Stop
              </button>
            ) : (
              <button
                onClick={send}
                disabled={!input.trim()}
                className="rounded-xl bg-emerald-700 px-4 py-3 text-sm font-medium text-white hover:bg-emerald-600 disabled:opacity-40"
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
