import { AuthClient } from "@icp-sdk/auth/client";
import { signal } from "@preact/signals";
import { actorRegistryIndexes } from "../backend/actors/registryIndexes";
import { stateCanistersIndexMain } from "./canisters";
import { actorIndexMain } from "../backend/actors/indexMain";
import { stateUserBucket } from "./userData";
import { stateFlashes } from "./display";

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
  // await AUTH_CLIENT.signOut(); // nettoie proprement les credentials

  await AUTH_CLIENT.signIn({
    maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000), // 8 hours
  });
  stateAuthenticated.value = await AUTH_CLIENT.isAuthenticated();
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();

  // Retrieve main indexes
  let mainIndexes = await (await actorRegistryIndexes()).handlerGetMainIndexes();
  stateCanistersIndexMain.value = mainIndexes;

  // Retrieve the current user's bucket
  let resUserBucket =  await (await actorIndexMain()).handlerGetCurrentUserBucket()
  if (resUserBucket && "ok" in resUserBucket) {
    stateUserBucket.value = resUserBucket.ok;
  } else {
    stateFlashes.flashError = `Failed to get user bucket`
    console.log(`Failed to get user bucket:`, resUserBucket)
  }
}

// Sign out
export async function signOut() {
  await AUTH_CLIENT.signOut();
  stateAuthenticated.value = false;
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();
}