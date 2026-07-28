// Client-side chat storage. Chats never leave the device: localStorage only.

export type Role = "user" | "assistant";

export interface Message {
  role: Role;
  content: string;
  ttftMs?: number;
}

export interface Chat {
  id: string;
  // random human-readable name used in the local /c/<slug> link;
  // optional because chats saved by older versions lack it
  slug?: string;
  title: string;
  model: string;
  messages: Message[];
  createdAt: number;
  updatedAt: number;
}

const SLUG_ADJECTIVES = [
  "amber", "brisk", "calm", "dusky", "eager", "fuzzy", "gentle", "hazel",
  "ivory", "jolly", "keen", "lucid", "mellow", "noble", "opal", "plum",
  "quiet", "rosy", "sable", "tidy", "umber", "vivid", "wry", "zesty",
];
const SLUG_NOUNS = [
  "otter", "falcon", "birch", "comet", "dune", "ember", "fjord", "grove",
  "harbor", "iris", "jasper", "kite", "lagoon", "meadow", "nimbus", "orchid",
  "pebble", "quill", "reef", "sparrow", "thicket", "umbra", "willow", "zephyr",
];

export function newSlug(): string {
  const pick = (list: string[]) => list[Math.floor(Math.random() * list.length)];
  const suffix = Math.random().toString(36).slice(2, 6);
  return `${pick(SLUG_ADJECTIVES)}-${pick(SLUG_NOUNS)}-${suffix}`;
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
    slug: newSlug(),
    title: "New chat",
    model,
    messages: [],
    createdAt: now,
    updatedAt: now,
  };
}
