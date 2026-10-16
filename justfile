# Linting, formatting, tests and running. See specs/linting.md.

prettier := "npx --yes prettier@3.3.3"

# Check formatting and linting (markdown and Dart).
lint:
    {{prettier}} --check "**/*.md"
    dart format --output=none --set-exit-if-changed .
    cd packages/ahp_client && dart analyze --fatal-infos
    cd packages/ahp_wire_gen && dart analyze --fatal-infos
    cd packages/ahp_fake_host && dart analyze --fatal-infos
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
    cd app && dart fix --apply
    just format

# Run unit and widget tests (pi integration tests excluded), and the
# client flows against the scripted fake host.
test:
    cd packages/ahp_wire_gen && dart test
    cd packages/ahp_client && dart test -x integration
    cd packages/ahp_fake_host && dart test
    cd app && flutter test

# Run the scripted fake AHP host (asks for approvals, input and sign-in;
# see packages/ahp_fake_host). Pass `--port N`, `--token T` or `--no-token`.
fake-host *args:
    cd packages/ahp_fake_host && dart run ahp_fake_host {{args}}

# Drive the real app against the fake host: approvals, input requests,
# session-level requests and MCP sign-in. Linux needs a display.
test-fake-host-app device="linux":
    cd app && flutter test integration_test/fake_host_flows_test.dart -d {{device}}

# Run the integration tests against pi-agent-host-protocol (no model turns).
# Set PI_AHP_HOST_DIR to the checkout (default: a sibling of this repo).
test-integration:
    cd packages/ahp_client && dart test -t integration -x model

# Run a real model turn through pi, using the providers in ~/.pi/agent.
# Costs tokens; sessions go to a temp directory.
test-model:
    cd packages/ahp_client && dart test -t model

# Run the desktop smoke test (window, secure storage, token header) on a
# native device against pi. Linux needs a display and an unlocked keyring;
# see scripts/test-desktop.
test-desktop device="linux":
    scripts/test-desktop {{device}}

# Regenerate the AHP wire types from the vendored JSON Schemas (see
# packages/ahp_wire_gen), then the freezed code in ahp_client. CI fails when
# the committed output differs.
codegen:
    cd packages/ahp_wire_gen && dart run ahp_wire_gen:generate schema/1.0.0 ../ahp_client/lib/src/generated
    dart format packages/ahp_client/lib/src/generated
    cd packages/ahp_client && dart run build_runner build

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
