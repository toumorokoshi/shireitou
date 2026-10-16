import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/config_fields.dart';

const _thinking = SessionModelInfo(
  id: 'm',
  provider: 'pi',
  name: 'Model',
  configSchema: ConfigSchema(
    properties: {
      'thinkingLevel': ConfigPropertySchema(
        type: ConfigPropertySchemaType.string,
        title: 'Thinking',
        defaultValue: 'medium',
        enumValues: ['low', 'medium', 'high'],
        enumLabels: ['Low', 'Medium', 'High'],
      ),
      'tags': ConfigPropertySchema(
        type: ConfigPropertySchemaType.array,
        title: 'Tags',
      ),
    },
  ),
);

const _sessionSchema = SessionConfigSchema(
  properties: {
    'mode': SessionConfigPropertySchema(
      type: SessionConfigPropertySchemaType.string,
      title: 'Mode',
      defaultValue: 'interactive',
      enumValues: ['interactive', 'plan'],
      sessionMutable: true,
    ),
    'branch': SessionConfigPropertySchema(
      type: SessionConfigPropertySchemaType.string,
      title: 'Branch',
      enumValues: ['main'],
      enumDynamic: true,
    ),
    'sandbox': SessionConfigPropertySchema(
      type: SessionConfigPropertySchemaType.boolean,
      title: 'Sandbox',
      sessionMutable: true,
    ),
  },
  required: ['mode'],
);

void main() {
  test('a model configSchema becomes fields with labelled options', () {
    final fields = modelConfigFields(_thinking.configSchema);
    expect(fields.map((f) => f.kind), [
      ConfigFieldKind.choice,
      ConfigFieldKind.unsupported,
    ]);
    expect(fields.first.labelOf('high'), 'High');
    expect(fields.first.labelOf('other'), 'other');
    expect(modelConfigFields(null), isEmpty);
  });

  test('session settings: choices, suggestions, toggles, mutability', () {
    final fields = sessionConfigFields(_sessionSchema);
    expect(fields.map((f) => f.kind), [
      ConfigFieldKind.choice,
      ConfigFieldKind.suggested,
      ConfigFieldKind.toggle,
    ]);
    expect(fields.first.required, isTrue);
    expect(
      mutableSessionFields(
        const SessionConfigState(schema: _sessionSchema, values: {}),
      ).map((f) => f.id),
      ['mode'],
    );
  });

  test('configValues fills defaults, keeps choices, drops non-primitives', () {
    final fields = sessionConfigFields(_sessionSchema);
    expect(configValues(fields, const {}), {'mode': 'interactive'});
    expect(
      configValues(fields, const {
        'mode': 'plan',
        'branch': 'fix',
        'sandbox': true,
      }),
      {'mode': 'plan', 'branch': 'fix', 'sandbox': true},
    );
    // Clearing a value leaves it out instead of sending the default.
    expect(configValues(fields, const {'mode': null}), isEmpty);
    expect(
      configValues(modelConfigFields(_thinking.configSchema), const {
        'tags': ['a'],
      }),
      {'thinkingLevel': 'medium'},
    );
  });

  test('modelSelection sends the model with its options', () {
    expect(modelSelection(null, const {}), isNull);
    final selection = modelSelection(_thinking, const {
      'thinkingLevel': 'high',
    });
    expect(selection?.id, 'm');
    expect(selection?.config, {'thinkingLevel': 'high'});
    expect(
      modelSelection(
        const SessionModelInfo(id: 'x', provider: 'pi', name: 'X'),
        const {},
      )?.config,
      isNull,
    );
    expect(modelSelectionLabel(selection!, const [_thinking]), 'Model · High');
  });
}
