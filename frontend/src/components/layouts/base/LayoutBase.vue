<script setup lang="ts">
    import { computed, ref } from "vue";
    import i18n from "../../../i18n/i18n";
    import { authenticated, STATE_PRINCIPAL, signIn, signOut } from "../../../stores/auth";
    import Sidebar from "./Sidebar.vue";
    import Modal from "./Modal.vue";

    const isAuthenticated = computed(() => authenticated.value);
</script>

<template>
    <div class="layout-base">
        <header
            class="flex justify-between items-center"
        >
            <div id="actions-login-logout">

            <button v-if="isAuthenticated"
                    id="action-logout" 
                    :title="STATE_PRINCIPAL" 
                    type="button"
                    @click="signOut"
            >
                {{ i18n().layoutLogoutLink }}
            </button>

            <button v-else 
                    id="action-login" 
                    type="button" 
                    @click="signIn"
                    class=""
            >
                    {{ i18n().layoutLoginLink }}
                </button>
            </div>
        </header>

        <Sidebar />

        <Modal />        

        <main>
            <RouterView />
        </main>
    </div>
</template>