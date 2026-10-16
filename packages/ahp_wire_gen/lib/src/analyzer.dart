/// Turns the AHP JSON Schemas into the [Decl] model.
library;

import 'dart:convert';

import 'package:collection/collection.dart';

import 'config.dart';
import 'model.dart';
import 'naming.dart';

/// A JSON Schema node.
typedef Schema = Map<String, Object?>;

/// Thrown for schema shapes the generator does not support.
class UnsupportedSchemaError extends Error {
  /// Creates an [UnsupportedSchemaError] at [path].
  UnsupportedSchemaError(this.path, this.message);

  /// Where in the schemas.
  final String path;

  /// What is unsupported.
  final String message;

  @override
  String toString() => 'Unsupported schema at $path: $message';
}

/// The analyzed schemas: declarations by name, in emit order.
final class WireModel {
  /// Creates a [WireModel].
  WireModel(this.decls);

  /// Declarations by Dart name, in emit order.
  final Map<String, Decl> decls;

  /// Whether [name] is a generated type.
  bool isType(String name) => decls.containsKey(name);
}

/// Merges the `$defs` of [schemas] (stem to decoded schema file, in
/// priority order). Returns each def with the stem it was first found in.
({Map<String, Schema> defs, Map<String, String> partOf}) mergeDefs(
  Map<String, Map<String, Object?>> schemas,
) {
  final defs = <String, Schema>{};
  final partOf = <String, String>{};
  for (final MapEntry(key: stem, value: file) in schemas.entries) {
    final fileDefs = (file[r'$defs']! as Map).cast<String, Object?>();
    for (final MapEntry(:key, :value) in fileDefs.entries) {
      if (defs.containsKey(key)) continue;
      // Deep copy, so patches never touch the caller's data.
      defs[key] = (jsonDecode(jsonEncode(value)) as Map)
          .cast<String, Object?>();
      partOf[key] = stem;
    }
  }
  return (defs: defs, partOf: partOf);
}

/// Analyzes [schemas] (stem to decoded schema file) with [config].
WireModel analyze(
  Map<String, Map<String, Object?>> schemas,
  GeneratorConfig config,
) {
  final (:defs, :partOf) = mergeDefs(schemas);
  for (final patch in config.patches) {
    patch.apply(defs);
  }
  return _Analyzer(config, defs, partOf).run();
}

String _canonical(Object? node) => jsonEncode(_stripDocs(node));

Object? _stripDocs(Object? node) => switch (node) {
  final Map<Object?, Object?> map => {
    for (final key in map.keys.map((k) => k.toString()).toList()..sort())
      if (key != 'description') key: _stripDocs(map[key]),
  },
  final List<Object?> list => [for (final e in list) _stripDocs(e)],
  _ => node,
};

Schema _schema(Object? node) => (node! as Map).cast<String, Object?>();

List<Schema> _oneOf(Schema schema) => [
  for (final m in schema['oneOf']! as List) _schema(m),
];

String? _refName(Schema schema) {
  final ref = schema[r'$ref'];
  return ref is String ? ref.substring(ref.lastIndexOf('/') + 1) : null;
}

bool _isConstOnly(Schema s) =>
    s.containsKey('const') &&
    s.keys.every((k) => k == 'const' || k == 'description');

final class _Analyzer {
  _Analyzer(this.config, this.defs, this.partOf);

  final GeneratorConfig config;
  final Map<String, Schema> defs;
  final Map<String, String> partOf;

  /// Declarations by their derived (pre-rename) name, in emit order.
  final decls = <String, Decl>{};

  /// Inline object classes by canonical schema, for de-duplication.
  final inlineByShape = <String, String>{};

  /// `$defs` that are not declarations but builtin Dart types.
  final builtins = <String, TypeRef>{};

  WireModel run() {
    for (final name in defs.keys) {
      if (config.skip.containsKey(name)) continue;
      final builtin = _builtin(name, defs[name]!);
      if (builtin != null) builtins[name] = builtin;
    }
    for (final MapEntry(key: name, value: schema) in defs.entries) {
      if (config.skip.containsKey(name) ||
          builtins.containsKey(name) ||
          decls.containsKey(name)) {
        continue;
      }
      _declare(name, schema, partOf[name]!);
    }
    for (final synthetic in config.syntheticUnions) {
      _synthesize(synthetic);
    }
    for (final union in decls.values.whereType<UnionDecl>()) {
      if (union.cases.isEmpty) _discriminate(union);
    }
    final done = <String>{};
    for (final union in decls.values.whereType<UnionDecl>()) {
      _commonFields(union, done);
    }
    return WireModel(_applyRenames());
  }

  /// The builtin type for a `$def` that needs no declaration.
  TypeRef? _builtin(String name, Schema schema) {
    if (name == config.statusType) return const StatusType();
    final alias = _refName(schema);
    if (alias != null) {
      // `type SessionOrigin = AutomationSessionOrigin`.
      return _builtin(alias, defs[alias]!) ?? NamedType(alias);
    }
    final type = schema['type'];
    if (type == 'string' && !schema.containsKey('enum')) {
      return const PrimType(Prim.string);
    }
    if (type == 'number' && schema.containsKey('enum')) {
      return const PrimType(Prim.int);
    }
    if (schema.containsKey('oneOf')) {
      final members = _oneOf(schema);
      final primitive = members.every(
        (m) =>
            m.keys.every((k) => k == 'type' || k == 'description') &&
            m['type'] != 'object' &&
            m['type'] != 'array',
      );
      if (primitive) return const PrimType(Prim.any);
    }
    return null;
  }

  void _add(Decl decl) {
    if (decls.containsKey(decl.name)) {
      throw UnsupportedSchemaError(decl.name, 'declared twice');
    }
    decls[decl.name] = decl;
  }

  void _declare(String name, Schema schema, String part) {
    if (schema.containsKey('oneOf')) {
      _declareOneOf(name, schema, part);
    } else if (schema['type'] == 'string' && schema['enum'] is List) {
      _add(
        EnumDecl(
          name: name,
          doc: schema['description'] as String?,
          part: part,
          values: [for (final v in schema['enum']! as List) v as String],
        ),
      );
    } else if (schema['type'] == 'object') {
      _declareClass(name, schema, part);
    } else {
      throw UnsupportedSchemaError(
        name,
        'unsupported def ${_canonical(schema)}',
      );
    }
  }

  void _declareOneOf(String name, Schema schema, String part) {
    final members = _oneOf(schema);
    final doc = schema['description'] as String?;
    if (members.every(_isConstOnly)) {
      _add(
        EnumDecl(
          name: name,
          doc: doc,
          part: part,
          values: [for (final m in members) m['const']! as String],
        ),
      );
      return;
    }
    final union = UnionDecl(name: name, doc: doc, part: part, members: []);
    _add(union);
    for (final member in members) {
      final ref = _refName(member);
      final String memberName;
      if (ref != null) {
        final builtin = builtins[ref];
        if (builtin != null) {
          throw UnsupportedSchemaError('$name/$ref', 'builtin union member');
        }
        memberName = ref;
      } else if (member['type'] == 'object' && member['properties'] is Map) {
        memberName = _inlineMemberName(name, member);
        _declareClass(memberName, member, part);
      } else if (member['type'] == 'string' && member.length <= 2) {
        memberName = _wrapperName(name, 'string');
        _add(
          WrapperDecl(
            name: memberName,
            doc: 'A plain string [$name].',
            part: part,
            prim: Prim.string,
          ),
        );
      } else {
        throw UnsupportedSchemaError(name, 'member ${_canonical(member)}');
      }
      union.members.add(memberName);
    }
    for (final member in union.members) {
      _memberDecl(member).unions.add(name);
    }
  }

  Decl _memberDecl(String name) {
    final decl = decls[name];
    if (decl != null) return decl;
    final schema = defs[name];
    if (schema == null) throw UnsupportedSchemaError(name, 'unknown \$ref');
    _declare(name, schema, partOf[name]!);
    return decls[name]!;
  }

  String _wrapperName(String union, String kind) {
    final name = config.wrapperNames['$union.$kind'];
    if (name == null) {
      throw UnsupportedSchemaError(
        union,
        'add a wrapperNames entry for "$union.$kind"',
      );
    }
    return name;
  }

  /// `ChatOrigin` + `{kind: const 'fork'}` → `ChatOriginFork`; an untagged
  /// object member takes its name from the config.
  String _inlineMemberName(String union, Schema member) {
    final properties = _schema(member['properties']);
    for (final property in properties.values) {
      final value = _schema(property)['const'];
      if (value is String) return '$union${pascalCase(value)}';
    }
    return _wrapperName(union, 'object');
  }

  void _declareClass(String name, Schema schema, String part) {
    if (decls.containsKey(name)) return;
    final properties = schema['properties'] is Map
        ? _schema(schema['properties'])
        : const <String, Object?>{};
    final required = {
      for (final r in (schema['required'] as List?) ?? const []) r as String,
    };
    final decl = ClassDecl(
      name: name,
      doc: schema['description'] as String?,
      part: part,
      fields: [],
      consts: [],
    );
    _add(decl);
    for (final MapEntry(key: jsonName, value: node) in properties.entries) {
      var property = _schema(node);
      if (property['enum'] case [final Object only]) {
        // A one-value enum is a constant.
        property = {...property, 'const': only}..remove('enum');
      }
      final dartName = fieldName(jsonName, renames: config.fieldRenames);
      final doc = property['description'] as String?;
      if (property.containsKey('const')) {
        decl.consts.add(
          ConstDecl(
            jsonName: jsonName,
            name: dartName,
            value: property['const']!,
            doc: doc,
          ),
        );
        continue;
      }
      final override = config.fieldTypes['$name.$jsonName'];
      List<Object>? constValues;
      final TypeRef type;
      if (override != null) {
        type = override;
      } else if (property['oneOf'] is List &&
          _oneOf(property).every(_isConstOnly) &&
          const {'kind', 'type', 'status', 'state'}.contains(jsonName)) {
        // A discriminator with several values in one member.
        constValues = [for (final m in _oneOf(property)) m['const']!];
        type = const PrimType(Prim.string);
      } else {
        type = _typeOf(property, name, jsonName, part);
      }
      decl.fields.add(
        FieldDecl(
          jsonName: jsonName,
          name: dartName,
          type: type,
          required: required.contains(jsonName),
          doc: doc,
          constValues: constValues,
        ),
      );
    }
    final names = [
      ...decl.fields.map((f) => f.name),
      ...decl.consts.map((c) => c.name),
    ];
    final duplicate = names.firstWhereOrNull(
      (n) => names.where((m) => m == n).length > 1,
    );
    if (duplicate != null) {
      throw UnsupportedSchemaError(name, 'two properties map to $duplicate');
    }
  }

  TypeRef _typeOf(Schema s, String owner, String property, String part) {
    final path = '$owner.$property';
    final ref = _refName(s);
    if (ref != null) {
      if (config.skip.containsKey(ref)) {
        throw UnsupportedSchemaError(path, 'references skipped $ref');
      }
      return builtins[ref] ?? NamedType(ref);
    }
    if (s['oneOf'] is List) {
      final members = _oneOf(s);
      if (members.every(_isConstOnly)) {
        final name = '$owner${pascalCase(property)}';
        _add(
          EnumDecl(
            name: name,
            doc: s['description'] as String?,
            part: part,
            values: [for (final m in members) m['const']! as String],
          ),
        );
        return NamedType(name);
      }
      throw UnsupportedSchemaError(
        path,
        'inline oneOf; add a fieldTypes entry',
      );
    }
    switch (s['type']) {
      case 'string':
        if (s['enum'] is List) {
          final name = '$owner${pascalCase(property)}';
          _add(
            EnumDecl(
              name: name,
              doc: s['description'] as String?,
              part: part,
              values: [for (final v in s['enum']! as List) v as String],
            ),
          );
          return NamedType(name);
        }
        return const PrimType(Prim.string);
      case 'number':
        return PrimType(
          config.numFields.contains(property) ? Prim.num : Prim.int,
        );
      case 'integer':
        return const PrimType(Prim.int);
      case 'boolean':
        return const PrimType(Prim.bool);
      case 'array':
        final items = s['items'];
        if (items == null) return const ListType(PrimType(Prim.any));
        return ListType(
          _typeOf(_schema(items), owner, '${property}Item', part),
        );
      case 'object':
        if (s['properties'] is Map) {
          final shape = _canonical(s);
          final existing = inlineByShape[shape];
          if (existing != null) return NamedType(existing);
          final name = '$owner${pascalCase(property)}';
          inlineByShape[shape] = name;
          _declareClass(name, s, part);
          return NamedType(name);
        }
        final additional = s['additionalProperties'];
        if (additional is Map && additional.isNotEmpty) {
          return MapType(_typeOf(_schema(additional), owner, property, part));
        }
        return const JsonMapType();
      case null:
        if (s.keys.every((k) => k == 'description')) {
          return const PrimType(Prim.any);
        }
    }
    throw UnsupportedSchemaError(path, 'unsupported type ${_canonical(s)}');
  }

  void _synthesize(SyntheticUnion synthetic) {
    final source = decls[synthetic.from];
    if (source is! UnionDecl) {
      throw UnsupportedSchemaError(
        synthetic.name,
        '${synthetic.from} is not a union',
      );
    }
    _discriminate(source);
    final members = [
      for (final c in source.cases)
        if (c.values.any((v) => v is String && v.startsWith(synthetic.prefix)))
          c.member,
    ];
    if (members.isEmpty) {
      throw UnsupportedSchemaError(synthetic.name, 'no members');
    }
    final union = UnionDecl(
      name: synthetic.name,
      doc: synthetic.doc,
      part: source.part,
      members: members,
    );
    _add(union);
    for (final member in members) {
      decls[member]!.unions.add(union.name);
    }
  }

  /// The values each member of [union] has for the property [jsonName],
  /// or null when a member has none.
  List<List<Object>>? _valuesFor(UnionDecl union, String jsonName) {
    final result = <List<Object>>[];
    for (final member in union.members) {
      final values = _memberValues(decls[member]!, jsonName);
      if (values == null) return null;
      result.add(values);
    }
    return result;
  }

  List<Object>? _memberValues(Decl decl, String jsonName) => switch (decl) {
    ClassDecl() => decl.discriminatorValues(jsonName),
    UnionDecl() => () {
      final nested = _valuesFor(decl, jsonName);
      return nested == null ? null : {...nested.flattened}.toList();
    }(),
    _ => null,
  };

  void _discriminate(UnionDecl union) {
    if (union.cases.isNotEmpty) return;
    final members = union.members.map((m) => decls[m]!).toList();
    if (members.any((m) => m is WrapperDecl)) {
      final objects = members.where((m) => m is! WrapperDecl).toList();
      if (objects.length > 1 || members.whereType<WrapperDecl>().length > 1) {
        throw UnsupportedSchemaError(union.name, 'ambiguous untagged union');
      }
      return;
    }
    final candidates = <String>{
      for (final m in members)
        if (m is ClassDecl) ...[
          ...m.consts.map((c) => c.jsonName),
          ...m.fields
              .where((f) => f.constValues != null)
              .map((f) => f.jsonName),
        ],
    };
    for (final candidate in candidates) {
      final values = _valuesFor(union, candidate);
      if (values == null) continue;
      final all = values.flattened.toList();
      if (all.length != all.toSet().length) continue;
      union.discriminator = candidate;
      union.discriminatorName = fieldName(
        candidate,
        renames: config.fieldRenames,
      );
      union.cases = [
        for (final (i, member) in union.members.indexed)
          UnionCase(values[i], member),
      ];
      return;
    }
    throw UnsupportedSchemaError(union.name, 'no discriminator');
  }

  /// Field sets by member, for common-field computation.
  Map<String, FieldDecl>? _fieldsOf(Decl decl, Set<String> done) =>
      switch (decl) {
        ClassDecl() => {for (final f in decl.fields) f.name: f},
        UnionDecl() => () {
          _commonFields(decl, done);
          return {for (final f in decl.commonFields) f.name: f};
        }(),
        _ => null,
      };

  void _commonFields(UnionDecl union, Set<String> done) {
    if (!done.add(union.name)) return;
    final sets = [for (final m in union.members) _fieldsOf(decls[m]!, done)];
    if (sets.isEmpty || sets.any((s) => s == null)) return;
    final common = <FieldDecl>[];
    for (final field in sets.first!.values) {
      if (field.jsonName == union.discriminator) continue;
      final others = [for (final s in sets) s![field.name]];
      if (others.any((o) => o == null)) continue;
      TypeRef? type = field.type;
      for (final other in others) {
        type = type == null ? null : _commonType(type, other!.type);
      }
      if (type == null) continue;
      common.add(
        FieldDecl(
          jsonName: field.jsonName,
          name: field.name,
          type: type,
          required: others.every((o) => o!.required),
          doc: field.doc,
        ),
      );
    }
    union.commonFields = common;
  }

  /// The type both [a] and [b] are assignable to: equal types, or a union
  /// and one of its (transitive) members.
  TypeRef? _commonType(TypeRef a, TypeRef b) {
    if (a == b) return a;
    if (a is NamedType && b is NamedType) {
      if (_isMemberOf(b.name, a.name)) return a;
      if (_isMemberOf(a.name, b.name)) return b;
    }
    return null;
  }

  bool _isMemberOf(String member, String union) {
    final decl = decls[member];
    if (decl == null) return false;
    return decl.unions.contains(union) ||
        decl.unions.any((u) => _isMemberOf(u, union));
  }

  Map<String, Decl> _applyRenames() {
    final unknown = config.typeRenames.keys.where((k) => !decls.containsKey(k));
    if (unknown.isNotEmpty) {
      throw UnsupportedSchemaError(
        'typeRenames',
        'no declarations named ${unknown.join(', ')}',
      );
    }
    String rename(String name) => config.typeRenames[name] ?? name;
    TypeRef retype(TypeRef type) => switch (type) {
      NamedType(:final name) => NamedType(rename(name)),
      ListType(:final item) => ListType(retype(item)),
      MapType(:final value) => MapType(retype(value)),
      _ => type,
    };
    final result = <String, Decl>{};
    for (final decl in decls.values) {
      decl.name = rename(decl.name);
      final renamedUnions = decl.unions.map(rename).toList();
      decl.unions
        ..clear()
        ..addAll(renamedUnions);
      switch (decl) {
        case ClassDecl(:final fields):
          for (final f in fields) {
            f.type = retype(f.type);
          }
        case UnionDecl():
          for (var i = 0; i < decl.members.length; i++) {
            decl.members[i] = rename(decl.members[i]);
          }
          decl.cases = [
            for (final c in decl.cases) UnionCase(c.values, rename(c.member)),
          ];
          for (final f in decl.commonFields) {
            f.type = retype(f.type);
          }
        case EnumDecl() || WrapperDecl():
          break;
      }
      if (result.containsKey(decl.name)) {
        throw UnsupportedSchemaError(decl.name, 'rename collides');
      }
      result[decl.name] = decl;
    }
    return result;
  }
}
