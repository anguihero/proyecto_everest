import { test, expect } from '@playwright/test';

test('assigned user can open the runner', async ({ page }) => {
  const email = process.env.E2E_EMAIL;
  const password = process.env.E2E_PASSWORD;
  if (!email || !password) test.skip(true, 'E2E credentials are required');

  const browserErrors = [];
  page.on('pageerror', error => browserErrors.push(error.stack ?? error.message));
  page.on('console', message => {
    if (message.type() === 'error' && message.text().includes('[Runner]')) {
      browserErrors.push(message.text());
    }
  });

  await page.goto('http://localhost:59871/');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.locator('#login-form').evaluate(form => form.requestSubmit());
  await page.waitForURL(/hub\.html/, { timeout: 15_000 });

  const expeditionLink = page.locator(
    '#experience-grid a[data-assignment-id]',
  ).first();
  await expect(expeditionLink).toBeVisible();
  await expeditionLink.click();

  await page.waitForURL(/runner\.html/, { timeout: 10_000 });
  await page.waitForFunction(() => {
    const runner = document.querySelector('#view-runner');
    const error = document.querySelector('#view-error');
    return !runner?.classList.contains('hidden')
      || !error?.classList.contains('hidden');
  });
  if (await page.locator('#view-error').isVisible()) {
    throw new Error(`Runner browser errors: ${JSON.stringify(browserErrors)}`);
  }
  await expect(page.locator('#view-runner')).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('#options-group input[name="choice"]')).toHaveCount(4);
  expect(browserErrors).toEqual([]);
});

test('OrgAdmin can select an explicit optional due date', async ({ page }) => {
  const email = process.env.E2E_ADMIN_EMAIL;
  const password = process.env.E2E_PASSWORD;
  if (!email || !password) test.skip(true, 'E2E admin credentials are required');

  await page.goto('http://localhost:59871/');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.locator('#login-form').evaluate(form => form.requestSubmit());
  await page.waitForURL(/admin\.html/, { timeout: 15_000 });

  await expect(page.locator('#users-tbody tr').first()).toBeVisible();
  await page.locator('[data-tab="assignments"]').click();
  await page.locator('#btn-new-assignment').click();
  await expect(page.locator('#sel-due-day')).toBeVisible();
  await expect(page.locator('#sel-due-month')).toBeVisible();
  await expect(page.locator('#sel-due-year')).toBeVisible();
  await expect(page.locator('#sel-due-day option')).toHaveCount(32);
  await expect(page.locator('#sel-due-month option')).toHaveCount(13);
  await expect(page.locator('#sel-due-year option')).toHaveCount(7);
});
