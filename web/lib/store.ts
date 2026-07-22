// Client-side chat storage. Chats never leave the device: localStorage only.

export type Role = "user" | "assistant";

export interface Message {
  role: Role;
  content: string;
  ttftMs?: number;
}

export interface Chat {
  id: string;
  title: string;
  model: string;
  messages: Message[];
  createdAt: number;
  updatedAt: number;
}

const KEY = "privepal.chats";

export function loadChats(): Chat[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as Chat[]) : [];
  } catch {
    return [];
  }
}

export function saveChats(chats: Chat[]) {
  try {
    localStorage.setItem(KEY, JSON.stringify(chats));
  } catch {
    // storage full or unavailable: drop oldest chats and retry once
    try {
      localStorage.setItem(KEY, JSON.stringify(chats.slice(0, 20)));
    } catch {
      /* give up silently */
    }
  }
}

export function newChat(model: string): Chat {
  const now = Date.now();
  return {
    id: crypto.randomUUID(),
    title: "New chat",
    model,
    messages: [],
    createdAt: now,
    updatedAt: now,
  };
}
