import { test, expect } from "@playwright/test";

test.describe("Visual smoke", () => {
  test("login page renders without layout shift", async ({ page }) => {
    await page.goto("/login");
    await expect(page.getByText("MetroPTY", { exact: false }).first()).toBeVisible();
    await page.addStyleTag({
      content: `*, *::before, *::after { animation-duration: 0s !important; transition-duration: 0s !important; }`,
    });
    // Capture a baseline snapshot (will create on first run)
    await expect(page).toHaveScreenshot("login.png", {
      fullPage: false,
      maxDiffPixelRatio: 0.05,
    });
  });
});
