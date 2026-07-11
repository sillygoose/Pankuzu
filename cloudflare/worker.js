export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response("Method not allowed", { status: 405 })
    }

    const url = new URL(request.url)
    let body
    try {
      body = await request.json()
    } catch {
      return new Response("Invalid JSON", { status: 400 })
    }

    if (url.pathname === "/trip-start") {
      return handleTripStart(body, env)
    }
    if (url.pathname === "/charge-start") {
      return handleChargeStart(body, env)
    }
    if (url.pathname === "/trip-token") {
      return new Response(null, { status: 204 })
    }

    return new Response("Not found", { status: 404 })
  }
}

async function handleTripStart(body, env) {
  const { pushToken, bundleId, apnsEnvironment } = body
  if (!pushToken || !bundleId) {
    return new Response(
      `Missing fields. Got: pushToken=${!!pushToken} bundleId=${!!bundleId} keys=${Object.keys(body).join(",")}`,
      { status: 400 }
    )
  }
  const deviceToken = pushToken
  const isProd = apnsEnvironment === "production"
  const apnsHost = isProd ? "api.push.apple.com" : "api.development.push.apple.com"
  const apnsKey = isProd ? env.APNS_KEY_PROD : env.APNS_KEY_SANDBOX
  const apnsKeyId = isProd ? env.APNS_KEY_ID_PROD : env.APNS_KEY_ID_SANDBOX

  let jwt
  try {
    jwt = await getCachedApnsJwt(apnsKey, apnsKeyId, env.APNS_TEAM_ID)
  } catch (e) {
    return new Response("JWT signing failed: " + e.message, { status: 500 })
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    aps: {
      timestamp: now,
      event: "start",
      "dismissal-date": now + (2 * 60),
      "content-state": {
        tripState: { starting: {} },
        duration: [0, 0],
        distance: 0
      },
      "attributes-type": "TripWindSockActivityAttributes",
      attributes: {
        tripID: crypto.randomUUID().toUpperCase()
      },
      alert: {
        title: "Trip Started",
        body: "Pankuzu is tracking your trip"
      }
    }
  }

  const apnsResp = await fetch(
    `https://${apnsHost}/3/device/${deviceToken}`,
    {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": `${bundleId}.push-type.liveactivity`,
        "apns-push-type": "liveactivity",
        "apns-expiration": "0",
        "apns-priority": "10",
      },
      body: JSON.stringify(payload)
    }
  )

  if (!apnsResp.ok) {
    const detail = await apnsResp.text()
    return new Response("APNs error: " + detail, { status: 502 })
  }

  return new Response(null, { status: 204 })
}

async function handleChargeStart(body, env) {
  const { pushToken, bundleId, apnsEnvironment } = body
  if (!pushToken || !bundleId) {
    return new Response(
      `Missing fields. Got: pushToken=${!!pushToken} bundleId=${!!bundleId} keys=${Object.keys(body).join(",")}`,
      { status: 400 }
    )
  }
  const deviceToken = pushToken
  const isProd = apnsEnvironment === "production"
  const apnsHost = isProd ? "api.push.apple.com" : "api.development.push.apple.com"
  const apnsKey = isProd ? env.APNS_KEY_PROD : env.APNS_KEY_SANDBOX
  const apnsKeyId = isProd ? env.APNS_KEY_ID_PROD : env.APNS_KEY_ID_SANDBOX

  let jwt
  try {
    jwt = await getCachedApnsJwt(apnsKey, apnsKeyId, env.APNS_TEAM_ID)
  } catch (e) {
    return new Response("JWT signing failed: " + e.message, { status: 500 })
  }

  const now = Math.floor(Date.now() / 1000)
  const payload = {
    aps: {
      timestamp: now,
      event: "start",
      "dismissal-date": now + (2 * 60),
      "content-state": {
        chargeState: { starting: {} },
        duration: [0, 0]
      },
      "attributes-type": "ChargeSessionActivityAttributes",
      attributes: {
        chargeID: crypto.randomUUID().toUpperCase()
      },
      alert: {
        title: "Charging Started",
        body: "Pankuzu is tracking your charge session"
      }
    }
  }

  const apnsResp = await fetch(
    `https://${apnsHost}/3/device/${deviceToken}`,
    {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": `${bundleId}.push-type.liveactivity`,
        "apns-push-type": "liveactivity",
        "apns-expiration": "0",
        "apns-priority": "10",
      },
      body: JSON.stringify(payload)
    }
  )

  if (!apnsResp.ok) {
    const detail = await apnsResp.text()
    return new Response("APNs error: " + detail, { status: 502 })
  }

  return new Response(null, { status: 204 })
}

const jwtCache = new Map()

async function getCachedApnsJwt(p8Key, keyId, teamId) {
  const now = Math.floor(Date.now() / 1000)
  const cached = jwtCache.get(keyId)
  if (cached && (now - cached.generatedAt) < 45 * 60) {
    return cached.jwt
  }
  const jwt = await makeApnsJwt(p8Key, keyId, teamId)
  jwtCache.set(keyId, { jwt, generatedAt: now })
  return jwt
}

async function makeApnsJwt(p8Key, keyId, teamId) {
  const pemBody = p8Key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "")

  const keyData = Uint8Array.from(atob(pemBody), c => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  )

  const header = b64url(JSON.stringify({ alg: "ES256", kid: keyId }))
  const claims = b64url(JSON.stringify({ iss: teamId, iat: Math.floor(Date.now() / 1000) }))
  const message = `${header}.${claims}`

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    cryptoKey,
    new TextEncoder().encode(message)
  )

  return `${message}.${b64url(signature)}`
}

function b64url(data) {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data)
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")
}
