<script setup lang="ts">
import i18n from "../../../i18n/i18n";
import { useModalStore } from "../../../stores/display";
import { STATE_GROUPS } from "../../../stores/home.ts";
import SidebarHomeCardGroup from "./SidebarHomeCardGroup.vue";
import FormAddGroup from "./FormAddGroup.vue";

const modalStore = useModalStore();
</script>

<template>
  <div id="sidebar-groups">
    <div id="sidebar-groups-title">
      <h3>{{ i18n().homeSidebarTitleGroups }}</h3>
      <div id="sidebar-groups-title-actions">
        <button id="action-add-group" type="button" aria-label="Add group" @click="modalStore.openModal('Add group', FormAddGroup)">
          <img src="/add.svg" alt="" />
        </button>
      </div>
    </div>
    <ul id="sidebar-groups-list">
      <li class="sidebar-group-item"><span class="sidebar-group-item-name selected">{{ i18n().homeSidebarSelectGroupsAll }}</span></li>
      <SidebarHomeCardGroup v-for="group in STATE_GROUPS.values()" :key="group.id.toString()" :group="group" />
    </ul>
  </div>
</template>