"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { loadChats } from "@/lib/store";

interface ShieldStatus {
  proxyOk: boolean;
  models: string[];
  checkedAt: number;
}

interface VersionInfo {
  commit: string | null;
  source: string | null;
}

import { AUDIT_LINKS, AUDIT_PROMPT } from "@/lib/audit";

function CopyAuditPackage() {
  const [state, setState] = useState<"idle" | "copied" | "error">("idle");
  return (
    <button
      onClick={async () => {
        try {
          const res = await fetch("/audit-bundle.txt");
          const bundle = await res.text();
          await navigator.clipboard.writeText(
            `${AUDIT_PROMPT}\n\nHere is the bundle content:\n\n${bundle}`
          );
          setState("copied");
        } catch {
          setState("error");
        }
        setTimeout(() => setState("idle"), 2000);
      }}
      className="rounded-lg border border-neutral-700 px-3.5 py-2 text-sm text-neutral-200 hover:border-neutral-400 hover:text-white"
    >
      {state === "copied"
        ? "Copied, paste into any AI"
        : state === "error"
          ? "Copy failed, open /audit-bundle.txt"
          : "Copy audit package"}
    </button>
  );
}

function VerifySection({ commit }: { commit: string | null }) {
  const short = commit?.slice(0, 12) ?? "<commit>";
  return (
    <div className="mt-10 rounded-xl border border-neutral-800 p-5">
      <h2 className="text-[15px] font-medium text-neutral-100">
        Verify this deployment yourself
      </h2>
      <p className="mt-1.5 text-sm leading-relaxed text-neutral-400">
        Four checks, increasing effort. Any mismatch means our claims are
        broken; please report it.
      </p>
      <ol className="mt-4 space-y-3 text-sm text-neutral-400">
        <li>
          <span className="text-neutral-200">
            1. Ask the server what it runs:
          </span>
          <pre className="mt-1 overflow-x-auto rounded-lg bg-neutral-950 p-3 font-mono text-[12px]">
            curl -s https://privepal.com/api/version
          </pre>
        </li>
        <li>
          <span className="text-neutral-200">
            2. Read exactly that code:
          </span>{" "}
          the response links to the commit on GitHub
          {commit ? (
            <>
              {" "}
              (currently{" "}
              <a
                href={`https://github.com/yachty66/Privepal/tree/${commit}`}
                target="_blank"
                rel="noopener noreferrer"
                className="underline hover:text-neutral-300"
              >
                <code>{short}</code>
              </a>
              )
            </>
          ) : null}
          .
        </li>
        <li>
          <span className="text-neutral-200">
            3. Confirm the pages you receive are stamped with the same commit:
          </span>
          <pre className="mt-1 overflow-x-auto rounded-lg bg-neutral-950 p-3 font-mono text-[12px]">
            {`curl -s https://privepal.com | grep -o 'privepal-commit[^>]*'`}
          </pre>
        </li>
        <li>
          <span className="text-neutral-200">
            4. Rebuild the app from source and compare the served bundles:
          </span>
          <pre className="mt-1 overflow-x-auto rounded-lg bg-neutral-950 p-3 font-mono text-[12px]">
            {`git clone https://github.com/yachty66/Privepal
cd Privepal/web && git checkout ${short}
npm ci && npm run build
# compare .next/static/chunks with what privepal.com serves`}
          </pre>
        </li>
      </ol>
      <p className="mt-4 text-xs leading-relaxed text-neutral-500">
        Honest limits: these checks catch any mismatch in the code your
        browser runs. The server-side relay cannot be externally proven this
        way; a deliberately malicious operator could misreport its own
        version. Closing that gap requires hardware-attested serving, which
        is on our roadmap, and is already how the AI inference itself runs.
      </p>
    </div>
  );
}

function AuditSection() {
  return (
    <div className="mt-10 rounded-xl border border-neutral-800 p-5">
      <h2 className="text-[15px] font-medium text-neutral-100">
        Don&apos;t take our word for it
      </h2>
      <p className="mt-1.5 text-sm leading-relaxed text-neutral-400">
        Our code is open source. One click sends it to an AI you already
        trust, with the question: is this really as private as they claim?
        It&apos;s a second opinion, not a formal proof, but it&apos;s a second
        opinion we can&apos;t influence.
      </p>
      <div className="mt-4 flex flex-wrap gap-2">
        {AUDIT_LINKS.map((l) => (
          <a
            key={l.name}
            href={l.href}
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-lg border border-neutral-700 px-3.5 py-2 text-sm text-neutral-200 hover:border-neutral-400 hover:text-white"
          >
            Ask {l.name} &rarr;
          </a>
        ))}
        <CopyAuditPackage />
      </div>
      <p className="mt-3 text-xs text-neutral-500">
        If the AI can&apos;t fetch URLs, use &quot;Copy audit package&quot;: it
        puts the question plus the complete source of the privacy-critical
        files in your clipboard, ready to paste into any AI. Raw bundle:{" "}
        <a
          href="/audit-bundle.txt"
          target="_blank"
          className="underline hover:text-neutral-400"
        >
          /audit-bundle.txt
        </a>
      </p>
    </div>
  );
}

function Item({
  state,
  title,
  children,
}: {
  state: "verified" | "design" | "trust";
  title: string;
  children: React.ReactNode;
}) {
  const badge =
    state === "verified"
      ? { label: "verified live", cls: "bg-white text-black" }
      : state === "design"
        ? { label: "by design", cls: "border border-neutral-600 text-neutral-300" }
        : { label: "you trust us", cls: "border border-neutral-700 text-neutral-500" };
  return (
    <div className="border-b border-neutral-800 py-5">
      <div className="mb-1.5 flex items-center gap-3">
        <h2 className="text-[15px] font-medium text-neutral-100">{title}</h2>
        <span
          className={`rounded-full px-2 py-0.5 text-[10px] uppercase tracking-wide ${badge.cls}`}
        >
          {badge.label}
        </span>
      </div>
      <p className="text-sm leading-relaxed text-neutral-400">{children}</p>
    </div>
  );
}

export default function Shield() {
  const [status, setStatus] = useState<ShieldStatus | null>(null);
  const [failed, setFailed] = useState(false);
  const [chatCount, setChatCount] = useState(0);
  const [msgCount, setMsgCount] = useState(0);
  const [version, setVersion] = useState<VersionInfo | null>(null);

  useEffect(() => {
    const chats = loadChats();
    setChatCount(chats.length);
    setMsgCount(chats.reduce((n, c) => n + c.messages.length, 0));
    fetch("/api/shield")
      .then((r) => r.json())
      .then(setStatus)
      .catch(() => setFailed(true));
    fetch("/api/version")
      .then((r) => r.json())
      .then(setVersion)
      .catch(() => {});
  }, []);

  const checking = !status && !failed;

  return (
    <div className="min-h-dvh bg-black text-neutral-100">
      <div className="mx-auto max-w-2xl px-4 py-10">
        <Link
          href="/"
          className="text-sm text-neutral-500 hover:text-neutral-300"
        >
          &larr; back to chat
        </Link>

        <div className="mt-8 mb-2 flex items-center gap-4">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.png" alt="" className="h-14 w-14" />
          <div>
            <h1 className="text-2xl font-semibold tracking-tight">
              Your privacy, itemized
            </h1>
            <p className="text-sm text-neutral-500">
              What is proven, what is architecture, and what still needs your
              trust. We list all three, because anyone who claims everything is
              proven is lying.
            </p>
          </div>
        </div>

        <div className="mt-6">
          <Item
            state={status?.proxyOk ? "verified" : "design"}
            title="Encrypted channel to confidential hardware"
          >
            {checking && "Checking the live connection..."}
            {status?.proxyOk &&
              `Live check passed ${new Date(status.checkedAt).toLocaleTimeString()}: the encryption proxy has verified the AI hardware's cryptographic attestation and holds an end-to-end encrypted channel into it. Models behind it right now: ${status.models.join(", ")}.`}
            {(failed || (status && !status.proxyOk)) &&
              "Live check unavailable right now. When the channel is down, chat does not work at all: there is no unencrypted fallback."}
          </Item>

          <Item state="verified" title="Chats live only on this device">
            This browser currently holds {chatCount}{" "}
            {chatCount === 1 ? "chat" : "chats"} with {msgCount}{" "}
            {msgCount === 1 ? "message" : "messages"} in local storage. We have
            no database for your conversations. Clear your browser data and
            they are gone forever, even we could not bring them back.
          </Item>

          <Item state="design" title="AI runs inside sealed hardware">
            Inference runs on NVIDIA H100 GPUs in confidential-computing mode
            inside AMD SEV-SNP encrypted VMs, operated by Privatemode (Edgeless
            Systems, Germany). The hardware signs a measurement of the exact
            code it runs; the encryption proxy rejects the connection unless
            that signature chain verifies against AMD and NVIDIA root
            certificates. Neither the operator nor the datacenter can read
            prompts, and nothing is retained after the response.
          </Item>

          <Item state="design" title="No account, no tracking">
            No sign-up, no cookies for tracking, no analytics scripts on the
            chat. There is nothing to link your conversations to you.
          </Item>

          <Item
            state={version?.commit ? "verified" : "trust"}
            title="This deployment matches the public code"
          >
            {version?.commit ? (
              <>
                This server was built by our host directly from the public
                repository, commit{" "}
                <a
                  href={version.source ?? "#"}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-neutral-300"
                >
                  <code>{version.commit.slice(0, 12)}</code>
                </a>
                . Read exactly that code on GitHub. (You still trust the host
                to build honestly; hardware-attested serving is on the
                roadmap.)
              </>
            ) : (
              "Deploy provenance is being set up: soon this will show the exact public commit this server was built from."
            )}
          </Item>

          <Item state="trust" title="Our relay server">
            Your message passes through our server on its way to the encrypted
            channel, and today you have to trust that we do not log it. We do
            not, and our code is public, but honesty requires the label. The
            fix is already on our roadmap: verification moves into the app on
            your device, so our server becomes a blind pipe. The upcoming
            native app closes this gap completely.
          </Item>
        </div>

        <VerifySection commit={version?.commit ?? null} />

        <AuditSection />

        <p className="mt-8 text-xs leading-relaxed text-neutral-600">
          Want to check the deep claims yourself? Privatemode&apos;s
          attestation flow, manifests, and source are public:{" "}
          <a
            href="https://docs.privatemode.ai"
            target="_blank"
            rel="noopener noreferrer"
            className="underline hover:text-neutral-400"
          >
            docs.privatemode.ai
          </a>
        </p>
      </div>
    </div>
  );
}
