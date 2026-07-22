# Cloudflare Worker — Pankuzu Live Activity Push-to-Start

This worker receives push-to-start requests from the Pankuzu app and forwards them to APNs to start a Live Activity on the device when the app is running in the background.

## Files

| File | Purpose |
|------|---------|
| `worker.js` | Cloudflare Worker — handles `/trip-overview-start`, `/trip-efficiency-start`, and `/charge-overview-start` routes |
| `wrangler.toml` | Wrangler configuration — worker name, entry point, and environments |

## Environments

Two worker deployments are maintained — one for development builds and one for production. Both are named environments; there is no default. The top-level (unnamed) config in `wrangler.toml` intentionally points at an inert, unused worker name (`pankuzu-trip-la-unset`) so that a `wrangler deploy` run without `--env` — e.g. a forgotten flag — can never silently touch development or production.

| Environment | Worker name | Used by |
|-------------|-------------|---------|
| production | `pankuzu-trip-la` | Release / TestFlight builds |
| development | `pankuzu-trip-la-dev` | Debug builds from Xcode |
| _(none — top-level)_ | `pankuzu-trip-la-unset` | Not used; exists only to make a forgotten `--env` harmless |

The app selects the correct worker URL at compile time via `#if DEBUG`. Set the URLs in `Local.xcconfig` (gitignored):

```xcconfig
WORKER_BASE_URL     = https://<worker-name>.<subdomain>.workers.dev
WORKER_BASE_URL_DEV = https://<worker-name-dev>.<subdomain>.workers.dev
```

## Routes

| Route | Description |
|-------|-------------|
| `POST /trip-overview-start` | Start the trip overview Live Activity via APNs push-to-start |
| `POST /trip-efficiency-start` | Start the trip efficiency-chart Live Activity via APNs push-to-start |
| `POST /charge-overview-start` | Start a charge Live Activity via APNs push-to-start |

### Request body

```json
{
  "pushToken": "<hex push-to-start token from the device>",
  "bundleId": "com.unchan.pankuzu.Pankuzu",
  "apnsEnvironment": "development | production"
}
```

## Environment variables

Set these in the Cloudflare dashboard under **Workers > [worker name] > Settings > Variables**. Each worker environment has its own set of secrets.

| Variable | Description |
|----------|-------------|
| `APNS_TEAM_ID` | Apple Developer Team ID |
| `APNS_KEY_ID_PROD` | Key ID of the production APNs `.p8` key |
| `APNS_KEY_PROD` | Full contents of the production APNs `.p8` key |
| `APNS_KEY_ID_SANDBOX` | Key ID of the sandbox APNs `.p8` key |
| `APNS_KEY_SANDBOX` | Full contents of the sandbox APNs `.p8` key |

APNs keys are created in the Apple Developer portal under **Certificates, Identifiers & Profiles > Keys**. Each key must have the **Apple Push Notifications service (APNs)** capability enabled.

The development worker typically only needs the sandbox keys; the production worker only needs the production keys. Both sets can be configured in each environment for flexibility.

## Deploying

`--env` is required — both environments are named, and there is no default (see [Environments](#environments)).

```bash
# Deploy to development
wrangler deploy --config cloudflare/wrangler.toml --env development

# Deploy to production
wrangler deploy --config cloudflare/wrangler.toml --env production
```

Run from the repository root. Requires `wrangler` to be installed (`npm install -g wrangler`) and authenticated (`wrangler login`).
