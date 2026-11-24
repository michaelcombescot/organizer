import { createActor, ReqUser, type ReqKind } from "../api/SearchIndexes";
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
    if (!text || text.trim() === "") {
      return [];
    }

    const actor = this.createActor(text);

    // 1. Retrieve localisation of matched users
    let resSearch = await actor.handlerPublicSearch({
      limit: BigInt(20),
      requests: {
        text,
        kinds: [
          { __kind__: "reqUsers", reqUsers: ReqUser.usersByName },
          { __kind__: "reqUsers", reqUsers: ReqUser.usersByEmail },
          { __kind__: "reqUsers", reqUsers: ReqUser.usersByPrincipal },
        ] satisfies ReqKind[],
      }
    });

    if (resSearch && "err" in resSearch) return [];

    const locs = resSearch.ok

    if (locs.length === 0) {
      return [];
    }

    // 2. Retrieve real bucket Principals
    var buckets = await (await (actorIndexMain())).handlerGetBucketUsers(locs);
    if (buckets && "err" in buckets) {
      throw new Error(`Failed to get bucket users: ${JSON.stringify(buckets.err)}`);
    }

    // 3. Retrieve public data for each user in the buckets
    const fetchPromises = buckets.ok.map(async (bucket) => {
      let principals = bucket.users.map((owner) => {
        if (owner.__kind__ !== "principal") {
          throw new Error(`Unexpected user owner kind: ${owner.__kind__}`);
        }

        return owner.principal;
      });

      return (await actorBucketUsers(bucket.bucket)).handlerGetUsersPublicData(principals);
    });

    let users = (await Promise.all(fetchPromises)).map((res) => res && "ok" in res ? res.ok : []).flat();

    return [
      ...new Map(
        users.map((user) => [user.principal.toText(), user])
      ).values(),
    ]
  }
}