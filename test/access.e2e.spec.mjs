import { test, expect } from '@playwright/test';

async function login(page, email, password, destination) {
  await page.goto('http://localhost:59871/');
  await page.locator('#email').fill(email);
  await page.locator('#password').fill(password);
  await page.locator('#login-form').evaluate(form => form.requestSubmit());
  await page.waitForURL(destination, { timeout: 15_000 });
}

test('coach can browse results from the organization', async ({ page }) => {
  const email = process.env.E2E_COACH_EMAIL;
  const password = process.env.E2E_PASSWORD;
  if (!email || !password) test.skip(true, 'Coach credentials are required');

  await login(page, email, password, /hub\.html/);
  await expect(page.locator('#btn-team-results')).toBeVisible();
  await page.locator('#btn-team-results').click();
  await page.waitForURL(/results-library\.html/);
  await expect(page.locator('#results-list article').first()).toBeVisible();
  await expect(page.locator('#results-list')).toContainText('Diego');
});

test('sysadmin sees global users and can open password change modal', async ({ page }) => {
  const email = process.env.E2E_SYSADMIN_EMAIL;
  const password = process.env.E2E_PASSWORD;
  if (!email || !password) test.skip(true, 'SysAdmin credentials are required');

  await login(page, email, password, /sysadmin\.html/);
  await expect(page.locator('#stats-grid p').first()).toBeVisible();
  await page.locator('[data-tab="users"]').click();
  await expect(page.locator('#system-users-list article').first()).toBeVisible();
  await page.locator('[data-password-user]').first().click();
  await expect(page.locator('#modal-password')).toBeVisible();
  await expect(page.locator('#new-password')).toBeVisible();
  await expect(page.locator('#confirm-password')).toBeVisible();
});
