#!/usr/bin/env node
/**
 * Runs a pi-agent-host-protocol host whose model is pi's scripted "faux"
 * provider, so app and client tests stream real pi turns without an API
 * key or network access. pi runs embedded (its SDK in this process), with
 * the host's own code from a pi-agent-host-protocol checkout.
 *
 * Usage:
 *   node scripts/pi-faux-host.ts [--pi-dir DIR] [--state-dir DIR]
 *     [--port N] [--token T | --no-token] [--tokens-per-second N]
 *
 * --pi-dir     the checkout (default $PI_AHP_HOST_DIR, else a sibling of
 *              this repo); it needs `npm ci`.
 * --state-dir  where sessions, settings and the archive live (default: a
 *              new temp directory, removed on exit). Pass the same one to
 *              a restarted host to keep its sessions.
 * --port       0 (default) for a free port; reuse a port to restart a
 *              host where clients expect it.
 *
 * Prints `pi-agent-host-protocol listening on ws://…` once ready, then
 * runs until SIGINT or SIGTERM.
 *
 * The model answers by keyword in the newest user message (see
 * docs/testing.md):
 *   "tool"  → runs `echo hello from pi` with pi's bash tool, then reports
 *             the output;
 *   "slow"  → a long reply (about 12 s) to stop, queue behind or reconnect
 *             during;
 *   "think" → reasoning, then a reply;
 *   else    → "pi faux reply: <message>".
 */
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

const { values } = parseArgs({
	options: {
		"pi-dir": { type: "string" },
		"state-dir": { type: "string" },
		port: { type: "string", default: "0" },
		token: { type: "string" },
		"no-token": { type: "boolean", default: false },
		"tokens-per-second": { type: "string", default: "500" },
	},
});

const repo = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const piDir = resolve(values["pi-dir"] ?? process.env.PI_AHP_HOST_DIR ?? join(repo, "../pi-agent-host-protocol"));
const temp = values["state-dir"] === undefined;
const stateDir = values["state-dir"] ?? (await mkdtemp(join(tmpdir(), "shireitou-pi-faux-")));
const workspace = join(stateDir, "workspace");
await mkdir(join(workspace, "src"), { recursive: true });
await mkdir(join(workspace, "docs"), { recursive: true });

// pi's settings directory is read when the host's modules load.
process.env.PI_AGENT_HOST_PROTOCOL_DIR = join(stateDir, "settings");
process.env.PI_OFFLINE = "1";
process.env.PI_SKIP_VERSION_CHECK = "1";
process.env.PI_AGENT_HOST_PROTOCOL_DAEMON = "1";

// Imported by file URL: this script is not inside the checkout, so its
// packages (import-only exports) cannot be resolved by name from here.
const load = (path: string) => import(pathToFileURL(join(piDir, path)).href);
const piAi = await load("node_modules/@earendil-works/pi-ai/dist/index.js");
const piAgent = await load("node_modules/@earendil-works/pi-coding-agent/dist/index.js");
const { AgentHost } = await load("src/host/agent-host.ts");
const { fileArchiveStore } = await load("src/host/archive-store.ts");
const { EmbeddedBackend } = await load("src/pi/embedded-backend.ts");
const { listen } = await load("src/transport/websocket.ts");
const { createLogger } = await load("src/core/logger.ts");

type Block = { type: string; text?: string };
type Message = { role: string; content: string | Block[]; toolName?: string };

const textOf = (content: string | Block[]): string =>
	typeof content === "string"
		? content
		: content
				.filter((b) => b.type === "text")
				.map((b) => b.text ?? "")
				.join("");

/** The scripted reply to [context], by keyword in the newest user message. */
function respond(context: { messages: Message[] }) {
	const { fauxAssistantMessage, fauxText, fauxThinking, fauxToolCall } = piAi;
	const last = context.messages.at(-1);
	if (last?.role === "toolResult") {
		return fauxAssistantMessage(`The ${last.toolName} tool printed: ${textOf(last.content).trim()}`);
	}
	const said = textOf(last?.content ?? "").trim();
	const lower = said.toLowerCase();
	if (lower.includes("tool")) {
		return fauxAssistantMessage([fauxText("Running a command."), fauxToolCall("bash", { command: "echo hello from pi" })], {
			stopReason: "toolUse",
		});
	}
	if (lower.includes("slow")) {
		const words = Array.from({ length: 3000 }, (_, i) => `word${i + 1}`).join(" ");
		return fauxAssistantMessage(`Counting slowly: ${words} done.`);
	}
	if (lower.includes("history")) {
		const users = context.messages.filter((m) => m.role === "user").map((m) => textOf(m.content).trim());
		return fauxAssistantMessage(`pi faux history: ${users.join(" | ")}`);
	}
	if (lower.includes("think")) {
		return fauxAssistantMessage([fauxThinking("The user wants me to think first."), fauxText(`Thought about: ${said}`)]);
	}
	return fauxAssistantMessage(`pi faux reply: ${said}`);
}

const modelRuntime = await piAgent.ModelRuntime.create({
	authPath: join(stateDir, "auth.json"),
	modelsPath: null,
	allowModelNetwork: false,
	refreshOnCreate: false,
});
const faux = piAi.fauxProvider({
	provider: "faux",
	models: [{ id: "faux-1", name: "Faux One" }],
	tokensPerSecond: Number(values["tokens-per-second"]),
});
// Every model call asks `respond`; a long-lived host needs many steps.
faux.setResponses(Array.from({ length: 100_000 }, () => respond));
modelRuntime.registerNativeProvider(faux.provider);
// Without credentials pi does not list a provider's models as available.
await modelRuntime.setRuntimeApiKey("faux", "test-key");

const backend = await EmbeddedBackend.create({
	agentDir: join(stateDir, "agent"),
	sessionDir: join(stateDir, "sessions"),
	modelRuntime,
	sessionOverrides: { model: faux.getModel(), settingsManager: piAgent.SettingsManager.inMemory() },
});
const host = new AgentHost({
	backend,
	defaultDirectory: workspace,
	serverVersion: "faux",
	logger: createLogger("warn"),
	archive: await fileArchiveStore(join(stateDir, "archived-sessions.json")),
});
await host.refreshAgents();
const listener = await listen(host, {
	host: "127.0.0.1",
	port: Number(values.port),
	token: values["no-token"] ? undefined : (values.token ?? "faux-token"),
});
console.log(`pi-agent-host-protocol listening on ${listener.url}`);

const shutdown = async () => {
	await listener.close();
	await host.dispose();
	if (temp) await rm(stateDir, { recursive: true, force: true });
	process.exit(0);
};
process.once("SIGINT", shutdown);
process.once("SIGTERM", shutdown);
