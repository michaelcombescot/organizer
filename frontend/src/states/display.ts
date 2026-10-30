import type { ComponentChildren } from "preact";
import { signal } from "@preact/signals";
import { deepSignal } from 'deepsignal';

// MODAL

export let stateModal = deepSignal({
  visible: false,
  content: null as ComponentChildren,
});

// SIDEBAR

export let stateSidebar = signal(false);

// FLASHES

export let stateFlashes = deepSignal({
  flashInfo: "",
  flashError: "",
  flashWarning: "",
});