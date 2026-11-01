/// <reference types="vite/client" />

import 'preact';

declare module 'preact' {
  namespace JSX {
    interface HTMLAttributes {
      popovertarget?: string;
      popoverTarget?: string;
      popovertargetaction?: 'hide' | 'show' | 'toggle';
      popoverTargetAction?: 'hide' | 'show' | 'toggle';
    }
  }
}