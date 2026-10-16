# Linting

- linting commands are found in the `justfile`.

## Linting

- linting is available via `just lint`, which usually routes to the linter of the particular language of the repository, such as `npm` or `cargo`.
- For Dart, `just lint` runs `dart format --set-exit-if-changed`, then
  `dart analyze --fatal-infos` (`packages/ahp_client`) and
  `flutter analyze --fatal-infos` (`app`).
- Analyzer settings live in each package's `analysis_options.yaml`: the
  `lints` / `flutter_lints` recommended sets, plus `strict-casts`,
  `strict-inference` and `strict-raw-types`, and extra rules such as
  `avoid_dynamic_calls` and `unawaited_futures`. `ahp_client` also requires
  `public_member_api_docs`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are excluded from analysis.
  CI checks they are up to date by running `just codegen` and `git diff`.

## Formatting

If there is no best practice formatter for the language of choice, then
`prettier` is used. It is available via `just format`.

- Dart uses `dart format`. Markdown uses prettier (`.prettierignore` skips
  build output and the generated platform folders).

## Fix

Auto-fixing is available via `just fix`, which runs `dart fix --apply` in each
package and then `just format`.

## Testing

- `just test` runs `dart test -x integration` in `packages/ahp_client` and
  `flutter test` in `app`.
- `just test-integration` runs the tests tagged `integration`, which launch
  pi-agent-host-protocol.
