# Wire types

The Dart types for AHP messages and state (`SessionState`, `ChatAction`,
`ToolCallState`, ...) are generated from the protocol's JSON Schemas. Never
edit them by hand.

```
packages/ahp_wire_gen/schema/1.0.0/*.schema.json   vendored upstream schemas
        │  just codegen  (dart run ahp_wire_gen:generate, then dart format)
        ▼
packages/ahp_client/lib/src/generated/
    ahp_types.dart                 library: JsonMap, wireProtocolVersion, helpers
    ahp_types_state.dart           part: defs first found in state.schema.json
    ahp_types_actions.dart         part: actions.schema.json
    ahp_types_commands.dart        part: commands.schema.json
    ahp_types_notifications.dart   part: notifications.schema.json
    ahp_types_errors.dart          part: errors.schema.json
```

`packages/ahp_client/lib/src/wire.dart` re-exports the generated library and
adds the few hand-written helpers (`StringOrMarkdownText.text`,
`userMessage`, `defaultChatOf`, and `ToolCallStateFields` for fields only
some tool call states have).

## Commands

- `just codegen` regenerates the wire types (and the freezed code of
  `host_state.dart`). The output is committed.
- `just fetch-schema [version]` downloads the schemas of an AHP release tag
  (`v<version>` of `microsoft/agent-host-protocol`) into
  `packages/ahp_wire_gen/schema/<version>/`.
- CI runs `just fetch-schema` and `just codegen` and fails when anything in
  the working tree changes, so the vendored schemas match upstream and the
  committed output matches the generator.

## How schemas map to Dart

| Schema                                               | Dart                                                                                                                                                                                                                         |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type: object` with `properties`                     | `@immutable final class` with `const` constructor, `fromJson`, `toJson`, typed `copyWith`, deep `==`/`hashCode` and `toString`                                                                                               |
| property with `const` (or a one-value `enum`)        | getter returning the constant; written by `toJson`, not a constructor parameter                                                                                                                                              |
| `type: string` with `enum`, or a `oneOf` of `const`s | `enum` with `wireValue`, `fromJson` and `toJson`; values this version does not know decode to `$unknown`                                                                                                                     |
| `oneOf` of objects                                   | `sealed class` whose members `implement` it. Decoded by the discriminator (the property that is `const` in every member and different in each), falling back to `<Union>Unknown`, which keeps the JSON and the shared fields |
| `oneOf` with a `string` member                       | `sealed class` decoded by JSON type, e.g. `StringOrMarkdown` = `PlainString` or `MarkdownString`, `ToolInput` = `InlineToolInput` or `ContentRef`                                                                            |
| `oneOf` of primitives only (`JsonPrimitive`)         | `Object?`                                                                                                                                                                                                                    |
| `$def` that is a plain `string` (`URI`)              | `String`                                                                                                                                                                                                                     |
| `SessionStatus`                                      | the hand-written `SessionStatus` bitset extension type                                                                                                                                                                       |
| `number` enums (`AhpErrorCode`, `JsonRpcErrorCode`)  | `int` (the named codes stay in `protocol.dart`'s `AhpErrorCodes`)                                                                                                                                                            |
| `number`                                             | `int`, except fields that may be fractional (`min`, `max`, `value`, `defaultValue`, `safety`, `progress`, `total`): `num`                                                                                                    |
| `integer`, `boolean`, `array`                        | `int`, `bool`, `List<T>`                                                                                                                                                                                                     |
| object with only `additionalProperties`              | `Map<String, T>`, or `JsonMap` (`Map<String, Object?>`) when untyped                                                                                                                                                         |
| inline object property                               | class named `<Owner><Property>` (identical shapes share one class)                                                                                                                                                           |
| `_meta`, `snake_case`, reserved words                | `meta`, `camelCase`, `defaultValue` / `enumValues`                                                                                                                                                                           |
| `description`                                        | doc comment (`{@link X}` becomes `[X]`)                                                                                                                                                                                      |

Fields the schema marks required are required constructor parameters;
optional ones are nullable and left out of `toJson` when null. A required
array or map that a host leaves out decodes as empty. Fields every member
of a union shares (with the same type, or member types of one union) are
abstract getters on the sealed class, so `toolCall.toolCallId` works for
every `ToolCallState`. Each tagged union also has
`discriminatorValues`, the values it decodes to known members.

`copyWith` is a getter returning a typed function: passing `null` clears an
optional field and keeps a required one; leaving an argument out keeps it.

## Deliberate departures from the schemas

All of them are in `packages/ahp_wire_gen/lib/src/config.dart`:

- **Kept as raw JSON (`JsonMap`):** `Snapshot.state` (the client decodes it
  by channel kind; the schema's `oneOf` has no discriminator),
  `ActionEnvelope.action` (write-ahead keeps actions as JSON and reducers
  decode them with the channel's action union), and the two partial
  summaries `SessionChatUpdatedAction.changes` and
  `SessionSummaryChangedParams.changes` (hosts clear fields with an explicit
  `null`, which a typed class cannot tell from an omitted field).
- **Not generated:** `AhpErrorDetailsMap` (a mapped TypeScript type keyed by
  expressions) and `ProtocolNotification` (notifications are told apart by
  their JSON-RPC method, not a field; the `*Params` types are generated).
- **Added:** `RootAction`, `SessionAction`, `TerminalAction`,
  `ChangesetAction`, `AnnotationsAction`, `AutomationAction` and
  `AutomationRunAction`, built from `StateAction` by `type` prefix (the
  TypeScript package has them; the schemas only export `ChatAction`).
- **Renamed:** `Icon`, `TextPosition`, `TextRange` and `TextSelection` get
  an `Ahp` prefix (they clash with Flutter and `dart:ui`); some inline
  classes get readable names (`ToolCallError`, `ResourceWatchFilter`, ...).
- **Schema fixes:** the 1.0.0 `StateAction` lists an empty `$ref`, and
  `ChatToolCallApprovedAction.approved` / `ChatToolCallDeniedAction.approved`
  lost their `true` / `false` literal types, so `chat/toolCallConfirmed`
  has no discriminator. The generator patches both, and each patch throws
  once upstream fixes the defect, so it is dropped on the next upgrade.
- **`ChatToolCallDeniedAction.reason`** reuses `ToolCallCancellationReason`
  instead of an inline enum with a subset of its values.

## Upgrading the protocol version

1. `just fetch-schema <version>`.
2. Point the `codegen` recipe and `protocol100Config` (rename it) at the
   new version; review `config.dart` (a stale patch or rename fails the
   generator with a message saying so).
3. `just codegen`, fix the client and app where types changed, and update
   `targetProtocolVersion` and the version compatibility lists in
   `protocol_version.dart` (diff the old and new schemas' `StateAction`
   members; `protocol_version_test.dart` checks every listed action exists
   in the generated `StateAction`).
4. Re-run the pi integration tests.
