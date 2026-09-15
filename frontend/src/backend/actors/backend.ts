import { createActor } from "../api/backend";
import { safeGetCanisterEnv } from "@icp-sdk/core/agent/canister-env";
import { STATE_IDENTITY } from "../../stores/auth";

interface CanisterEnv {
  readonly "PUBLIC_CANISTER_ID:backend": string;
}

const canisterEnv = safeGetCanisterEnv() as CanisterEnv & { IC_ROOT_KEY?: Uint8Array };
const canisterId = canisterEnv["PUBLIC_CANISTER_ID:backend"];

export async function actorBackend() {
  return createActor(canisterId, {
    agentOptions: {
      identity: STATE_IDENTITY,
      rootKey: !import.meta.env.DEV ? canisterEnv.IC_ROOT_KEY : undefined,
      shouldFetchRootKey: import.meta.env.DEV,
    },
  });
}