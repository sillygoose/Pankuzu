# Cloudflare Worker — Pankuzu Live Activity Push-to-Start

This worker receives push-to-start requests from the Pankuzu app and forwards them to APNs to start a Live Activity on the device when the app is running in the background.

## Files

| File | Purpose |
|------|---------|
| `worker.js` | Cloudflare Worker — handles `/trip-start` and `/charge-start` routes |
| `wrangler.toml` | Wrangler configuration — worker name and entry point |

## Routes

| Route | Description |
|-------|-------------|
| `POST /trip-start` | Start a trip Live Activity via APNs push-to-start |
| `POST /charge-start` | Start a charge Live Activity via APNs push-to-start |

### Request body

```json
{
  "pushToken": "<hex push-to-start token from the device>",
  "bundleId": "com.unchan.pankuzu.Pankuzu",
  "apnsEnvironment": "development | production"
}
```

## Environment variables

Set these in the Cloudflare dashboard under **Workers > pankuzu-trip-la > Settings > Variables**.

| Variable | Description |
|----------|-------------|
| `APNS_TEAM_ID` | Apple Developer Team ID |
| `APNS_KEY_ID_PROD` | Key ID of the production APNs `.p8` key |
| `APNS_KEY_PROD` | Full contents of the production APNs `.p8` key |
| `APNS_KEY_ID_SANDBOX` | Key ID of the sandbox APNs `.p8` key |
| `APNS_KEY_SANDBOX` | Full contents of the sandbox APNs `.p8` key |

APNs keys are created in the Apple Developer portal under **Certificates, Identifiers & Profiles > Keys**. Each key must have the **Apple Push Notifications service (APNs)** capability enabled.

## Deploying

```bash
wrangler deploy --config cloudflare/wrangler.toml
```

Run from the repository root. Requires `wrangler` to be installed (`npm install -g wrangler`) and authenticated (`wrangler login`).
