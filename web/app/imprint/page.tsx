import Link from "next/link";

export const metadata = { title: "Impressum | Privepal" };

// TODO(max): fill in real name, address and email before launch.
// Required by § 5 DDG for any publicly offered service in Germany.

export default function Imprint() {
  return (
    <div className="min-h-dvh bg-black text-neutral-100">
      <div className="mx-auto max-w-2xl px-4 py-10">
        <Link
          href="/"
          className="text-sm text-neutral-500 hover:text-neutral-300"
        >
          &larr; back to chat
        </Link>
        <h1 className="mt-8 text-2xl font-semibold tracking-tight">
          Impressum
        </h1>
        <div className="mt-6 space-y-4 text-sm leading-relaxed text-neutral-300">
          <p>Angaben gemäß § 5 DDG:</p>
          <p>
            [VOLLSTÄNDIGER NAME]
            <br />
            [STRASSE HAUSNUMMER]
            <br />
            [PLZ ORT]
            <br />
            Deutschland
          </p>
          <p>
            Kontakt:
            <br />
            E-Mail: support@privepal.com
          </p>
          <p>
            Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV:
            <br />
            [VOLLSTÄNDIGER NAME], Anschrift wie oben
          </p>
        </div>
      </div>
    </div>
  );
}
