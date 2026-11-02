import { signal } from "@preact/signals";
import { deepSignal } from 'deepsignal';
import type { Principal } from "@icp-sdk/core/principal";
import type { PrivateUser } from "../backend/api/BucketUsers";

export let stateUserBucket = signal<Principal | null>();

export const stateUserData = deepSignal<{userData: PrivateUser}>({
  userData: {
    name: "",
    email: "",
    groups: [],
    createdAt: 0n,
    updatedAt: 0n,
  }
});