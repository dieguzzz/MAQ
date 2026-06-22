import { defaultCache } from "@serwist/next/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { Serwist } from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: WorkerGlobalScope & typeof globalThis;

// Skip cross-origin requests entirely — let the browser handle them natively
// without Serwist wrapping them in respondWith (which breaks on fetch failures).
// eslint-disable-next-line @typescript-eslint/no-explicit-any
self.addEventListener("fetch", (event: any) => {
  if (new URL(event.request.url).origin !== self.location.origin) {
    event.stopImmediatePropagation();
    return;
  }
});

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: false,
  runtimeCaching: defaultCache,
});

serwist.addEventListeners();
