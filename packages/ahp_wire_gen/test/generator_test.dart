import 'dart:convert';
import 'dart:io';

import 'package:ahp_wire_gen/ahp_wire_gen.dart';
import 'package:ahp_wire_gen/src/naming.dart';
import 'package:test/test.dart';

const _config = GeneratorConfig(protocolVersion: 'test', sources: ['state']);

/// A one-file schema set with [defs].
Map<String, Map<String, Object?>> _schemas(Map<String, Object?> defs) => {
  'state': {r'$defs': defs},
};

WireModel _analyze(Map<String, Object?> defs, [GeneratorConfig? config]) =>
    analyze(_schemas(defs), config ?? _config);

Map<String, Object?> _ref(String name) => {r'$ref': '#/\$defs/$name'};

/// Two tagged members and an untagged inline one.
final _unionDefs = <String, Object?>{
  'Shape': {
    'oneOf': [
      _ref('Circle'),
      _ref('Square'),
      {
        'type': 'object',
        'properties': {
          'kind': {'const': 'dot'},
        },
        'required': ['kind'],
      },
    ],
  },
  'Circle': {
    'type': 'object',
    'description': 'A circle.',
    'properties': {
      'kind': {'const': 'circle'},
      'id': {'type': 'string'},
      'radius': {'type': 'number'},
    },
    'required': ['kind', 'id', 'radius'],
  },
  'Square': {
    'type': 'object',
    'properties': {
      'kind': {
        'oneOf': [
          {'const': 'square'},
          {'const': 'box'},
        ],
      },
      'id': {'type': 'string'},
    },
    'required': ['kind'],
  },
};

void main() {
  group('naming', () {
    test('camelCase and pascalCase', () {
      expect(camelCase('pending-confirmation'), 'pendingConfirmation');
      expect(camelCase('resource_name'), 'resourceName');
      expect(camelCase('_meta'), 'meta');
      expect(camelCase('MCP'), 'mcp');
      expect(camelCase('1x'), 'v1x');
      expect(pascalCase('sideChat'), 'SideChat');
      expect(pascalCase('chat/turnStarted'), 'ChatTurnStarted');
    });

    test('field names avoid reserved words', () {
      expect(
        fieldName('default', renames: {'default': 'defaultValue'}),
        'defaultValue',
      );
      expect(fieldName('in'), 'inValue');
      expect(fieldName('jwks_uri'), 'jwksUri');
    });

    test('doc comments turn TSDoc links into Dart references', () {
      final doc = docComment(
        'See {@link Foo} and {@link Foo.bar | `bar`}.\n\nMore.',
        fallback: 'x',
        indent: '  ',
        isType: (name) => name == 'Foo',
      );
      expect(doc, '  /// See [Foo] and `bar`.\n  ///\n  /// More.');
      expect(docComment(null, fallback: 'Fallback.'), '/// Fallback.');
    });
  });

  group('analyze', () {
    test('objects become classes with typed fields and constants', () {
      final model = _analyze(
        {
          'Thing': {
            'type': 'object',
            'properties': {
              'type': {'const': 'thing'},
              'count': {'type': 'number'},
              'min': {'type': 'number'},
              'tags': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              '_meta': {
                'type': 'object',
                'additionalProperties': <String, Object?>{},
              },
              'labels': {
                'type': 'object',
                'additionalProperties': {'type': 'boolean'},
              },
              'mode': {
                'type': 'string',
                'enum': ['a', 'b'],
              },
              'single': {
                'type': 'string',
                'enum': ['only'],
              },
              'error': {
                'type': 'object',
                'properties': {
                  'message': {'type': 'string'},
                },
                'required': ['message'],
              },
            },
            'required': ['type', 'count'],
          },
        },
        const GeneratorConfig(
          protocolVersion: 'test',
          sources: ['state'],
          numFields: {'min'},
        ),
      );
      final thing = model.decls['Thing']! as ClassDecl;
      final fields = {for (final f in thing.fields) f.name: f};
      expect(fields['count']!.type, const PrimType(Prim.int));
      expect(fields['count']!.required, isTrue);
      expect(fields['min']!.type, const PrimType(Prim.num));
      expect(fields['tags']!.type, const ListType(PrimType(Prim.string)));
      expect(fields['labels']!.type, const MapType(PrimType(Prim.bool)));
      expect(fields['meta']!.jsonName, '_meta');
      expect(fields['mode']!.type, const NamedType('ThingMode'));
      expect(fields['error']!.type, const NamedType('ThingError'));
      expect(thing.consts.map((c) => (c.name, c.value)), [
        ('type', 'thing'),
        ('single', 'only'),
      ]);
      expect(model.decls['ThingMode'], isA<EnumDecl>());
      expect(model.decls['ThingError'], isA<ClassDecl>());
    });

    test('a meta field and _meta both mapping to meta is rejected', () {
      expect(
        () => _analyze({
          'Thing': {
            'type': 'object',
            'properties': {
              'meta': {'type': 'string'},
              '_meta': {'type': 'string'},
            },
          },
        }),
        throwsA(isA<UnsupportedSchemaError>()),
      );
    });

    test('tagged unions find their discriminator and common fields', () {
      final model = _analyze(_unionDefs);
      final shape = model.decls['Shape']! as UnionDecl;
      expect(shape.discriminator, 'kind');
      expect(shape.cases.map((c) => (c.values.join(','), c.member)), [
        ('circle', 'Circle'),
        ('square,box', 'Square'),
        ('dot', 'ShapeDot'),
      ]);
      expect(shape.hasUnknown, isTrue);
      expect(shape.commonFields, isEmpty);
      expect(model.decls['Circle']!.unions, {'Shape'});
    });

    test('common fields widen to a union their types belong to', () {
      final model = _analyze({
        ..._unionDefs,
        'Holder': {
          'oneOf': [_ref('A'), _ref('B')],
        },
        'A': {
          'type': 'object',
          'properties': {
            'tag': {'const': 'a'},
            'shape': _ref('Shape'),
          },
          'required': ['tag', 'shape'],
        },
        'B': {
          'type': 'object',
          'properties': {
            'tag': {'const': 'b'},
            'shape': _ref('Circle'),
          },
          'required': ['tag'],
        },
      });
      final holder = model.decls['Holder']! as UnionDecl;
      expect(holder.commonFields.single.type, const NamedType('Shape'));
      expect(holder.commonFields.single.required, isFalse);
    });

    test('primitive unions become untagged unions or any', () {
      final model = _analyze(
        {
          'Text': {
            'oneOf': [
              {'type': 'string'},
              {
                'type': 'object',
                'properties': {
                  'markdown': {'type': 'string'},
                },
                'required': ['markdown'],
              },
            ],
          },
          'Primitive': {
            'oneOf': [
              {'type': 'string'},
              {'type': 'number'},
            ],
          },
          'Holder': {
            'type': 'object',
            'properties': {'value': _ref('Primitive')},
          },
        },
        const GeneratorConfig(
          protocolVersion: 'test',
          sources: ['state'],
          wrapperNames: {'Text.string': 'Plain', 'Text.object': 'Rich'},
        ),
      );
      final text = model.decls['Text']! as UnionDecl;
      expect(text.discriminator, isNull);
      expect(text.members, ['Plain', 'Rich']);
      expect(model.decls['Primitive'], isNull);
      final holder = model.decls['Holder']! as ClassDecl;
      expect(holder.fields.single.type, const PrimType(Prim.any));
    });

    test('const-only unions become enums', () {
      final model = _analyze({
        'Kind': {
          'oneOf': [
            {'const': 'a'},
            {'const': 'b-c'},
          ],
        },
      });
      expect((model.decls['Kind']! as EnumDecl).values, ['a', 'b-c']);
    });

    test('synthetic unions filter another union by prefix', () {
      final model = _analyze(
        {
          'Action': {
            'oneOf': [_ref('RootX'), _ref('ChatY')],
          },
          'RootX': {
            'type': 'object',
            'properties': {
              'type': {'const': 'root/x'},
            },
          },
          'ChatY': {
            'type': 'object',
            'properties': {
              'type': {'const': 'chat/y'},
            },
          },
        },
        const GeneratorConfig(
          protocolVersion: 'test',
          sources: ['state'],
          syntheticUnions: [
            SyntheticUnion('RootAction', 'Action', 'root/', 'R.'),
          ],
        ),
      );
      expect((model.decls['RootAction']! as UnionDecl).members, ['RootX']);
      expect(model.decls['RootX']!.unions, {'Action', 'RootAction'});
    });

    test('renames apply to declarations and references', () {
      final model = _analyze(
        _unionDefs,
        const GeneratorConfig(
          protocolVersion: 'test',
          sources: ['state'],
          typeRenames: {'Circle': 'Round'},
        ),
      );
      expect(model.decls.containsKey('Round'), isTrue);
      expect((model.decls['Shape']! as UnionDecl).members.first, 'Round');
    });

    test('unknown renames and untagged unions are errors', () {
      expect(
        () => _analyze(
          _unionDefs,
          const GeneratorConfig(
            protocolVersion: 'test',
            sources: ['state'],
            typeRenames: {'Nope': 'X'},
          ),
        ),
        throwsA(isA<UnsupportedSchemaError>()),
      );
      expect(
        () => _analyze({
          'U': {
            'oneOf': [_ref('P'), _ref('Q')],
          },
          'P': {'type': 'object', 'properties': <String, Object?>{}},
          'Q': {'type': 'object', 'properties': <String, Object?>{}},
        }),
        throwsA(isA<UnsupportedSchemaError>()),
      );
    });
  });

  group('emit', () {
    test('writes a library with one part per schema file', () {
      final files = generate(_schemas(_unionDefs), _config);
      expect(files.keys, ['ahp_types.dart', 'ahp_types_state.dart']);
      final library = files['ahp_types.dart']!;
      expect(library, contains("part 'ahp_types_state.dart';"));
      expect(library, contains("const wireProtocolVersion = 'test';"));
      final part = files['ahp_types_state.dart']!;
      expect(part, contains('sealed class Shape {'));
      expect(part, contains("'square' || 'box' => Square.fromJson(json),"));
      expect(part, contains('_ => ShapeUnknown.fromJson(json),'));
      expect(part, contains('final class Circle implements Shape {'));
      expect(part, contains("String get kind => 'circle';"));
      expect(part, contains('/// A circle.'));
      expect(part, contains("'radius': radius,"));
      expect(part, contains('Circle Function({String? id, int? radius})'));
    });
  });

  group('AHP 1.0.0', () {
    final schemas = {
      for (final stem in protocol100Config.sources)
        stem: (jsonDecode(
          File('schema/1.0.0/$stem.schema.json').readAsStringSync(),
        ) as Map).cast<String, Object?>(),
    };

    test('every def is generated or deliberately skipped', () {
      final model = analyze(schemas, protocol100Config);
      final defs = mergeDefs(schemas).defs.keys;
      final renamed = protocol100Config.typeRenames;
      final builtins = {
        'URI',
        'SessionStatus',
        'JsonPrimitive',
        'SessionOrigin',
        'JsonRpcErrorCode',
        'AhpErrorCode',
      };
      for (final def in defs) {
        if (protocol100Config.skip.containsKey(def) || builtins.contains(def)) {
          continue;
        }
        expect(model.isType(renamed[def] ?? def), isTrue, reason: def);
      }
    });

    test('the key unions are discriminated as the protocol says', () {
      final model = analyze(schemas, protocol100Config);
      String? discriminator(String name) =>
          (model.decls[name]! as UnionDecl).discriminator;
      expect(discriminator('StateAction'), 'type');
      expect(discriminator('ChatAction'), 'type');
      expect(discriminator('ChatToolCallConfirmedAction'), 'approved');
      expect(discriminator('ResponsePart'), 'kind');
      expect(discriminator('ToolCallState'), 'status');
      expect(discriminator('ReconnectResult'), 'type');
      expect(discriminator('StringOrMarkdown'), isNull);
      final toolCall = model.decls['ToolCallState']! as UnionDecl;
      expect(
        toolCall.commonFields.map((f) => f.name),
        containsAll(['toolCallId', 'toolName', 'displayName', 'contributor']),
      );
    });

    test('schema patches fail once upstream fixes the defect', () {
      final (:defs, partOf: _) = mergeDefs(schemas);
      for (final patch in protocol100Config.patches) {
        patch.apply(defs);
        expect(
          () => patch.apply(defs),
          throwsStateError,
          reason: patch.description,
        );
      }
    });
  });
}
