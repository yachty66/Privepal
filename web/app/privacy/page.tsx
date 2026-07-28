import Link from "next/link";

export const metadata = { title: "Datenschutz | Privepal" };

// TODO(max): fill in name/address/email (same as Impressum) and have this
// reviewed before scaling. Written to be honest and match the actual
// architecture: no accounts, no tracking, no server-side chat storage.

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
          Datenschutzerklärung
        </h1>
        <div className="mt-6 space-y-5 text-sm leading-relaxed text-neutral-300">
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              1. Verantwortlicher
            </h2>
            <p>
              [VOLLSTÄNDIGER NAME], [ANSCHRIFT], E-Mail: support@privepal.com
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              2. Das Wichtigste zuerst
            </h2>
            <p>
              Privepal ist so gebaut, dass wir möglichst wenig über Sie wissen.
              Es gibt keine Konten, keine Cookies zu Werbe- oder
              Analysezwecken, keine Tracker und keine serverseitige Speicherung
              Ihrer Unterhaltungen.
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              3. Ihre Chat-Inhalte
            </h2>
            <p>
              Ihre Unterhaltungen werden ausschließlich lokal in Ihrem Browser
              gespeichert (localStorage). Zur Erzeugung einer Antwort wird Ihre
              Nachricht über unseren Server an die Privatemode-API der Edgeless
              Systems GmbH (Bochum, Deutschland) übermittelt und dort in einer
              versiegelten Confidential-Computing-Umgebung verarbeitet, die
              weder Edgeless Systems noch deren Rechenzentrumsbetreiber
              einsehen können. Weder wir noch Edgeless Systems speichern
              Chat-Inhalte oder verwenden sie zum Training von KI-Modellen.
              Rechtsgrundlage: Art. 6 Abs. 1 lit. b DSGVO
              (Vertragserfüllung).
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">
              4. Technische Zugriffsdaten
            </h2>
            <p>
              Beim Aufruf der Seite verarbeitet unser Hosting-Anbieter Railway
              Corp. (USA) technisch notwendige Verbindungsdaten (z. B.
              IP-Adresse, Zeitpunkt des Zugriffs) zur Auslieferung der Seite
              und zur Abwehr von Missbrauch. Wir selbst verarbeiten
              IP-Adressen flüchtig im Arbeitsspeicher zur Begrenzung der
              Anfragerate; sie werden nicht dauerhaft gespeichert.
              Rechtsgrundlage: Art. 6 Abs. 1 lit. f DSGVO (berechtigtes
              Interesse an Betrieb und Sicherheit). Mit Railway besteht ein
              Auftragsverarbeitungsvertrag auf Basis der
              EU-Standardvertragsklauseln.
            </p>
          </section>
          <section>
            <h2 className="mb-1 font-medium text-neutral-100">5. Ihre Rechte</h2>
            <p>
              Sie haben nach der DSGVO Rechte auf Auskunft, Berichtigung,
              Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit
              und Widerspruch sowie ein Beschwerderecht bei einer
              Datenschutzaufsichtsbehörde. Da wir keine Inhalte über Sie
              speichern, gibt es in aller Regel schlicht nichts, worüber wir
              Auskunft geben könnten: Ihre Chats liegen nur bei Ihnen.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
