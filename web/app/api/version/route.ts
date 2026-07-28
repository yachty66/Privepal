// Deployment provenance. When Railway builds this app directly from the
// public GitHub repo, it injects the commit SHA at build time; exposing it
// lets anyone tie the running deployment to exact public source code.

const sha = process.env.RAILWAY_GIT_COMMIT_SHA ?? null;
const branch = process.env.RAILWAY_GIT_BRANCH ?? null;

export async function GET() {
  return Response.json(
    {
      commit: sha,
      branch,
      source: sha
        ? `https://github.com/yachty66/Privepal/tree/${sha}`
        : null,
      provenance: sha
        ? "built by Railway from the public GitHub repository"
        : "manual CLI deploy (provenance not yet verifiable)",
    },
    { headers: { "Cache-Control": "no-store" } }
  );
}
