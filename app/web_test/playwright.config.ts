import { defineConfig, devices } from "@playwright/test";

/** The web build (`flutter build web --dart-define=SHIREITOU_SEMANTICS=true`) is served here. */
export const port = Number(process.env.SHIREITOU_WEB_PORT ?? 8765);

export default defineConfig({
	testDir: "tests",
	// Every test starts its own hosts; one browser at a time keeps CI steady.
	workers: 1,
	timeout: 180_000,
	expect: { timeout: 30_000 },
	retries: process.env.CI ? 1 : 0,
	reporter: process.env.CI ? [["list"], ["github"]] : "list",
	use: {
		...devices["Desktop Chrome"],
		baseURL: `http://127.0.0.1:${port}`,
		viewport: { width: 1400, height: 1000 },
		trace: "retain-on-failure",
	},
	webServer: {
		command: `python3 -m http.server ${port} --bind 127.0.0.1 --directory ../build/web`,
		url: `http://127.0.0.1:${port}/index.html`,
		reuseExistingServer: !process.env.CI,
	},
});
