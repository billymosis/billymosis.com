# Deploying to Cloudflare Workers

The site is a static Astro build served by a Cloudflare Worker with
[static assets](https://developers.cloudflare.com/workers/static-assets/) (no Worker script).

- Production: <https://billy.gatsu.org> (Workers Custom Domain in the `gatsu.org` zone)
- Fallback: `https://billymosis-com.<account-subdomain>.workers.dev`

## How deploy works

- `wrangler.jsonc`: Worker name `billymosis-com`, serves `./dist`, keeps the
  workers.dev address on, and attaches the custom hostname under `routes`.
- `public/.assetsignore` keeps Windows `*:Zone.Identifier` files out of the upload.
- `.github/workflows/deploy-cloudflare.yml`:
  - **Pull requests**: `pnpm build` (runs `astro check` + `astro build`) and
    `wrangler deploy --dry-run`. No secrets are used and nothing is deployed.
  - **Push to `main`** (or a manual run on `main`): build, then `wrangler deploy`.

Manual deploy from a checkout (needs `wrangler login` or the two env vars below):

```sh
pnpm install --frozen-lockfile
pnpm build
npx wrangler@4.166.0 deploy
```

## Secrets

Add these as GitHub repository secrets (Settings → Secrets and variables → Actions).
Never commit them.

| Secret | Value |
| --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | The Cloudflare account ID (dashboard → Workers & Pages → right sidebar) |
| `CLOUDFLARE_API_TOKEN` | An API token with the permissions below |

API token (dashboard → My Profile → API Tokens → Create Custom Token), least privilege:

- **Account** → Workers Scripts → **Edit** (the account that owns the Worker)
- **Zone** → Workers Routes → **Edit**, limited to the zone `gatsu.org` (needed
  because every deploy re-applies the custom domain in `routes`)

## Changing the hostname

The hostname appears in two places that must match:

1. `wrangler.jsonc` → `routes[0].pattern` (where the Worker is served)
2. `astro.config.mjs` → `site` (canonical URLs, OpenGraph, sitemap, RSS)

The hostname must belong to a zone on the same Cloudflare account. On the next deploy, wrangler
creates the proxied DNS record and certificate for the new hostname. After you remove or
replace a hostname, check Worker → Settings → Domains & Routes in the dashboard and detach
the old one there if it is still listed.

## Rollback

Pick one:

- **Revert the commit** on `main`. The workflow then redeploys the previous build.
- **Roll back to an earlier version** without a new build:
  `npx wrangler@4.166.0 deployments list` then
  `npx wrangler@4.166.0 rollback <version-id>`, or use the dashboard
  (Worker → Deployments → ⋯ → Rollback).
- **Take the custom hostname offline**: detach `billy.gatsu.org` under Worker →
  Settings → Domains & Routes. The workers.dev address keeps working.
