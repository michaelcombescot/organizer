import type { GroupBase } from "../../../backend/api/backend";

interface SidebarHomeCardGroupProps {
  group: GroupBase;
}

export default function SidebarHomeCardGroup({ group }: SidebarHomeCardGroupProps) {
  return (
    <li class="sidebar-group-item">
      <span class="sidebar-group-item-name">{group.name}</span>
    </li>
  );
}
