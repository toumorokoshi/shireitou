/**
 * Hosts and helpers for the browser tests: the scripted fake host
 * (`dart run ahp_fake_host`), pi with its faux model
 * (`scripts/pi-faux-host.ts`), and a TCP relay that drops connections the
 * way a network does.
 */
import { type ChildProcess, spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { createServer, type Server, type Socket, connect as tcpConnect } from "node:net";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { expect, type Page } from "@playwright/test";

export const repo = resolve(dirname(fileURLToPath(import.meta.url)), "../../..");
export const piDir = process.env.PI_AHP_HOST_DIR ?? join(repo, "../pi-agent-host-protocol");

/** Why pi cannot run here, or undefined when it can. */
export const piUnavailable = !existsSync(join(piDir, "node_modules/@earendil-works"))
	? `no pi-agent-host-protocol checkout with node_modules at ${piDir} (set PI_AHP_HOST_DIR)`
	: undefined;

export interface Host {
	url: URL;
	stop(): Promise<void>;
}

/** Runs [command] and resolves with the `ws://` URL it prints once listening. */
async function launch(command: string, args: string[], cwd: string): Promise<{ process: ChildProcess; url: URL }> {
	const child = spawn(command, args, { cwd, stdio: ["ignore", "pipe", "pipe"] });
	let log = "";
	child.stderr?.on("data", (chunk) => {
		log += chunk;
	});
	const url = await new Promise<URL>((done, fail) => {
		const timer = setTimeout(() => fail(new Error(`${command} did not start: ${log}`)), 180_000);
		let out = "";
		child.stdout?.on("data", (chunk) => {
			out += chunk;
			const match = /listening on (ws:\/\/\S+)/.exec(out);
			if (match) {
				clearTimeout(timer);
				done(new URL(match[1]));
			}
		});
		child.once("exit", (code) => {
			clearTimeout(timer);
			fail(new Error(`${command} exited with ${code}: ${log}`));
		});
	});
	return { process: child, url };
}

async function terminate(child: ChildProcess): Promise<void> {
	if (child.exitCode !== null) return;
	const exited = new Promise((done) => child.once("exit", done));
	child.kill("SIGTERM");
	const timer = setTimeout(() => child.kill("SIGKILL"), 10_000);
	await exited;
	clearTimeout(timer);
}

/** The scripted fake host (see docs/fake-host.md). */
export async function startFakeHost(): Promise<Host> {
	const { process: child, url } = await launch(
		"dart",
		["run", "ahp_fake_host", "--port", "0", "--token", "web", "--slow-seconds", "30"],
		join(repo, "packages/ahp_fake_host"),
	);
	return { url, stop: () => terminate(child) };
}

export interface PiHost extends Host {
	/** Stops pi and starts it again on the same port and sessions. */
	restart(): Promise<void>;
}

/** pi with the faux model (see docs/testing.md); its sessions live in a temp directory. */
export async function startPiHost(): Promise<PiHost> {
	const stateDir = await mkdtemp(join(tmpdir(), "shireitou-web-pi-"));
	const start = (port: number) =>
		launch(
			"node",
			[join(repo, "scripts/pi-faux-host.ts"), "--pi-dir", piDir, "--state-dir", stateDir, "--port", `${port}`],
			repo,
		);
	let current = await start(0);
	const port = Number(current.url.port);
	return {
		url: current.url,
		restart: async () => {
			await terminate(current.process);
			current = await start(port);
		},
		stop: async () => {
			await terminate(current.process);
			await rm(stateDir, { recursive: true, force: true });
		},
	};
}

/**
 * A loopback TCP relay in front of a host: `drop` closes every relayed
 * connection, `refusing` turns new ones away (the host looks down), and
 * `hold` loses what clients send.
 */
export class Relay {
	readonly #server: Server;
	readonly #pairs = new Set<[Socket, Socket]>();
	refusing = false;
	#holding = false;

	private constructor(
		server: Server,
		readonly target: number,
	) {
		this.#server = server;
	}

	static async start(target: number): Promise<Relay> {
		const server = createServer();
		const relay = new Relay(server, target);
		server.on("connection", (client) => relay.#accept(client));
		await new Promise<void>((done) => server.listen(0, "127.0.0.1", done));
		return relay;
	}

	get port(): number {
		const address = this.#server.address();
		if (address === null || typeof address === "string") throw new Error("not listening");
		return address.port;
	}

	/** [url] through the relay. */
	relayed(url: URL): string {
		const copy = new URL(url);
		copy.port = `${this.port}`;
		return copy.toString();
	}

	#accept(client: Socket): void {
		if (this.refusing) {
			client.destroy();
			return;
		}
		const upstream = tcpConnect(this.target, "127.0.0.1");
		const pair: [Socket, Socket] = [client, upstream];
		this.#pairs.add(pair);
		const close = () => {
			this.#pairs.delete(pair);
			client.destroy();
			upstream.destroy();
		};
		client.on("data", (data) => {
			if (!this.#holding) upstream.write(data);
		});
		upstream.on("data", (data) => client.write(data));
		for (const socket of pair) {
			socket.on("close", close);
			socket.on("error", close);
		}
	}

	drop(): void {
		for (const [client, upstream] of this.#pairs) {
			client.destroy();
			upstream.destroy();
		}
		this.#pairs.clear();
		this.#holding = false;
	}

	/** Black-holes what clients send until the next `drop`: their actions never arrive. */
	hold(): void {
		this.#holding = true;
	}

	async close(): Promise<void> {
		this.drop();
		await new Promise((done) => this.#server.close(done));
	}
}

// ── The app ──────────────────────────────────────────────────────────────

/**
 * Opens the app and connects to [url] through the connect screen. The web
 * build has its semantics tree on (`SHIREITOU_SEMANTICS`), so widgets are
 * found by their accessible names.
 */
export async function connect(page: Page, url: string): Promise<void> {
	await page.goto("/");
	await expect(page.getByText("Connect to a host")).toBeVisible({ timeout: 60_000 });
	await page.getByRole("textbox", { name: "Host URL" }).fill(url);
	await page.getByRole("button", { name: "Connect" }).click();
}

/** The follow-up box, focused with the Ctrl+L shortcut; types and sends [text]. */
export async function send(page: Page, text: string): Promise<void> {
	await expect(page.getByRole("button", { name: "Send", exact: true })).toBeVisible();
	await page.keyboard.press("Control+KeyL");
	await expect(page.getByRole("textbox", { name: /^Send a follow-up/ })).toBeFocused();
	await page.keyboard.type(text);
	await page.keyboard.press("Enter");
}

/**
 * Clicks into the app (an empty spot, or the follow-up box when a session
 * is open) so it has the keyboard focus: after the focused element went
 * away, keys go to the page body.
 */
export async function focusApp(page: Page): Promise<void> {
	// The connect page's route transition may still remove the element
	// that took the focus, so check it stayed.
	await expect(async () => {
		await page.mouse.click(1000, 900);
		await page.waitForTimeout(300);
		const inApp = await page.evaluate(() => document.querySelector("flutter-view")?.contains(document.activeElement));
		expect(inApp).toBe(true);
	}).toPass();
}
