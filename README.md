# Privepal

Fast, private AI chat. Like Threema, but for LLMs.

- **Snappy**: sub-200ms first token via Privatemode (EU confidential compute)
- **Private**: inference runs in GPU TEEs (attested, encrypted end-to-end), chat history lives only on the user's device, the server stores nothing
- **Models**: gpt-oss-120b ("Fast"), Kimi K2.6 ("Smart")

## Structure

- `web/`: Next.js web app (current focus, rapid prototyping)
- `ios/`: native iOS app (later, App Store target)
- `api/`: research notes on running our own confidential-compute inference (long-term option, currently using Privatemode as provider)

## Dev setup

1. Start the Privatemode proxy (does attestation + encryption):

```bash
docker run -d --name pm-proxy -p 8080:8080 \
  ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest \
  --apiKey $PRIVATEMODE_API_KEY
```

2. Run the web app:

```bash
cd web
cp .env.example .env.local   # fill in values
npm install
npm run dev
```

Open http://localhost:3000.

## Architecture notes

- The web app's `/api/chat` route only forwards the SSE stream from the proxy; it never logs or stores messages.
- Chats are persisted client-side in localStorage.
- Provider is abstracted behind one OpenAI-compatible endpoint; Tinfoil (cheaper, US) can be swapped in later.
- Benchmarks (2026-07-22, Berlin): Privatemode TTFT 94-185ms / 68-87 tok/s, Tinfoil TTFT 578-817ms / 48-111 tok/s.
