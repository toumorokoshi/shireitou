# Linting, formatting, tests and running. See specs/linting.md.

prettier := "npx --yes prettier@3.3.3"

# Check formatting and linting (markdown and Dart).
lint:
    {{prettier}} --check "**/*.md"
    dart format --output=none --set-exit-if-changed .
    cd packages/ahp_client && dart analyze --fatal-infos
    cd packages/ahp_wire_gen && dart analyze --fatal-infos
    cd packages/ahp_fake_host && dart analyze --fatal-infos
    cd packages/flutter_pty && dart analyze --fatal-infos
    cd app && flutter analyze --fatal-infos

# Format markdown and Dart files.
format:
    {{prettier}} --write "**/*.md"
    dart format .

# Apply lint fixes, then format.
fix:
    cd packages/ahp_client && dart fix --apply
    cd packages/ahp_wire_gen && dart fix --apply
    cd packages/ahp_fake_host && dart fix --apply
    cd packages/flutter_pty && dart fix --apply
    cd app && dart fix --apply
    just format

# Run unit and widget tests (pi integration tests excluded), and the
# client flows against the scripted fake host.
test:
    cd packages/ahp_wire_gen && dart test
    cd packages/ahp_client && dart test -x integration
    cd packages/ahp_fake_host && dart test -x integration
    cd packages/flutter_pty && dart test
    cd app && flutter test -x screenshots

# Run the scripted fake AHP host (asks for approvals, input and sign-in;
# see packages/ahp_fake_host). Pass `--port N`, `--token T` or `--no-token`.
fake-host *args:
    cd packages/ahp_fake_host && dart run ahp_fake_host {{args}}

# Render the sessions screen (dark, light, phone, a hovered row) to
# app/build/screenshots/*.png to compare with
# design/reference/agents-window.png. Needs macOS for its system fonts;
# see docs/testing.md.
screenshots:
    cd app && flutter test -t screenshots test/screenshots

# Drive the real app against the fake host: approvals, input requests,
# session-level requests, MCP sign-in, terminals, diffs and review,
# subagent chats, queued messages, drafts and paging; a second host, the
# composer and session settings; reconnects. Linux needs a
# display; `flutter-tester` runs it headless (no window plugin).
test-fake-host-app device="linux":
    cd app && flutter test integration_test/fake_host_flows_test.dart -d {{device}}

# Run the integration tests against pi-agent-host-protocol: the handshake
# without a model, and client flows (replies, tools, stop, reconnects, a
# host restart) with pi's faux model, so no API key is needed. Set
# PI_AHP_HOST_DIR to the checkout (default: a sibling of this repo); it
# needs `npm ci`.
test-integration:
    cd packages/ahp_client && dart test -t integration -x model
    cd packages/ahp_fake_host && dart test -t integration

# Run pi-agent-host-protocol with pi's scripted faux model (no API key; see
# docs/testing.md). Pass `--port N`, `--token T`, `--no-token` or
# `--state-dir DIR`.
pi-faux-host *args:
    node scripts/pi-faux-host.ts {{args}}

# Drive the real app against pi with the faux model: the composer, streamed
# replies, a tool call, stop, queued messages, drafts, search, archive,
# filters, and reconnecting after a dropped connection or a host restart.
# Linux needs a display; `flutter-tester` runs it headless.
test-pi-app device="linux":
    cd app && flutter test integration_test/pi_host_flows_test.dart -d {{device}}

# Drive the web build in Chromium with Playwright (app/web_test) against
# the fake host and pi: shortcuts, OAuth through oauth_callback.html,
# reconnects and a host restart. Installs Playwright's Chromium on first
# use; pi's tests are skipped without a checkout.
test-web:
    cd app && flutter build web --dart-define=SHIREITOU_SEMANTICS=true
    cd app/web_test && npm ci && npx playwright install chromium && npx playwright test

# Run a real model turn through pi, using the providers in ~/.pi/agent.
# Costs tokens; sessions go to a temp directory.
test-model:
    cd packages/ahp_client && dart test -t model

# Run the desktop smoke test (window, secure storage, token header) on a
# native device (linux, macos or windows) against pi. Linux needs a display
# and an unlocked keyring; see scripts/test-desktop.
test-desktop device="linux":
    scripts/test-desktop {{device}}

# Run the mobile smoke test (secure storage, the phone layout against the
# fake host) on an Android emulator or iOS simulator, e.g.
# `just test-mobile emulator-5554`; see docs/mobile.md.
test-mobile device:
    scripts/test-mobile {{device}}

# Re-render the app icons from app/assets/icon/shireitou.svg (needs
# Playwright's Chromium in app/web_test); see docs/packaging.md.
icons:
    scripts/render-icon

# Create the Android release keystore and store it in the repository's
# Actions secrets (needs a JDK 17 and gh); see docs/packaging.md.
android-keystore keystore:
    scripts/android-keystore --upload {{keystore}}

# Regenerate the AHP wire types from the vendored JSON Schemas (see
# packages/ahp_wire_gen), then the freezed code in ahp_client. CI fails when
# the committed output differs.
codegen:
    cd packages/ahp_wire_gen && dart run ahp_wire_gen:generate schema/1.0.0 ../ahp_client/lib/src/generated
    dart format packages/ahp_client/lib/src/generated
    cd packages/ahp_client && dart run build_runner build

# Regenerate the colour themes (app/lib/src/theme/generated/themes.g.dart)
# from app/themes/manifest.yaml. See docs/themes.md.
themes:
    cd app && dart run tool/gen_themes.dart
    dart format app/lib/src/theme/generated

# Re-download the manifest's tinted-theming schemes, then regenerate.
fetch-themes:
    cd app && dart run tool/gen_themes.dart fetch
    dart format app/lib/src/theme/generated

# Download the JSON Schemas of an AHP release into packages/ahp_wire_gen.
# Generation stays pinned to 1.0.0 until the config and codegen recipe move.
fetch-schema version="1.0.0":
    mkdir -p packages/ahp_wire_gen/schema/{{version}}
    for f in actions commands errors notifications state; do \
      curl -fsSL -o packages/ahp_wire_gen/schema/{{version}}/$f.schema.json \
        https://raw.githubusercontent.com/microsoft/agent-host-protocol/v{{version}}/schema/$f.schema.json; \
    done

# Run the app. Pass a device, e.g. `just run macos`, and an optional host
# URL to prefill: `just run chrome ws://127.0.0.1:63877?tkn=...`.
run device="chrome" url="":
    cd app && flutter run -d {{device}} --dart-define=AHP_URL='{{url}}'
