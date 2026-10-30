import { createActor } from "../api/IndexMain";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { stateIdentity } from "../../states/auth";
import { stateCanistersIndexMain } from "../../states/canisters";

export async function actorIndexMain() {
  const canisterEnv = safeGetCanisterEnv()!;
  let principal = stateCanistersIndexMain.value[Math.floor(Math.random() * stateCanistersIndexMain.value.length)];

  return createActor(principal.toString(), {
    agentOptions: {
      identity: stateIdentity.value,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}