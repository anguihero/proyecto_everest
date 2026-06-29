import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './test',
  testMatch: '**/*.e2e.spec.mjs',
  timeout: 30_000,
  use: {
    headless: true,
    browserName: 'chromium',
    launchOptions: {
      executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    },
  },
});

