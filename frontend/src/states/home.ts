import type { GroupBase } from "../backend/api/backend";
import { signal } from "@preact/signals";

export const STATE_GROUPS = signal(new Map<bigint, GroupBase>());

export function changeStateGroups(action: "add", group: GroupBase) {
  if (action === "add") {
    STATE_GROUPS.value = new Map(STATE_GROUPS.value).set(group.id, group);
  }
}
