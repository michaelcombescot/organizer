import type { ComponentChildren } from "preact";
import { signal } from "@preact/signals";
import { useDeepSignal } from 'deepsignal';

// MODAL

export let stateModal = useDeepSignal({
  visible: false,
  content: null as ComponentChildren,
});

// SIDEBAR

export let stateSidebar = signal(false);

// FLASHES

export let stateFlash = useDeepSignal({
  flashInfo: "",
  flashError: "",
  flashWarning: "",
});