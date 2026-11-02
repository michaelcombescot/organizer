import { createActor, ReqKind } from "../api/SearchIndexes";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { stateIdentity } from "../../states/auth";
import { stateUserBucket } from "../../states/user";
import { getClosestEntry, getIndexInRing } from "./helpers";
import { stateCanistersSearchIndexes } from "../../states/canisters";
import { actorIndexMain } from "./indexMain";
import { actorBucketUsers } from "./bucketUsers";

export class SearchIndexesActor {
  private createActor(text: string) {
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

  async searchUsersFromText(text: string) {
    const actor = this.createActor(text);

    // 1. Retrieve localisation of matched users
    let resSearch = await actor.handlerPublicSearch({
      limit: BigInt(50),
      requests: { text: text, kinds: [ReqKind.usersByName, ReqKind.usersByEmail, ReqKind.usersByPrincipal] }
    });
    
    if (resSearch && "err" in resSearch) {
      throw new Error(`Search failed or returned no results: ${JSON.stringify(resSearch.err)}`);
    }

    const locs = resSearch.ok

    if (locs.length === 0) {
      return [];
    }

    // 2. Retrieve real bucket Principals
    const buckets = await (await (actorIndexMain())).handlerGetBucketUsers(locs);
    if (buckets && "err" in buckets) {
      throw new Error(`Failed to get bucket users: ${JSON.stringify(buckets.err)}`);
    }

    // 3. Retrieve public data for each user in the buckets
    const fetchPromises = buckets.ok.map(async (bucket) => (await actorBucketUsers(bucket)).handlerGetUsersPublicData([bucket]));

    return await Promise.all(fetchPromises)
  }
}