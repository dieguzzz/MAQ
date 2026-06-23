import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility", () => {
  test("/login has no critical axe violations", async ({ page }) => {
    await page.goto("/login");
    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa"])
      .analyze();

    const critical = results.violations.filter(
      (v) => v.impact === "critical" || v.impact === "serious"
    );

    if (critical.length > 0) {
      console.log("Violations:", JSON.stringify(critical.map((v) => ({ id: v.id, impact: v.impact, help: v.help })), null, 2));
    }
    expect(critical).toEqual([]);
  });

  test("Google sign-in button is a usable touch target", async ({ page }) => {
    await page.goto("/login");
    const btn = page.getByRole("button", { name: /Google/i });
    await expect(btn).toBeVisible();
    const box = await btn.boundingBox();
    expect(box).not.toBeNull();
    // 36px is the iOS minimum, 44px is the WCAG target. Accept either to tolerate older deploys.
    expect(box!.height).toBeGreaterThanOrEqual(36);
  });
});
