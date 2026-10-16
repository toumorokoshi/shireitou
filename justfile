# Linting, formatting, tests and running. See specs/linting.md.

prettier := "npx --yes prettier@3.3.3"

# Check formatting and linting (markdown and Dart).
lint:
    {{prettier}} --check "**/*.md"
    dart format --output=none --set-exit-if-changed .
    cd packages/ahp_client && dart analyze --fatal-infos
    cd app && flutter analyze --fatal-infos

# Format markdown and Dart files.
format:
    {{prettier}} --write "**/*.md"
    dart format .

# Apply lint fixes, then format.
fix:
    cd packages/ahp_client && dart fix --apply
    cd app && dart fix --apply
    just format

# Run unit and widget tests (integration tests excluded).
test:
    cd packages/ahp_client && dart test -x integration
    cd app && flutter test

# Run the integration test against pi-agent-host-protocol.
# Set PI_AHP_HOST_DIR to the checkout (default: a sibling of this repo).
test-integration:
    cd packages/ahp_client && dart test -t integration

# Regenerate freezed / json_serializable code in ahp_client.
codegen:
    cd packages/ahp_client && dart run build_runner build

# Run the app. Pass a device, e.g. `just run macos`, and an optional host
# URL to prefill: `just run chrome ws://127.0.0.1:63877?tkn=...`.
run device="chrome" url="":
    cd app && flutter run -d {{device}} --dart-define=AHP_URL='{{url}}'
