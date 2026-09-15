<script setup lang="ts">
    import { useSidebarStore } from "../../../stores/display";

    const sidebarStore = useSidebarStore();
</script>

<template>
    <div
        v-if="sidebarStore.visible"
        class="fixed inset-0 z-40 w-64 bg-white border-r"
    >

        <button 
            class="absolute top-1 right-1 h-8 w-8 rounded-full text-gray-400 hover:bg-gray-100 hover:text-gray-700" 
            @click="sidebarStore.closeSidebar()"
        >
            ✕
        </button>

        <div class="pt-10">
            <h1 class="font-bold">Dashboards</h1>
            <ul class="pt-2">
                <li class="flex"><a href="#">Dashboard 1</a></li>
            </ul>
        </div>
    </div>

    <img
        v-if="!sidebarStore.visible"
        class="fixed top-2 left-2 h-6 w-6"
        src="/menu.svg"
        alt="Menu"
        @click="sidebarStore.openSidebar()"
    ></img>
</template>