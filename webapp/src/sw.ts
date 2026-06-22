import { defaultCache } from "@serwist/next/worker";
import type { PrecacheEntry, SerwistGlobalConfig } from "serwist";
import { Serwist, NetworkOnly } from "serwist";

declare global {
  interface WorkerGlobalScope extends SerwistGlobalConfig {
    __SW_MANIFEST: (PrecacheEntry | string)[] | undefined;
  }
}

declare const self: WorkerGlobalScope & typeof globalThis;

const serwist = new Serwist({
  precacheEntries: self.__SW_MANIFEST,
  skipWaiting: true,
  clientsClaim: true,
  navigationPreload: true,
  runtimeCaching: [
    {
      urlPattern: /^https:\/\/(apis\.google\.com|maps\.googleapis\.com|maps\.gstatic\.com|www\.googleapis\.com|firestore\.googleapis\.com|identitytoolkit\.googleapis\.com|www\.google-analytics\.com|www\.googletagmanager\.com|.*\.firebaseio\.com|.*\.firebaseapp\.com)/,
      handler: new NetworkOnly(),
    },
    ...defaultCache,
  ],
});

serwist.addEventListeners();
