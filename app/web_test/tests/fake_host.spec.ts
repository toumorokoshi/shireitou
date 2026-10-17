/**
 * The web app in Chromium against the scripted fake host: a session and
 * a reply, the keyboard shortcuts as the browser delivers them, MCP
 * sign-in through a real new tab and the `oauth_callback.html` redirect
 * page, and reconnecting after the connection drops.
 */
import { expect, test } from "@playwright/test";
import { connect, focusApp, type Host, Relay, send, startFakeHost } from "./support.ts";

let host: Host;
let relay: Relay;

test.beforeEach(async () => {
	host = await startFakeHost();
	relay = await Relay.start(Number(host.url.port));
});

test.afterEach(async () => {
	await relay?.close();
	await host?.stop();
});

test("a session, shortcuts, OAuth sign-in and a reconnect", async ({ page, context }) => {
	await connect(page, relay.relayed(host.url));
	const list = page.getByRole("button", { name: /^Scripted session/ });
	await expect(list.first()).toBeVisible();

	// Keys reach the app once it has focus: the Connect button that had it
	// is gone, so click into the app first, as a user would.
	await focusApp(page);

	// Ctrl+K focuses the search field (AV-140).
	await page.keyboard.press("Control+KeyK");
	await expect(page.getByRole("textbox", { name: /^Search/ })).toBeFocused();
	await page.keyboard.type("long");
	await expect(page.getByRole("button", { name: /^Long session/ })).toBeVisible();
	await expect(list).toHaveCount(0);
	await page.getByRole("button", { name: "Close search" }).click();
	await expect(list.first()).toBeVisible();

	// Alt+↓ opens the next session.
	await page.keyboard.press("Alt+ArrowDown");
	await expect(page.getByRole("button", { name: "Send", exact: true })).toBeVisible();
	await list.first().click();
	await expect(page.getByText("No messages yet. Say something.")).toBeVisible();

	// Ctrl+L focuses the follow-up box; Enter sends.
	await send(page, "hello");
	await expect(page.getByText(/^You said: hello/)).toBeVisible();

	// Ctrl+. stops a running turn.
	await send(page, "slow");
	await expect(page.getByText("Working on it slowly.")).toBeVisible();
	await page.keyboard.press("Control+Period");
	await expect(page.getByText(/^Cancelled/).first()).toBeVisible();

	// MCP sign-in: a new tab goes through the fake authorization server
	// and back to oauth_callback.html, which hands the code to this tab.
	await send(page, "auth");
	await page.getByRole("button", { name: "Sign in", exact: true }).click();
	const popup = context.waitForEvent("page");
	await page.getByRole("button", { name: "Sign in with browser" }).click();
	const tab = await popup;
	await tab.waitForURL(/oauth_callback\.html/).catch(() => {
		// The page closes itself once it has posted the redirect.
	});
	await expect(page.getByText("Signed in. I found 2 pages.")).toBeVisible();

	// The connection drops and comes back.
	relay.refusing = true;
	relay.drop();
	await expect(page.getByText("Reconnecting…", { exact: true })).toBeVisible();
	relay.refusing = false;
	await expect(page.getByText("Reconnecting…", { exact: true })).toHaveCount(0);
	await send(page, "after the reconnect");
	await expect(page.getByText(/^You said: after the reconnect/)).toBeVisible();
});
