import i18n from "../../../i18n/i18n";
import { useModalStore } from "../../../states/display";
import { STATE_GROUPS } from "../../../states/home";
import SidebarHomeCardGroup from "./SidebarHomeCardGroup";
import FormAddGroup from "./FormAddGroup";

export default function SidebarHome() {
  const modalStore = useModalStore();

  return (
    <div id="sidebar-groups">
      <div id="sidebar-groups-title">
        <h3>{i18n().homeSidebarTitleGroups}</h3>
        <div id="sidebar-groups-title-actions">
          <button
            id="action-add-group"
            type="button"
            aria-label="Add group"
            onClick={() => modalStore.openModal(<FormAddGroup />)}
          >
            <img src="/add.svg" alt="" />
          </button>
        </div>
      </div>
      <ul id="sidebar-groups-list">
        <li class="sidebar-group-item">
          <span class="sidebar-group-item-name selected">
            {i18n().homeSidebarSelectGroupsAll}
          </span>
        </li>
        {[...STATE_GROUPS.value.values()].map((group) => (
          <SidebarHomeCardGroup key={group.id.toString()} group={group} />
        ))}
      </ul>
    </div>
  );
}
