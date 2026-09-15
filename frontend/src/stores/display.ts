import { defineStore } from "pinia";
import { ref, shallowRef, type Component } from "vue";

export const useModalStore = defineStore('modal', () => {
  const visible = ref(false)
  const content = shallowRef<Component | null>(null)

  function openModal(c: Component) {
    content.value = c
    visible.value = true
  }

  function closeModal() {
    visible.value = false
    content.value = null
  }
  
  return { visible, content, openModal, closeModal }
})

export const useSidebarStore = defineStore('sidebar', () => {
  const visible = ref(false)

  function openSidebar() { visible.value = true }
  function closeSidebar() { visible.value = false }

  return { visible, openSidebar, closeSidebar }
})