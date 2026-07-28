import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!;
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!;
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!.replace(/\\n/g, '\n');

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// --- Get an OAuth2 access token for FCM using the service account ---
async function getAccessToken(): Promise<string> {
  const jwtHeader = { alg: 'RS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const jwtClaimSet = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();
  const base64url = (input: Uint8Array | string) => {
    const bytes = typeof input === 'string' ? encoder.encode(input) : input;
    return btoa(String.fromCharCode(...bytes))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  };

  const headerB64 = base64url(JSON.stringify(jwtHeader));
  const claimB64 = base64url(JSON.stringify(jwtClaimSet));
  const unsignedToken = `${headerB64}.${claimB64}`;

  const keyData = FIREBASE_PRIVATE_KEY
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '');
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryKey,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    encoder.encode(unsignedToken),
  );

  const signedJwt = `${unsignedToken}.${base64url(new Uint8Array(signature))}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signedJwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

// --- Build the notification text based on type ---
function buildMessage(type: string, actorName: string | null) {
  const name = actorName ?? 'Someone';
  switch (type) {
    case 'like':
      return { title: 'New Like', body: `${name} liked your post` };
    case 'comment':
      return { title: 'New Comment', body: `${name} commented on your post` };
    case 'share':
      return { title: 'New Share', body: `${name} shared your post` };
    default:
      return { title: 'New Notification', body: `${name} interacted with your post` };
  }
}

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record; // Supabase webhook wraps the row in `record`

    if (!record) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), { status: 400 });
    }

    const { recipient_id, actor_id, type, post_id } = record;

    // Fetch actor's name for the message text
    const { data: actor } = await supabase
      .from('profiles')
      .select('name')
      .eq('id', actor_id)
      .single();

    // Fetch all device tokens for the recipient
    const { data: tokens, error: tokensError } = await supabase
      .from('device_tokens')
      .select('fcm_token')
      .eq('user_id', recipient_id);

    if (tokensError) throw tokensError;
    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ message: 'No device tokens for recipient' }), { status: 200 });
    }

    const accessToken = await getAccessToken();
    const { title, body } = buildMessage(type, actor?.name);

    const results = await Promise.all(
      tokens.map(async ({ fcm_token }) => {
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token: fcm_token,
                notification: { title, body },
                data: {
                  post_id: post_id ?? '',
                  type: type ?? '',
                },
              },
            }),
          },
        );
        return res.json();
      }),
    );

    return new Response(JSON.stringify({ success: true, results }), { status: 200 });
  } catch (err) {
    console.error('Error sending push notification:', err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});