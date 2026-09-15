<script setup lang="ts">
import { reactive } from "vue";
import { actorBackend } from "../../../backend/actors/backend";
import { Kind, type CreateGroupParams } from "../../../backend/api/backend";
import i18n from "../../../i18n/i18n";
import { useModalStore } from "../../../stores/display";
import { changeStateDisplayFlash } from "../../../stores/display";
import { changeStateGroups } from "../../../stores/home";

const group = reactive<CreateGroupParams>({ name: "", kind: Kind.personnal, color: "#3498db" });
const modalStore = useModalStore();

async function submit() {
  const response = await (await actorBackend()).createGroup({ ...group });

  if (response.err) {
    changeStateDisplayFlash("error", response.err);
    return;
  }
  if (response.ok) {
    changeStateGroups("add", response.ok);
    modalStore.closeModal();
  }
}
</script>

<template>
  <section>
    <h1>{{ i18n().groupFormNewTitle }}</h1>
    <form @submit.prevent="submit">
      <div class="form-group">
        <label class="required" for="name">{{ i18n().groupFormNameLabel }}</label>
        <input id="name" v-model="group.name" type="text" placeholder="Group name" required minlength="1" maxlength="100" />
      </div>
      <div class="form-group">
        <label class="required" for="kind">{{ i18n().groupFormKindLabel }}</label>
        <select id="kind" v-model="group.kind" required>
          <option v-for="kind in Object.values(Kind)" :key="kind" :value="kind">{{ i18n().groupKind[kind] }}</option>
        </select>
      </div>
      <div class="form-group">
        <label class="required" for="color">{{ i18n().groupFormColorLabel }}</label>
        <input id="color" v-model="group.color" type="color" required />
      </div>
      <button type="submit">{{ i18n().formSubmit }}</button>
    </form>
  </section>
</template>