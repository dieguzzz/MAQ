import { test, expect } from "@playwright/test";

test.describe("PWA", () => {
  test("/manifest.json is valid", async ({ request }) => {
    const resp = await request.get("/manifest.json");
    expect(resp.ok()).toBeTruthy();
    const manifest = await resp.json();
    expect(typeof manifest.name).toBe("string");
    expect(manifest.name.length).toBeGreaterThan(0);
    expect(manifest.start_url).toBe("/map");
    expect(manifest.display).toBe("standalone");
    expect(manifest.theme_color).toMatch(/^#[0-9A-Fa-f]{6}$/);
    expect(Array.isArray(manifest.icons)).toBe(true);
    expect(manifest.icons.length).toBeGreaterThanOrEqual(4);
    const has192 = manifest.icons.some((i: { sizes: string }) => i.sizes === "192x192");
    const has512 = manifest.icons.some((i: { sizes: string }) => i.sizes === "512x512");
    expect(has192 && has512).toBe(true);
  });

  test("/sw.js is served as JavaScript", async ({ request }) => {
    const resp = await request.get("/sw.js");
    expect(resp.ok()).toBeTruthy();
    const ct = resp.headers()["content-type"] ?? "";
    expect(ct).toMatch(/javascript/);
  });

  test("service worker registers on /login", async ({ page }) => {
    await page.goto("/login");
    const registered = await page.evaluate(async () => {
      if (!("serviceWorker" in navigator)) return false;
      for (let i = 0; i < 50; i++) {
        const reg = await navigator.serviceWorker.getRegistration();
        if (reg) return true;
        await new Promise((r) => setTimeout(r, 100));
      }
      return false;
    });
    expect(registered).toBe(true);
  });
});
