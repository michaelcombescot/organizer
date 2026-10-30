import type { Principal } from "@icp-sdk/core/principal";
import { signal } from "@preact/signals";

export let stateCanistersIndexMain = signal<Principal[]>([])