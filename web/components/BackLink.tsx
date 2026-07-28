import Link from "next/link";

export default function BackLink() {
  return (
    <Link
      href="/"
      className="inline-flex items-center gap-1.5 rounded-full border border-neutral-800 py-1.5 pr-3.5 pl-2.5 text-sm text-neutral-400 transition-colors hover:border-neutral-600 hover:text-neutral-100"
    >
      <svg
        viewBox="0 0 24 24"
        className="h-3.5 w-3.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M15 18l-6-6 6-6" />
      </svg>
      Chat
    </Link>
  );
}
