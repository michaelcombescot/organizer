import { createActor } from "../api/RegistryIndexes";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { stateIdentity } from "../../states/auth";

const CANISTER_NAME = "RegistryIndexes";

export async function actorBackend() {
  const canisterEnv = safeGetCanisterEnv();
  const canisterId = canisterEnv?.[`PUBLIC_CANISTER_ID:${CANISTER_NAME}`];
  if (!canisterId) {
    throw new Error(`Canister "${CANISTER_NAME}" not found in ic_env cookie`);
  }

  return createActor(canisterId, {
    agentOptions: {
      identity: stateIdentity.value,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}