import { AuthClient } from "@icp-sdk/auth/client";
import { signal } from "@preact/signals";

// Init client

function getIdentityProviderUrl() {
  const host = window.location.hostname;
  const isLocal =
    host === "localhost" ||
    host === "127.0.0.1" ||
    host.endsWith(".localhost");

  return isLocal ? "http://id.ai.localhost:8000/authorize" : "https://id.ai/authorize";
}

export const AUTH_CLIENT = new AuthClient({
    identityProvider: getIdentityProviderUrl(),
});

// States

export let stateAuthenticated = signal(AUTH_CLIENT.isAuthenticated());
export let stateIdentity = signal(await AUTH_CLIENT.getIdentity());
export let statePrincipal = signal((await AUTH_CLIENT.getIdentity()).getPrincipal().toString());

// Update authentication states

export async function signIn() {
  await AUTH_CLIENT.signIn({
    maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000), // 8 hours
  });
  stateAuthenticated.value = await AUTH_CLIENT.isAuthenticated();
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();
}

// Sign out
export async function signOut() {
  await AUTH_CLIENT.signOut();
  stateAuthenticated.value = false;
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();
}