/**
 * The web app in Chromium against pi-agent-host-protocol with pi's faux
 * model (no API key): starting a session from the composer, a streamed
 * reply, a dropped connection in the middle of a reply (replayed), a
 * message lost with the connection (rolled back) and a host restart.
 */
import { expect, test } from "@playwright/test";
import { connect, focusApp, type PiHost, piUnavailable, Relay, send, startPiHost } from "./support.ts";

test.skip(piUnavailable !== undefined, piUnavailable);

let pi: PiHost;
let relay: Relay;

test.beforeEach(async () => {
	pi = await startPiHost();
	relay = await Relay.start(Number(pi.url.port));
});

test.afterEach(async () => {
	await relay?.close();
	await pi?.stop();
});

test("a session, a reconnect, a lost message and a host restart", async ({ page }) => {
	await connect(page, relay.relayed(pi.url));
	await expect(page.getByText("No sessions yet.")).toBeVisible();
	const reconnecting = page.getByText("Reconnecting…", { exact: true });

	// The composer starts a pi session; the reply streams in.
	await page.getByRole("button", { name: /^New\b/ }).first().click();
	await page.getByRole("textbox", { name: /^Chat with/ }).fill("hello from the browser");
	await page.getByRole("button", { name: "Start session" }).click();
	await expect(page.getByText("pi faux reply: hello from the browser")).toBeVisible();
	await expect(page.getByRole("button", { name: /^hello from the browser/ })).toBeVisible();
	await focusApp(page);

	// The connection drops in the middle of a reply; pi keeps going, and the
	// replay fills in what the browser missed.
	await send(page, "slow, across a reconnect");
	await expect(page.getByText(/^Counting slowly/)).toBeVisible();
	relay.refusing = true;
	relay.drop();
	await expect(reconnecting).toBeVisible();
	await page.waitForTimeout(1500);
	relay.refusing = false;
	await expect(reconnecting).toHaveCount(0);
	await expect(page.getByText(/word3000 done\.$/)).toBeVisible({ timeout: 60_000 });

	// A message that never reached pi is rolled back, with a notice.
	relay.hold();
	await send(page, "lost on the way");
	await expect(page.getByText("lost on the way", { exact: true })).toBeVisible();
	relay.drop();
	await expect(page.getByText(/^The connection dropped before the host confirmed/)).toBeVisible();
	await expect(page.getByText("lost on the way", { exact: true })).toHaveCount(0);

	// pi restarts: the browser initializes again and the session is still there.
	await pi.restart();
	await expect(reconnecting).toHaveCount(0, { timeout: 60_000 });
	await send(page, "after the restart");
	await expect(page.getByText("pi faux reply: after the restart")).toBeVisible();
});
