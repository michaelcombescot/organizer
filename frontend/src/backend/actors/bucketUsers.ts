import { createActor } from "../api/BucketUsers";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { stateIdentity } from "../../states/auth";
import { stateUserBucket } from "../../states/user";
import type { Principal } from "@icp-sdk/core/principal";

export async function actorBucketUsersCurrent() {
  const canisterEnv = safeGetCanisterEnv()!;
  let principal = stateUserBucket.value;
  if (!principal) {
    throw new Error("User bucket is not set");
  }

  return createActor(principal.toString(), {
    agentOptions: {
      identity: stateIdentity.value,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}

export async function actorBucketUsers(principal: Principal) {
  const canisterEnv = safeGetCanisterEnv()!;
  return createActor(principal.toString(), {
    agentOptions: {
      identity: stateIdentity.value,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}