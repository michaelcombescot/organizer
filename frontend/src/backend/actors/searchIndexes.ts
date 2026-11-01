import { createActor, ReqKind } from "../api/SearchIndexes";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { stateIdentity } from "../../states/auth";
import { stateUserBucket } from "../../states/user";
import { getClosestEntry, getIndexInRing } from "./helpers";
import { stateCanistersSearchIndexes } from "../../states/canisters";
import { actorIndexMain } from "./indexMain";
import { actorBucketUsers } from "./bucketUsers";

export async function actorSearchIndexes(text: string) {
  let hash = getIndexInRing(text);

  let canisterId = getClosestEntry(stateCanistersSearchIndexes.value, hash)?.value;
  if (!canisterId) {
    throw new Error("No suitable canister found for the given text");
  }

  const canisterEnv = safeGetCanisterEnv()!;
  let principal = stateUserBucket.value;
  if (!principal) {
    throw new Error("User bucket is not set");
  }

  return createActor(canisterId, {
    agentOptions: {
      identity: stateIdentity.value,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}

export async function searchUsersFromText(text: string) {
  const actor = await actorSearchIndexes(text);
  let resSearch = await actor.handlerPublicSearch({
    limit: BigInt(50),
    requests: [[ReqKind.usersByName, text], [ReqKind.usersByEmail, text], [ReqKind.usersByPrincipal, text]] 
  });
  
  if (resSearch && "err" in resSearch) {
    throw new Error(`Search failed or returned no results: ${JSON.stringify(resSearch.err)}`);
  }

  const indexes = resSearch.ok.flatMap((loc) =>
    loc.bucketHash
  );

  if (indexes.length === 0) {
    throw new Error("No indexes found for the given text");
  }

  const buckets = await (await (actorIndexMain())).handlerGetBucketUsers(indexes);
  if (buckets && "err" in buckets) {
    throw new Error(`Failed to get bucket users: ${JSON.stringify(buckets.err)}`);
  }

  const fetchPromises = buckets.ok.map((bucket) => (await actorBucketUsers(bucket)).([bucket]));

  const results = await Promise.all(fetchPromises);
  if (results.length === 0) {
    throw new Error("No results found for the given text");
  }
  return results;
}