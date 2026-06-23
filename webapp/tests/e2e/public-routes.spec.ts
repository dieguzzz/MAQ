import { test, expect } from "@playwright/test";

const PROTECTED = ["/map", "/reports", "/profile", "/routes", "/leaderboards"];

test.describe("Public routes & redirects", () => {
  test("/login renders the login shell", async ({ page }) => {
    const errors: string[] = [];
    page.on("pageerror", (e) => errors.push(e.message));
    page.on("console", (msg) => {
      if (msg.type() === "error") errors.push(msg.text());
    });

    await page.goto("/login");
    await expect(page).toHaveURL(/\/login/);

    // Brand always present
    await expect(page.getByText("MetroPTY", { exact: false }).first()).toBeVisible();
    // Google sign-in button always present
    await expect(page.getByRole("button", { name: /Google/i })).toBeVisible();

    const critical = errors.filter(
      (e) =>
        !/favicon/i.test(e) &&
        !/manifest/i.test(e) &&
        !/the resource .* was preloaded/i.test(e) &&
        !/Failed to load resource/i.test(e) &&
        // Sandbox TLS-interception causes SW registration to fail; not a prod bug.
        !/SSL certificate/i.test(e) &&
        !/Failed to register a ServiceWorker/i.test(e)
    );
    expect(critical, `Console errors:\n${critical.join("\n")}`).toHaveLength(0);
  });

  test("root / redirects somewhere sensible", async ({ page }) => {
    const resp = await page.goto("/");
    expect(resp?.status()).toBeLessThan(500);
    await expect(page).toHaveURL(/\/(login|map)/);
  });

  for (const path of PROTECTED) {
    test(`${path} without session redirects to /login with redirect param`, async ({ page, context }) => {
      await context.clearCookies();
      await page.goto(path);
      await expect(page).toHaveURL(/\/login(\?|$)/);
      const url = new URL(page.url());
      expect(url.searchParams.get("redirect")).toBe(path);
    });
  }
});
