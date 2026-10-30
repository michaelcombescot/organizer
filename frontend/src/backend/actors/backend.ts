import { createActor } from "../api/backend";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { STATE_IDENTITY } from "../../states/auth";

// Name of the canister in icp.yaml, read from the `ic_env` cookie
const CANISTER_NAME = "RegistryIndexes";

export async function actorBackend() {
  const canisterEnv = safeGetCanisterEnv();
  const canisterId = canisterEnv?.[`PUBLIC_CANISTER_ID:${CANISTER_NAME}`];
  if (!canisterId) {
    throw new Error(`Canister "${CANISTER_NAME}" not found in ic_env cookie`);
  }

  return createActor(canisterId, {
    agentOptions: {
      identity: STATE_IDENTITY,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}