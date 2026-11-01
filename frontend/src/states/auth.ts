import { AuthClient } from "@icp-sdk/auth/client";
import { signal } from "@preact/signals";
import { actorRegistryIndexes } from "../backend/actors/registryIndexes";
import { stateCanistersIndexMain, stateCanistersSearchIndexes } from "./canisters";
import { actorIndexMain } from "../backend/actors/indexMain";
import { stateUserBucket, stateUserData } from "./user";
import { stateFlashes } from "./display";
import { actorBucketUsersCurrent } from "../backend/actors/bucketUsers";

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

if (stateAuthenticated.value) {
  await loadUserData();
}

async function loadUserData() {
  stateAuthenticated.value = await AUTH_CLIENT.isAuthenticated();
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();

  // Retrieve main indexes
  let mainIndexes = await (await actorRegistryIndexes()).handlerGetMainIndexes();
  stateCanistersIndexMain.value = mainIndexes;

  // Retrieve search indexes
  let resSearchIndexes = await (await actorIndexMain()).handlerGetSearchIndexes();
  if (resSearchIndexes && "ok" in resSearchIndexes) {
    stateCanistersSearchIndexes.value = new Map(resSearchIndexes.ok);
  } else {
    stateFlashes.flashError = `Failed to get search indexes`;
    console.log(`Failed to get search indexes:`, resSearchIndexes);
  }

  // Retrieve the current user's bucket
  let resUserBucket =  await (await actorIndexMain()).handlerGetCurrentUserBucket()
  if (resUserBucket && "ok" in resUserBucket) {
    stateUserBucket.value = resUserBucket.ok;
  } else {
    stateFlashes.flashError = `Failed to get user bucket`
    console.log(`Failed to get user bucket:`, resUserBucket)
  }

  // Retrieve the current user data
  let resUserData = await (await actorBucketUsersCurrent()).handlerGetUserData();
  if (resUserData && "ok" in resUserData) {
    stateUserData.userData = resUserData.ok;
  } else {
    let resUserData = await (await actorBucketUsersCurrent()).handlerCreateUser();
    if (resUserData && "ok" in resUserData) {
      console.log(`User crated successfully:`);
    } else {
      stateFlashes.flashError = `Failed to create user data`;
      console.log(`Failed to create user data:`, resUserData);
    }
  }
}

export async function signIn() {
  // await AUTH_CLIENT.signOut(); // nettoie proprement les credentials

  await AUTH_CLIENT.signIn({
    maxTimeToLive: BigInt(8) * BigInt(3_600_000_000_000), // 8 hours
  });
  
  await loadUserData();
}

// Sign out
export async function signOut() {
  await AUTH_CLIENT.signOut();
  stateAuthenticated.value = false;
  stateIdentity.value = await AUTH_CLIENT.getIdentity();
  statePrincipal.value = (await AUTH_CLIENT.getIdentity()).getPrincipal().toString();
}