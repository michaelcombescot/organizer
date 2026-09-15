<script setup lang="ts">
import type { GroupBase } from "../../../backend/api/backend";

defineProps<{ group: GroupBase }>();
</script>

<template>
  <li class="sidebar-group-item">
    <span class="sidebar-group-item-name">{{ group.name }}</span>
  </li>
</template>