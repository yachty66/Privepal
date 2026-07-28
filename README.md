# Privepal

**Fast, private AI chat. Like Threema, but for LLMs.**

Live at [privepal.com](https://privepal.com). iOS app in TestFlight.

## Why this exists

Every mainstream AI chat stores your conversations on someone else's servers,
readable by the operator. Privepal is built so that nobody can read your
chats: not the AI provider, not the datacenter, and as far as technically
possible, not even us. This repo is public so you don't have to take our word
for any of it.

## The trust architecture, honestly

| Claim | Status | How to check |
|---|---|---|
| Chats stored only on your device | enforced | localStorage on web, Data-Protection files on iOS; there is no chat database (search this repo) |
| Inference inside sealed hardware | enforced | [Privatemode](https://www.privatemode.ai) runs models on NVIDIA H100s in confidential-computing mode (AMD SEV-SNP); their proxy verifies hardware attestation before any prompt leaves our infra |
| No tracking, no analytics scripts, no third-party requests | enforced | strict CSP (`web/proxy.ts`) blocks every external host; usage metrics are anonymous aggregate counters (`web/lib/metrics.ts`) |
| Our relay doesn't log your messages | trust + audit | `web/app/api/chat/route.ts` forwards the stream and stores nothing; you have to trust our deployment matches this code, which is the honest limit of any web app |

The last row is why the native app exists: on-device verification (planned)
removes our server from the trust chain entirely.

## Structure

- `web/`: Next.js web app (privepal.com)
- `ios/`: native SwiftUI iOS app
- `api/`: research notes on running our own confidential-compute inference

## Self-host

```bash
# 1. Privatemode encryption proxy (get an API key at privatemode.ai)
docker run -d -p 8080:8080 \
  ghcr.io/edgelesssys/privatemode/privatemode-proxy:latest

# 2. Web app
cd web
cp .env.example .env.local   # set PRIVATEMODE_API_KEY
npm install && npm run dev
```

## Auditing

Found something that contradicts a privacy claim? Please open an issue or
mail support@privepal.com. Breaking our claims is a contribution.

## License

[AGPL-3.0](LICENSE). Run a modified Privepal, publish your changes. Deploys build directly from this repository; verify via privepal.com/api/version.
