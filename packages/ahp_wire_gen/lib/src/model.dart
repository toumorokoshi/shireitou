/// The intermediate model between the JSON Schemas and the Dart source:
/// type references and declarations.
library;

import 'package:collection/collection.dart';

/// A primitive JSON value type.
enum Prim {
  /// A JSON string.
  string,

  /// A JSON number known to hold whole numbers.
  int,

  /// A JSON number that may be fractional.
  num,

  /// A JSON boolean.
  bool,

  /// Any JSON value (`Object?` in Dart).
  any,
}

/// The type of a field, list item or map value.
sealed class TypeRef {
  const TypeRef();
}

/// A primitive type.
final class PrimType extends TypeRef {
  /// Creates a [PrimType].
  const PrimType(this.prim);

  /// The primitive.
  final Prim prim;

  @override
  bool operator ==(Object other) => other is PrimType && other.prim == prim;

  @override
  int get hashCode => prim.hashCode;

  @override
  String toString() => prim.name;
}

/// A JSON object kept as a raw map.
final class JsonMapType extends TypeRef {
  /// Creates a [JsonMapType].
  const JsonMapType();

  @override
  bool operator ==(Object other) => other is JsonMapType;

  @override
  int get hashCode => 1;

  @override
  String toString() => 'JsonMap';
}

/// The `SessionStatus` bitset, mapped to the client's extension type.
final class StatusType extends TypeRef {
  /// Creates a [StatusType].
  const StatusType();

  @override
  bool operator ==(Object other) => other is StatusType;

  @override
  int get hashCode => 2;

  @override
  String toString() => 'SessionStatus';
}

/// A JSON array.
final class ListType extends TypeRef {
  /// Creates a [ListType].
  const ListType(this.item);

  /// The item type.
  final TypeRef item;

  @override
  bool operator ==(Object other) => other is ListType && other.item == item;

  @override
  int get hashCode => Object.hash(3, item);

  @override
  String toString() => 'List<$item>';
}

/// A JSON object used as a string-keyed map.
final class MapType extends TypeRef {
  /// Creates a [MapType].
  const MapType(this.value);

  /// The value type.
  final TypeRef value;

  @override
  bool operator ==(Object other) => other is MapType && other.value == value;

  @override
  int get hashCode => Object.hash(4, value);

  @override
  String toString() => 'Map<String, $value>';
}

/// A generated declaration, by name.
final class NamedType extends TypeRef {
  /// Creates a [NamedType].
  const NamedType(this.name);

  /// The declaration's Dart name.
  final String name;

  @override
  bool operator ==(Object other) => other is NamedType && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

/// A generated declaration.
sealed class Decl {
  Decl({required this.name, required this.doc, required this.part});

  /// Dart name.
  String name;

  /// Schema description.
  final String? doc;

  /// The output part (schema file stem) this declaration goes in.
  final String part;

  /// Unions this declaration is a direct member of.
  final Set<String> unions = {};
}

/// A field of a [ClassDecl].
final class FieldDecl {
  /// Creates a [FieldDecl].
  FieldDecl({
    required this.jsonName,
    required this.name,
    required this.type,
    required this.required,
    required this.doc,
    this.constValues,
  });

  /// The JSON property name.
  final String jsonName;

  /// The Dart field name.
  final String name;

  /// The field type.
  TypeRef type;

  /// Whether the schema requires the property.
  final bool required;

  /// Schema description.
  final String? doc;

  /// The allowed values when the schema lists them as `const`s (a
  /// discriminator with several values).
  final List<Object>? constValues;
}

/// A property with a single `const` value, generated as a getter.
final class ConstDecl {
  /// Creates a [ConstDecl].
  const ConstDecl({
    required this.jsonName,
    required this.name,
    required this.value,
    required this.doc,
  });

  /// The JSON property name.
  final String jsonName;

  /// The Dart getter name.
  final String name;

  /// The constant (a string, number or boolean).
  final Object value;

  /// Schema description.
  final String? doc;
}

/// A JSON object type.
final class ClassDecl extends Decl {
  /// Creates a [ClassDecl].
  ClassDecl({
    required super.name,
    required super.doc,
    required super.part,
    required this.fields,
    required this.consts,
  });

  /// Fields, in schema order.
  final List<FieldDecl> fields;

  /// `const` properties, in schema order.
  final List<ConstDecl> consts;

  /// The const or multi-valued discriminator values of [jsonName], or null.
  List<Object>? discriminatorValues(String jsonName) {
    final constant = consts.firstWhereOrNull((c) => c.jsonName == jsonName);
    if (constant != null) return [constant.value];
    return fields.firstWhereOrNull((f) => f.jsonName == jsonName)?.constValues;
  }
}

/// A string enumeration.
final class EnumDecl extends Decl {
  /// Creates an [EnumDecl].
  EnumDecl({
    required super.name,
    required super.doc,
    required super.part,
    required this.values,
  });

  /// The JSON values, in schema order.
  final List<String> values;
}

/// A wrapper class for a primitive member of a [UnionDecl] (e.g. the
/// `string` side of `StringOrMarkdown`).
final class WrapperDecl extends Decl {
  /// Creates a [WrapperDecl].
  WrapperDecl({
    required super.name,
    required super.doc,
    required super.part,
    required this.prim,
  });

  /// The wrapped primitive.
  final Prim prim;
}

/// One case of a discriminated union: the discriminator values that select
/// [member].
final class UnionCase {
  /// Creates a [UnionCase].
  const UnionCase(this.values, this.member);

  /// Discriminator values.
  final List<Object> values;

  /// The member declaration's name.
  final String member;
}

/// A `oneOf`: a sealed class whose members implement it.
final class UnionDecl extends Decl {
  /// Creates a [UnionDecl].
  UnionDecl({
    required super.name,
    required super.doc,
    required super.part,
    required this.members,
  });

  /// Member declarations, in schema order.
  final List<String> members;

  /// The discriminating property's JSON name; null for a union decoded by
  /// JSON value type (one with primitive members).
  String? discriminator;

  /// The discriminator's Dart name.
  String? discriminatorName;

  /// Cases in member order (discriminated unions only).
  List<UnionCase> cases = const [];

  /// Fields every member has, with the same type.
  List<FieldDecl> commonFields = const [];

  /// Whether unknown discriminator values decode to a fallback member.
  bool get hasUnknown =>
      discriminator != null &&
      !cases.every((c) => c.values.every((v) => v is bool));

  /// The fallback member's name.
  String get unknownName => '${name}Unknown';

  /// The Dart type of the discriminator values.
  String get discriminatorType =>
      cases.isNotEmpty && cases.first.values.first is bool ? 'bool' : 'String';
}
