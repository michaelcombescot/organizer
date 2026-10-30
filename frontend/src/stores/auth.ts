import { AuthClient } from "@icp-sdk/auth/client";
import { signal } from "@preact/signals";

function getIdentityProviderUrl() {
  const host = window.location.hostname;
  const isLocal =
    host === "localhost" ||
    host === "127.0.0.1" ||
    host.endsWith(".localhost");

  return isLocal ? "http://id.ai.localhost:8000/authorize" : "https://id.ai/authorize";
}

export const STATE_AUTH_CLIENT = new AuthClient({
    identityProvider: getIdentityProviderUrl(),
});

export let STATE_IDENTITY = await STATE_AUTH_CLIENT.getIdentity();

export let STATE_PRINCIPAL = "";
export const authenticated = signal(STATE_AUTH_CLIENT.isAuthenticated());

export async function changeStateAuthenticated() {
    STATE_PRINCIPAL = (await STATE_AUTH_CLIENT.getIdentity()).getPrincipal().toString();
    STATE_IDENTITY = await STATE_AUTH_CLIENT.getIdentity();
  authenticated.value = await STATE_AUTH_CLIENT.isAuthenticated();
}


export async function signIn() {
  await STATE_AUTH_CLIENT.signIn({
    maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000), // 8 hours
  });
  await changeStateAuthenticated();
}

// Sign out
export async function signOut() {
  await STATE_AUTH_CLIENT.signOut();
  await changeStateAuthenticated();
}