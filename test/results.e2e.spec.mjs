import { test, expect } from '@playwright/test';

test('completed result shows radar, timing and audit reference', async ({ page }) => {
  const email = process.env.E2E_RESULT_EMAIL;
  const password = process.env.E2E_PASSWORD;
  const sessionId = process.env.E2E_RESULT_SESSION;
  if (!email || !password || !sessionId) {
    test.skip(true, 'E2E result credentials and session are required');
  }

  await page.goto('http://localhost:59871/');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.locator('#login-form').evaluate(form => form.requestSubmit());
  await page.waitForURL(/hub\.html/, { timeout: 15_000 });

  await page.goto(`http://localhost:59871/results.html?session=${sessionId}`);
  await expect(page.locator('#results-content')).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('#disc-radar svg')).toBeVisible();
  await expect(page.locator('#disc-radar polygon')).toHaveCount(6);
  for (const dimension of ['D', 'I', 'S', 'C']) {
    const label = page.locator('#disc-radar text').filter({
      hasText: new RegExp(`^${dimension} \\d+%$`),
    });
    await expect(label).toBeVisible();
    const box = await label.boundingBox();
    const svgBox = await page.locator('#disc-radar svg').boundingBox();
    expect(box.x).toBeGreaterThanOrEqual(svgBox.x);
    expect(box.x + box.width).toBeLessThanOrEqual(svgBox.x + svgBox.width);
  }
  await expect(page.locator('#average-time')).not.toBeEmpty();
  await expect(page.locator('#result-reference')).toContainText(/^EV-/);
  await expect(page.locator('#result-version')).toContainText('Scoring');
});
