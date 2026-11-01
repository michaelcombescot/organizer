import type { Principal } from "@icp-sdk/core/principal";
import { signal } from "@preact/signals";

export let stateCanistersIndexMain = signal<Principal[]>([])

export let stateCanistersSearchIndexes = signal(new Map())