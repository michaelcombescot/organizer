import { signal } from "@preact/signals";
import type { Principal } from "@icp-sdk/core/principal";

export let stateUserBucket = signal<Principal | null>();