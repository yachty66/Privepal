import Link from "next/link";

export const metadata = { title: "Privacy | Privepal" };

// Written to be honest and match the actual architecture: no accounts,
// no tracking, no server-side chat storage.

export default function Privacy() {
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
          Privacy Policy
        </h1>
        <div className="mt-6 space-y-5 text-sm leading-relaxed text-neutral-300">
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">1. Contact</h2>
            <p>support@privepal.com</p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              2. The most important part first
            </h2>
            <p>
              Privepal is built so that we know as little about you as
              possible. There are no accounts, no advertising or analytics
              cookies, no trackers, and no server-side storage of your
              conversations.
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              3. Your chat content
            </h2>
            <p>
              Your conversations are stored exclusively in your browser
              (localStorage). To generate a response, your message is relayed
              through our server to the Privatemode API of Edgeless Systems
              GmbH (Bochum, Germany), where it is processed inside a sealed
              confidential-computing environment that neither Edgeless
              Systems nor their datacenter operator can look into. Neither we
              nor Edgeless Systems store chat content or use it to train AI
              models. Legal basis: Art. 6(1)(b) GDPR (performance of the
              service).
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              4. Technical access data
            </h2>
            <p>
              When you visit the site, our hosting provider Railway Corp.
              (USA) processes technically necessary connection data (such as
              IP address and time of access) to deliver the site and defend
              against abuse. We ourselves process IP addresses transiently in
              memory to rate-limit requests; they are never stored
              permanently. Legal basis: Art. 6(1)(f) GDPR (legitimate
              interest in operating and securing the service). A data
              processing agreement based on the EU Standard Contractual
              Clauses is in place with Railway.
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              5. Your rights
            </h2>
            <p>
              Under the GDPR you have the right to access, rectification,
              erasure, restriction of processing, data portability, and
              objection, as well as the right to lodge a complaint with a
              supervisory authority. Since we store no content about you,
              there is usually simply nothing for us to disclose: your chats
              live only with you.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
