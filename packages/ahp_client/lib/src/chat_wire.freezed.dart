// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_wire.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModelSelection {

/// Model ID from `SessionModelInfo.id`.
 String get id;/// Per-model config values, e.g. `{thinkingLevel: 'low'}`.
 JsonMap? get config;
/// Create a copy of ModelSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModelSelectionCopyWith<ModelSelection> get copyWith => _$ModelSelectionCopyWithImpl<ModelSelection>(this as ModelSelection, _$identity);

  /// Serializes this ModelSelection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModelSelection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModelSelection&&(identical(other.id, _this.id) || other.id == _this.id)&&const DeepCollectionEquality().equals(other.config, _this.config));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModelSelection;
  return Object.hash(runtimeType,_this.id,const DeepCollectionEquality().hash(_this.config));
}

@override
String toString() {
  final _this = this as ModelSelection;
  return 'ModelSelection(id: ${_this.id}, config: ${_this.config})';
}


}

/// @nodoc
abstract mixin class $ModelSelectionCopyWith<$Res>  {
  factory $ModelSelectionCopyWith(ModelSelection value, $Res Function(ModelSelection) _then) = _$ModelSelectionCopyWithImpl;
@useResult
$Res call({
 String id, JsonMap? config
});




}
/// @nodoc
class _$ModelSelectionCopyWithImpl<$Res>
    implements $ModelSelectionCopyWith<$Res> {
  _$ModelSelectionCopyWithImpl(this._self, this._then);

  final ModelSelection _self;
  final $Res Function(ModelSelection) _then;

/// Create a copy of ModelSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? config = freezed,}) {
  return _then(ModelSelection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModelSelection].
extension ModelSelectionPatterns on ModelSelection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModelSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModelSelection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModelSelection value)  $default,){
final _that = this;
switch (_that) {
case _ModelSelection():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModelSelection value)?  $default,){
final _that = this;
switch (_that) {
case _ModelSelection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  JsonMap? config)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModelSelection() when $default != null:
return $default(_that.id,_that.config);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  JsonMap? config)  $default,) {final _that = this;
switch (_that) {
case _ModelSelection():
return $default(_that.id,_that.config);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  JsonMap? config)?  $default,) {final _that = this;
switch (_that) {
case _ModelSelection() when $default != null:
return $default(_that.id,_that.config);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModelSelection implements ModelSelection {
  const _ModelSelection({required this.id,  JsonMap? config}): _config = config;
  factory _ModelSelection.fromJson(Map<String, dynamic> json) => _$ModelSelectionFromJson(json);

/// Model ID from `SessionModelInfo.id`.
@override final  String id;
/// Per-model config values, e.g. `{thinkingLevel: 'low'}`.
 final  JsonMap? _config;
/// Per-model config values, e.g. `{thinkingLevel: 'low'}`.
@override JsonMap? get config {
  final value = _config;
  if (value == null) return null;
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ModelSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModelSelectionCopyWith<_ModelSelection> get copyWith => __$ModelSelectionCopyWithImpl<_ModelSelection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModelSelectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModelSelection&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.config, _config));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_config));
}

@override
String toString() {
    return 'ModelSelection(id: $id, config: $config)';
}


}

/// @nodoc
abstract mixin class _$ModelSelectionCopyWith<$Res> implements $ModelSelectionCopyWith<$Res> {
  factory _$ModelSelectionCopyWith(_ModelSelection value, $Res Function(_ModelSelection) _then) = __$ModelSelectionCopyWithImpl;
@override @useResult
$Res call({
 String id, JsonMap? config
});




}
/// @nodoc
class __$ModelSelectionCopyWithImpl<$Res>
    implements _$ModelSelectionCopyWith<$Res> {
  __$ModelSelectionCopyWithImpl(this._self, this._then);

  final _ModelSelection _self;
  final $Res Function(_ModelSelection) _then;

/// Create a copy of ModelSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? config = freezed,}) {
  return _then(_ModelSelection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,config: freezed == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}


/// @nodoc
mixin _$MessageOrigin {

/// `user`, `agent`, `tool`, `automation` or `systemNotification`.
 String get kind;
/// Create a copy of MessageOrigin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageOriginCopyWith<MessageOrigin> get copyWith => _$MessageOriginCopyWithImpl<MessageOrigin>(this as MessageOrigin, _$identity);

  /// Serializes this MessageOrigin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MessageOrigin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageOrigin&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MessageOrigin;
  return Object.hash(runtimeType,_this.kind);
}

@override
String toString() {
  final _this = this as MessageOrigin;
  return 'MessageOrigin(kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $MessageOriginCopyWith<$Res>  {
  factory $MessageOriginCopyWith(MessageOrigin value, $Res Function(MessageOrigin) _then) = _$MessageOriginCopyWithImpl;
@useResult
$Res call({
 String kind
});




}
/// @nodoc
class _$MessageOriginCopyWithImpl<$Res>
    implements $MessageOriginCopyWith<$Res> {
  _$MessageOriginCopyWithImpl(this._self, this._then);

  final MessageOrigin _self;
  final $Res Function(MessageOrigin) _then;

/// Create a copy of MessageOrigin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,}) {
  return _then(MessageOrigin(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageOrigin].
extension MessageOriginPatterns on MessageOrigin {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageOrigin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageOrigin() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageOrigin value)  $default,){
final _that = this;
switch (_that) {
case _MessageOrigin():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageOrigin value)?  $default,){
final _that = this;
switch (_that) {
case _MessageOrigin() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageOrigin() when $default != null:
return $default(_that.kind);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind)  $default,) {final _that = this;
switch (_that) {
case _MessageOrigin():
return $default(_that.kind);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind)?  $default,) {final _that = this;
switch (_that) {
case _MessageOrigin() when $default != null:
return $default(_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageOrigin implements MessageOrigin {
  const _MessageOrigin({required this.kind});
  factory _MessageOrigin.fromJson(Map<String, dynamic> json) => _$MessageOriginFromJson(json);

/// `user`, `agent`, `tool`, `automation` or `systemNotification`.
@override final  String kind;

/// Create a copy of MessageOrigin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageOriginCopyWith<_MessageOrigin> get copyWith => __$MessageOriginCopyWithImpl<_MessageOrigin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageOriginToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageOrigin&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind);
}

@override
String toString() {
    return 'MessageOrigin(kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$MessageOriginCopyWith<$Res> implements $MessageOriginCopyWith<$Res> {
  factory _$MessageOriginCopyWith(_MessageOrigin value, $Res Function(_MessageOrigin) _then) = __$MessageOriginCopyWithImpl;
@override @useResult
$Res call({
 String kind
});




}
/// @nodoc
class __$MessageOriginCopyWithImpl<$Res>
    implements _$MessageOriginCopyWith<$Res> {
  __$MessageOriginCopyWithImpl(this._self, this._then);

  final _MessageOrigin _self;
  final $Res Function(_MessageOrigin) _then;

/// Create a copy of MessageOrigin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(_MessageOrigin(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Message {

/// Message text.
 String get text;/// Who wrote it.
 MessageOrigin get origin;/// Attachments (passed through).
 List<JsonMap>? get attachments;/// Model to run the turn with; absent means the host's default.
 ModelSelection? get model;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Message;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&const DeepCollectionEquality().equals(other.attachments, _this.attachments)&&(identical(other.model, _this.model) || other.model == _this.model)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Message;
  return Object.hash(runtimeType,_this.text,_this.origin,const DeepCollectionEquality().hash(_this.attachments),_this.model,const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as Message;
  return 'Message(text: ${_this.text}, origin: ${_this.origin}, attachments: ${_this.attachments}, model: ${_this.model}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String text, MessageOrigin origin, List<JsonMap>? attachments, ModelSelection? model,@JsonKey(name: '_meta') JsonMap? meta
});


$MessageOriginCopyWith<$Res> get origin;$ModelSelectionCopyWith<$Res>? get model;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? origin = null,Object? attachments = freezed,Object? model = freezed,Object? meta = freezed,}) {
  return _then(Message(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as MessageOrigin,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ModelSelection?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageOriginCopyWith<$Res> get origin {
  
  return $MessageOriginCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelSelectionCopyWith<$Res>? get model {
    if (_self.model == null) {
    return null;
  }

  return $ModelSelectionCopyWith<$Res>(_self.model!, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// Adds pattern-matching-related methods to [Message].
extension MessagePatterns on Message {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Message value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Message value)  $default,){
final _that = this;
switch (_that) {
case _Message():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Message value)?  $default,){
final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  MessageOrigin origin,  List<JsonMap>? attachments,  ModelSelection? model, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.text,_that.origin,_that.attachments,_that.model,_that.meta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  MessageOrigin origin,  List<JsonMap>? attachments,  ModelSelection? model, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _Message():
return $default(_that.text,_that.origin,_that.attachments,_that.model,_that.meta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  MessageOrigin origin,  List<JsonMap>? attachments,  ModelSelection? model, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _Message() when $default != null:
return $default(_that.text,_that.origin,_that.attachments,_that.model,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Message implements Message {
  const _Message({required this.text, required this.origin,  List<JsonMap>? attachments, this.model, @JsonKey(name: '_meta')  JsonMap? meta}): _attachments = attachments,_meta = meta;
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

/// Message text.
@override final  String text;
/// Who wrote it.
@override final  MessageOrigin origin;
/// Attachments (passed through).
 final  List<JsonMap>? _attachments;
/// Attachments (passed through).
@override List<JsonMap>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Model to run the turn with; absent means the host's default.
@override final  ModelSelection? model;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@override@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.text, text) || other.text == text)&&(identical(other.origin, origin) || other.origin == origin)&&const DeepCollectionEquality().equals(other.attachments, _attachments)&&(identical(other.model, model) || other.model == model)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,origin,const DeepCollectionEquality().hash(_attachments),model,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'Message(text: $text, origin: $origin, attachments: $attachments, model: $model, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String text, MessageOrigin origin, List<JsonMap>? attachments, ModelSelection? model,@JsonKey(name: '_meta') JsonMap? meta
});


@override $MessageOriginCopyWith<$Res> get origin;@override $ModelSelectionCopyWith<$Res>? get model;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? origin = null,Object? attachments = freezed,Object? model = freezed,Object? meta = freezed,}) {
  return _then(_Message(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,origin: null == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as MessageOrigin,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as ModelSelection?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageOriginCopyWith<$Res> get origin {
  
  return $MessageOriginCopyWith<$Res>(_self.origin, (value) {
    return _then(_self.copyWith(origin: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModelSelectionCopyWith<$Res>? get model {
    if (_self.model == null) {
    return null;
  }

  return $ModelSelectionCopyWith<$Res>(_self.model!, (value) {
    return _then(_self.copyWith(model: value));
  });
}
}


/// @nodoc
mixin _$UsageInfo {

/// Input tokens.
 int? get inputTokens;/// Output tokens.
 int? get outputTokens;/// Model that served the turn.
 String? get model;/// Input tokens read from the prompt cache.
 int? get cacheReadTokens;
/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<UsageInfo> get copyWith => _$UsageInfoCopyWithImpl<UsageInfo>(this as UsageInfo, _$identity);

  /// Serializes this UsageInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UsageInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsageInfo&&(identical(other.inputTokens, _this.inputTokens) || other.inputTokens == _this.inputTokens)&&(identical(other.outputTokens, _this.outputTokens) || other.outputTokens == _this.outputTokens)&&(identical(other.model, _this.model) || other.model == _this.model)&&(identical(other.cacheReadTokens, _this.cacheReadTokens) || other.cacheReadTokens == _this.cacheReadTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UsageInfo;
  return Object.hash(runtimeType,_this.inputTokens,_this.outputTokens,_this.model,_this.cacheReadTokens);
}

@override
String toString() {
  final _this = this as UsageInfo;
  return 'UsageInfo(inputTokens: ${_this.inputTokens}, outputTokens: ${_this.outputTokens}, model: ${_this.model}, cacheReadTokens: ${_this.cacheReadTokens})';
}


}

/// @nodoc
abstract mixin class $UsageInfoCopyWith<$Res>  {
  factory $UsageInfoCopyWith(UsageInfo value, $Res Function(UsageInfo) _then) = _$UsageInfoCopyWithImpl;
@useResult
$Res call({
 int? inputTokens, int? outputTokens, String? model, int? cacheReadTokens
});




}
/// @nodoc
class _$UsageInfoCopyWithImpl<$Res>
    implements $UsageInfoCopyWith<$Res> {
  _$UsageInfoCopyWithImpl(this._self, this._then);

  final UsageInfo _self;
  final $Res Function(UsageInfo) _then;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputTokens = freezed,Object? outputTokens = freezed,Object? model = freezed,Object? cacheReadTokens = freezed,}) {
  return _then(UsageInfo(
inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,cacheReadTokens: freezed == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UsageInfo].
extension UsageInfoPatterns on UsageInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UsageInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UsageInfo value)  $default,){
final _that = this;
switch (_that) {
case _UsageInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UsageInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? inputTokens,  int? outputTokens,  String? model,  int? cacheReadTokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.model,_that.cacheReadTokens);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? inputTokens,  int? outputTokens,  String? model,  int? cacheReadTokens)  $default,) {final _that = this;
switch (_that) {
case _UsageInfo():
return $default(_that.inputTokens,_that.outputTokens,_that.model,_that.cacheReadTokens);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? inputTokens,  int? outputTokens,  String? model,  int? cacheReadTokens)?  $default,) {final _that = this;
switch (_that) {
case _UsageInfo() when $default != null:
return $default(_that.inputTokens,_that.outputTokens,_that.model,_that.cacheReadTokens);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UsageInfo implements UsageInfo {
  const _UsageInfo({this.inputTokens, this.outputTokens, this.model, this.cacheReadTokens});
  factory _UsageInfo.fromJson(Map<String, dynamic> json) => _$UsageInfoFromJson(json);

/// Input tokens.
@override final  int? inputTokens;
/// Output tokens.
@override final  int? outputTokens;
/// Model that served the turn.
@override final  String? model;
/// Input tokens read from the prompt cache.
@override final  int? cacheReadTokens;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageInfoCopyWith<_UsageInfo> get copyWith => __$UsageInfoCopyWithImpl<_UsageInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UsageInfo&&(identical(other.inputTokens, inputTokens) || other.inputTokens == inputTokens)&&(identical(other.outputTokens, outputTokens) || other.outputTokens == outputTokens)&&(identical(other.model, model) || other.model == model)&&(identical(other.cacheReadTokens, cacheReadTokens) || other.cacheReadTokens == cacheReadTokens));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,inputTokens,outputTokens,model,cacheReadTokens);
}

@override
String toString() {
    return 'UsageInfo(inputTokens: $inputTokens, outputTokens: $outputTokens, model: $model, cacheReadTokens: $cacheReadTokens)';
}


}

/// @nodoc
abstract mixin class _$UsageInfoCopyWith<$Res> implements $UsageInfoCopyWith<$Res> {
  factory _$UsageInfoCopyWith(_UsageInfo value, $Res Function(_UsageInfo) _then) = __$UsageInfoCopyWithImpl;
@override @useResult
$Res call({
 int? inputTokens, int? outputTokens, String? model, int? cacheReadTokens
});




}
/// @nodoc
class __$UsageInfoCopyWithImpl<$Res>
    implements _$UsageInfoCopyWith<$Res> {
  __$UsageInfoCopyWithImpl(this._self, this._then);

  final _UsageInfo _self;
  final $Res Function(_UsageInfo) _then;

/// Create a copy of UsageInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputTokens = freezed,Object? outputTokens = freezed,Object? model = freezed,Object? cacheReadTokens = freezed,}) {
  return _then(_UsageInfo(
inputTokens: freezed == inputTokens ? _self.inputTokens : inputTokens // ignore: cast_nullable_to_non_nullable
as int?,outputTokens: freezed == outputTokens ? _self.outputTokens : outputTokens // ignore: cast_nullable_to_non_nullable
as int?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,cacheReadTokens: freezed == cacheReadTokens ? _self.cacheReadTokens : cacheReadTokens // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ErrorInfo {

/// Error category, e.g. `model`.
 String get errorType;/// Human-readable message.
 String get message;/// Stack trace, when the host sends one.
 String? get stack;
/// Create a copy of ErrorInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorInfoCopyWith<ErrorInfo> get copyWith => _$ErrorInfoCopyWithImpl<ErrorInfo>(this as ErrorInfo, _$identity);

  /// Serializes this ErrorInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ErrorInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorInfo&&(identical(other.errorType, _this.errorType) || other.errorType == _this.errorType)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.stack, _this.stack) || other.stack == _this.stack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ErrorInfo;
  return Object.hash(runtimeType,_this.errorType,_this.message,_this.stack);
}

@override
String toString() {
  final _this = this as ErrorInfo;
  return 'ErrorInfo(errorType: ${_this.errorType}, message: ${_this.message}, stack: ${_this.stack})';
}


}

/// @nodoc
abstract mixin class $ErrorInfoCopyWith<$Res>  {
  factory $ErrorInfoCopyWith(ErrorInfo value, $Res Function(ErrorInfo) _then) = _$ErrorInfoCopyWithImpl;
@useResult
$Res call({
 String errorType, String message, String? stack
});




}
/// @nodoc
class _$ErrorInfoCopyWithImpl<$Res>
    implements $ErrorInfoCopyWith<$Res> {
  _$ErrorInfoCopyWithImpl(this._self, this._then);

  final ErrorInfo _self;
  final $Res Function(ErrorInfo) _then;

/// Create a copy of ErrorInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? errorType = null,Object? message = null,Object? stack = freezed,}) {
  return _then(ErrorInfo(
errorType: null == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stack: freezed == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorInfo].
extension ErrorInfoPatterns on ErrorInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorInfo value)  $default,){
final _that = this;
switch (_that) {
case _ErrorInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String errorType,  String message,  String? stack)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorInfo() when $default != null:
return $default(_that.errorType,_that.message,_that.stack);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String errorType,  String message,  String? stack)  $default,) {final _that = this;
switch (_that) {
case _ErrorInfo():
return $default(_that.errorType,_that.message,_that.stack);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String errorType,  String message,  String? stack)?  $default,) {final _that = this;
switch (_that) {
case _ErrorInfo() when $default != null:
return $default(_that.errorType,_that.message,_that.stack);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorInfo implements ErrorInfo {
  const _ErrorInfo({required this.errorType, required this.message, this.stack});
  factory _ErrorInfo.fromJson(Map<String, dynamic> json) => _$ErrorInfoFromJson(json);

/// Error category, e.g. `model`.
@override final  String errorType;
/// Human-readable message.
@override final  String message;
/// Stack trace, when the host sends one.
@override final  String? stack;

/// Create a copy of ErrorInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorInfoCopyWith<_ErrorInfo> get copyWith => __$ErrorInfoCopyWithImpl<_ErrorInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorInfo&&(identical(other.errorType, errorType) || other.errorType == errorType)&&(identical(other.message, message) || other.message == message)&&(identical(other.stack, stack) || other.stack == stack));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,errorType,message,stack);
}

@override
String toString() {
    return 'ErrorInfo(errorType: $errorType, message: $message, stack: $stack)';
}


}

/// @nodoc
abstract mixin class _$ErrorInfoCopyWith<$Res> implements $ErrorInfoCopyWith<$Res> {
  factory _$ErrorInfoCopyWith(_ErrorInfo value, $Res Function(_ErrorInfo) _then) = __$ErrorInfoCopyWithImpl;
@override @useResult
$Res call({
 String errorType, String message, String? stack
});




}
/// @nodoc
class __$ErrorInfoCopyWithImpl<$Res>
    implements _$ErrorInfoCopyWith<$Res> {
  __$ErrorInfoCopyWithImpl(this._self, this._then);

  final _ErrorInfo _self;
  final $Res Function(_ErrorInfo) _then;

/// Create a copy of ErrorInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? errorType = null,Object? message = null,Object? stack = freezed,}) {
  return _then(_ErrorInfo(
errorType: null == errorType ? _self.errorType : errorType // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stack: freezed == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ConfirmationOption {

/// Option ID, sent back as `selectedOptionId`.
 String get id;/// Button label.
 String get label;/// `approve` or `deny`.
 String get kind;/// Options with the same group are shown together.
 int? get group;
/// Create a copy of ConfirmationOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfirmationOptionCopyWith<ConfirmationOption> get copyWith => _$ConfirmationOptionCopyWithImpl<ConfirmationOption>(this as ConfirmationOption, _$identity);

  /// Serializes this ConfirmationOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConfirmationOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfirmationOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.group, _this.group) || other.group == _this.group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConfirmationOption;
  return Object.hash(runtimeType,_this.id,_this.label,_this.kind,_this.group);
}

@override
String toString() {
  final _this = this as ConfirmationOption;
  return 'ConfirmationOption(id: ${_this.id}, label: ${_this.label}, kind: ${_this.kind}, group: ${_this.group})';
}


}

/// @nodoc
abstract mixin class $ConfirmationOptionCopyWith<$Res>  {
  factory $ConfirmationOptionCopyWith(ConfirmationOption value, $Res Function(ConfirmationOption) _then) = _$ConfirmationOptionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String kind, int? group
});




}
/// @nodoc
class _$ConfirmationOptionCopyWithImpl<$Res>
    implements $ConfirmationOptionCopyWith<$Res> {
  _$ConfirmationOptionCopyWithImpl(this._self, this._then);

  final ConfirmationOption _self;
  final $Res Function(ConfirmationOption) _then;

/// Create a copy of ConfirmationOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? group = freezed,}) {
  return _then(ConfirmationOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfirmationOption].
extension ConfirmationOptionPatterns on ConfirmationOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConfirmationOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConfirmationOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConfirmationOption value)  $default,){
final _that = this;
switch (_that) {
case _ConfirmationOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConfirmationOption value)?  $default,){
final _that = this;
switch (_that) {
case _ConfirmationOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String kind,  int? group)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConfirmationOption() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.group);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String kind,  int? group)  $default,) {final _that = this;
switch (_that) {
case _ConfirmationOption():
return $default(_that.id,_that.label,_that.kind,_that.group);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String kind,  int? group)?  $default,) {final _that = this;
switch (_that) {
case _ConfirmationOption() when $default != null:
return $default(_that.id,_that.label,_that.kind,_that.group);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConfirmationOption implements ConfirmationOption {
  const _ConfirmationOption({required this.id, required this.label, required this.kind, this.group});
  factory _ConfirmationOption.fromJson(Map<String, dynamic> json) => _$ConfirmationOptionFromJson(json);

/// Option ID, sent back as `selectedOptionId`.
@override final  String id;
/// Button label.
@override final  String label;
/// `approve` or `deny`.
@override final  String kind;
/// Options with the same group are shown together.
@override final  int? group;

/// Create a copy of ConfirmationOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmationOptionCopyWith<_ConfirmationOption> get copyWith => __$ConfirmationOptionCopyWithImpl<_ConfirmationOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConfirmationOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmationOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.group, group) || other.group == group));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,kind,group);
}

@override
String toString() {
    return 'ConfirmationOption(id: $id, label: $label, kind: $kind, group: $group)';
}


}

/// @nodoc
abstract mixin class _$ConfirmationOptionCopyWith<$Res> implements $ConfirmationOptionCopyWith<$Res> {
  factory _$ConfirmationOptionCopyWith(_ConfirmationOption value, $Res Function(_ConfirmationOption) _then) = __$ConfirmationOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String kind, int? group
});




}
/// @nodoc
class __$ConfirmationOptionCopyWithImpl<$Res>
    implements _$ConfirmationOptionCopyWith<$Res> {
  __$ConfirmationOptionCopyWithImpl(this._self, this._then);

  final _ConfirmationOption _self;
  final $Res Function(_ConfirmationOption) _then;

/// Create a copy of ConfirmationOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? group = freezed,}) {
  return _then(_ConfirmationOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ToolCall {

/// Tool call ID, unique within the turn.
 String get toolCallId;/// Machine-readable tool name, e.g. `bash`.
 String get toolName;/// Human-readable tool name, e.g. `Bash`.
 String get displayName;/// Lifecycle status; selects which other fields apply.
@JsonKey(unknownEnumValue: ToolCallStatus.unknown) ToolCallStatus get status;/// Why the model is calling the tool.
 String? get intention;/// Who runs the tool (client or MCP server), passed through.
 JsonMap? get contributor;/// Input JSON streamed so far (`streaming` only).
 String? get partialInput;/// `StringOrMarkdown` describing the call, e.g. "Running `ls`".
 Object? get invocationMessage;/// Tool input: a JSON string or a `ContentRef` map.
 Object? get toolInput;/// `StringOrMarkdown` title for the approval prompt.
 Object? get confirmationTitle;/// Risk assessment for the approval prompt (passed through).
 JsonMap? get riskAssessment;/// File edits the call would make (passed through).
 JsonMap? get edits;/// Whether the user may edit [toolInput] before approving.
 bool? get editable;/// Host-provided approve/deny choices.
 List<ConfirmationOption>? get options;/// How the call was confirmed: `not-needed`, `user-action` or `setting`.
 String? get confirmed;/// The option the user chose.
 ConfirmationOption? get selectedOption;/// Result content (text, terminals, file edits, ...), passed through.
 List<JsonMap>? get content;/// Whether the tool succeeded (finished statuses only).
 bool? get success;/// `StringOrMarkdown` past-tense summary, e.g. "Ran `ls`".
 Object? get pastTenseMessage;/// Structured result (passed through).
 JsonMap? get structuredContent;/// Tool error: `{message, code?}`.
 JsonMap? get error;/// Authentication the tool needs (`auth-required` only).
 JsonMap? get auth;/// Why the call was cancelled: `denied`, `skipped` or `result-denied`.
 String? get reason;/// `StringOrMarkdown` explanation of the cancellation.
 Object? get reasonMessage;/// A message the user sent instead of approving.
 Message? get userSuggestion;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallCopyWith<ToolCall> get copyWith => _$ToolCallCopyWithImpl<ToolCall>(this as ToolCall, _$identity);

  /// Serializes this ToolCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ToolCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCall&&(identical(other.toolCallId, _this.toolCallId) || other.toolCallId == _this.toolCallId)&&(identical(other.toolName, _this.toolName) || other.toolName == _this.toolName)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.intention, _this.intention) || other.intention == _this.intention)&&const DeepCollectionEquality().equals(other.contributor, _this.contributor)&&(identical(other.partialInput, _this.partialInput) || other.partialInput == _this.partialInput)&&const DeepCollectionEquality().equals(other.invocationMessage, _this.invocationMessage)&&const DeepCollectionEquality().equals(other.toolInput, _this.toolInput)&&const DeepCollectionEquality().equals(other.confirmationTitle, _this.confirmationTitle)&&const DeepCollectionEquality().equals(other.riskAssessment, _this.riskAssessment)&&const DeepCollectionEquality().equals(other.edits, _this.edits)&&(identical(other.editable, _this.editable) || other.editable == _this.editable)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.confirmed, _this.confirmed) || other.confirmed == _this.confirmed)&&(identical(other.selectedOption, _this.selectedOption) || other.selectedOption == _this.selectedOption)&&const DeepCollectionEquality().equals(other.content, _this.content)&&(identical(other.success, _this.success) || other.success == _this.success)&&const DeepCollectionEquality().equals(other.pastTenseMessage, _this.pastTenseMessage)&&const DeepCollectionEquality().equals(other.structuredContent, _this.structuredContent)&&const DeepCollectionEquality().equals(other.error, _this.error)&&const DeepCollectionEquality().equals(other.auth, _this.auth)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&const DeepCollectionEquality().equals(other.reasonMessage, _this.reasonMessage)&&(identical(other.userSuggestion, _this.userSuggestion) || other.userSuggestion == _this.userSuggestion)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ToolCall;
  return Object.hashAll([runtimeType,_this.toolCallId,_this.toolName,_this.displayName,_this.status,_this.intention,const DeepCollectionEquality().hash(_this.contributor),_this.partialInput,const DeepCollectionEquality().hash(_this.invocationMessage),const DeepCollectionEquality().hash(_this.toolInput),const DeepCollectionEquality().hash(_this.confirmationTitle),const DeepCollectionEquality().hash(_this.riskAssessment),const DeepCollectionEquality().hash(_this.edits),_this.editable,const DeepCollectionEquality().hash(_this.options),_this.confirmed,_this.selectedOption,const DeepCollectionEquality().hash(_this.content),_this.success,const DeepCollectionEquality().hash(_this.pastTenseMessage),const DeepCollectionEquality().hash(_this.structuredContent),const DeepCollectionEquality().hash(_this.error),const DeepCollectionEquality().hash(_this.auth),_this.reason,const DeepCollectionEquality().hash(_this.reasonMessage),_this.userSuggestion,const DeepCollectionEquality().hash(_this.meta)]);
}

@override
String toString() {
  final _this = this as ToolCall;
  return 'ToolCall(toolCallId: ${_this.toolCallId}, toolName: ${_this.toolName}, displayName: ${_this.displayName}, status: ${_this.status}, intention: ${_this.intention}, contributor: ${_this.contributor}, partialInput: ${_this.partialInput}, invocationMessage: ${_this.invocationMessage}, toolInput: ${_this.toolInput}, confirmationTitle: ${_this.confirmationTitle}, riskAssessment: ${_this.riskAssessment}, edits: ${_this.edits}, editable: ${_this.editable}, options: ${_this.options}, confirmed: ${_this.confirmed}, selectedOption: ${_this.selectedOption}, content: ${_this.content}, success: ${_this.success}, pastTenseMessage: ${_this.pastTenseMessage}, structuredContent: ${_this.structuredContent}, error: ${_this.error}, auth: ${_this.auth}, reason: ${_this.reason}, reasonMessage: ${_this.reasonMessage}, userSuggestion: ${_this.userSuggestion}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $ToolCallCopyWith<$Res>  {
  factory $ToolCallCopyWith(ToolCall value, $Res Function(ToolCall) _then) = _$ToolCallCopyWithImpl;
@useResult
$Res call({
 String toolCallId, String toolName, String displayName,@JsonKey(unknownEnumValue: ToolCallStatus.unknown) ToolCallStatus status, String? intention, JsonMap? contributor, String? partialInput, Object? invocationMessage, Object? toolInput, Object? confirmationTitle, JsonMap? riskAssessment, JsonMap? edits, bool? editable, List<ConfirmationOption>? options, String? confirmed, ConfirmationOption? selectedOption, List<JsonMap>? content, bool? success, Object? pastTenseMessage, JsonMap? structuredContent, JsonMap? error, JsonMap? auth, String? reason, Object? reasonMessage, Message? userSuggestion,@JsonKey(name: '_meta') JsonMap? meta
});


$ConfirmationOptionCopyWith<$Res>? get selectedOption;$MessageCopyWith<$Res>? get userSuggestion;

}
/// @nodoc
class _$ToolCallCopyWithImpl<$Res>
    implements $ToolCallCopyWith<$Res> {
  _$ToolCallCopyWithImpl(this._self, this._then);

  final ToolCall _self;
  final $Res Function(ToolCall) _then;

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toolCallId = null,Object? toolName = null,Object? displayName = null,Object? status = null,Object? intention = freezed,Object? contributor = freezed,Object? partialInput = freezed,Object? invocationMessage = freezed,Object? toolInput = freezed,Object? confirmationTitle = freezed,Object? riskAssessment = freezed,Object? edits = freezed,Object? editable = freezed,Object? options = freezed,Object? confirmed = freezed,Object? selectedOption = freezed,Object? content = freezed,Object? success = freezed,Object? pastTenseMessage = freezed,Object? structuredContent = freezed,Object? error = freezed,Object? auth = freezed,Object? reason = freezed,Object? reasonMessage = freezed,Object? userSuggestion = freezed,Object? meta = freezed,}) {
  return _then(ToolCall(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ToolCallStatus,intention: freezed == intention ? _self.intention : intention // ignore: cast_nullable_to_non_nullable
as String?,contributor: freezed == contributor ? _self.contributor : contributor // ignore: cast_nullable_to_non_nullable
as JsonMap?,partialInput: freezed == partialInput ? _self.partialInput : partialInput // ignore: cast_nullable_to_non_nullable
as String?,invocationMessage: freezed == invocationMessage ? _self.invocationMessage : invocationMessage ,toolInput: freezed == toolInput ? _self.toolInput : toolInput ,confirmationTitle: freezed == confirmationTitle ? _self.confirmationTitle : confirmationTitle ,riskAssessment: freezed == riskAssessment ? _self.riskAssessment : riskAssessment // ignore: cast_nullable_to_non_nullable
as JsonMap?,edits: freezed == edits ? _self.edits : edits // ignore: cast_nullable_to_non_nullable
as JsonMap?,editable: freezed == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<ConfirmationOption>?,confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as String?,selectedOption: freezed == selectedOption ? _self.selectedOption : selectedOption // ignore: cast_nullable_to_non_nullable
as ConfirmationOption?,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,pastTenseMessage: freezed == pastTenseMessage ? _self.pastTenseMessage : pastTenseMessage ,structuredContent: freezed == structuredContent ? _self.structuredContent : structuredContent // ignore: cast_nullable_to_non_nullable
as JsonMap?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as JsonMap?,auth: freezed == auth ? _self.auth : auth // ignore: cast_nullable_to_non_nullable
as JsonMap?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,reasonMessage: freezed == reasonMessage ? _self.reasonMessage : reasonMessage ,userSuggestion: freezed == userSuggestion ? _self.userSuggestion : userSuggestion // ignore: cast_nullable_to_non_nullable
as Message?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConfirmationOptionCopyWith<$Res>? get selectedOption {
    if (_self.selectedOption == null) {
    return null;
  }

  return $ConfirmationOptionCopyWith<$Res>(_self.selectedOption!, (value) {
    return _then(_self.copyWith(selectedOption: value));
  });
}/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get userSuggestion {
    if (_self.userSuggestion == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.userSuggestion!, (value) {
    return _then(_self.copyWith(userSuggestion: value));
  });
}
}


/// Adds pattern-matching-related methods to [ToolCall].
extension ToolCallPatterns on ToolCall {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolCall value)  $default,){
final _that = this;
switch (_that) {
case _ToolCall():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolCall value)?  $default,){
final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String toolCallId,  String toolName,  String displayName, @JsonKey(unknownEnumValue: ToolCallStatus.unknown)  ToolCallStatus status,  String? intention,  JsonMap? contributor,  String? partialInput,  Object? invocationMessage,  Object? toolInput,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  List<ConfirmationOption>? options,  String? confirmed,  ConfirmationOption? selectedOption,  List<JsonMap>? content,  bool? success,  Object? pastTenseMessage,  JsonMap? structuredContent,  JsonMap? error,  JsonMap? auth,  String? reason,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that.toolCallId,_that.toolName,_that.displayName,_that.status,_that.intention,_that.contributor,_that.partialInput,_that.invocationMessage,_that.toolInput,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.options,_that.confirmed,_that.selectedOption,_that.content,_that.success,_that.pastTenseMessage,_that.structuredContent,_that.error,_that.auth,_that.reason,_that.reasonMessage,_that.userSuggestion,_that.meta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String toolCallId,  String toolName,  String displayName, @JsonKey(unknownEnumValue: ToolCallStatus.unknown)  ToolCallStatus status,  String? intention,  JsonMap? contributor,  String? partialInput,  Object? invocationMessage,  Object? toolInput,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  List<ConfirmationOption>? options,  String? confirmed,  ConfirmationOption? selectedOption,  List<JsonMap>? content,  bool? success,  Object? pastTenseMessage,  JsonMap? structuredContent,  JsonMap? error,  JsonMap? auth,  String? reason,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _ToolCall():
return $default(_that.toolCallId,_that.toolName,_that.displayName,_that.status,_that.intention,_that.contributor,_that.partialInput,_that.invocationMessage,_that.toolInput,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.options,_that.confirmed,_that.selectedOption,_that.content,_that.success,_that.pastTenseMessage,_that.structuredContent,_that.error,_that.auth,_that.reason,_that.reasonMessage,_that.userSuggestion,_that.meta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String toolCallId,  String toolName,  String displayName, @JsonKey(unknownEnumValue: ToolCallStatus.unknown)  ToolCallStatus status,  String? intention,  JsonMap? contributor,  String? partialInput,  Object? invocationMessage,  Object? toolInput,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  List<ConfirmationOption>? options,  String? confirmed,  ConfirmationOption? selectedOption,  List<JsonMap>? content,  bool? success,  Object? pastTenseMessage,  JsonMap? structuredContent,  JsonMap? error,  JsonMap? auth,  String? reason,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _ToolCall() when $default != null:
return $default(_that.toolCallId,_that.toolName,_that.displayName,_that.status,_that.intention,_that.contributor,_that.partialInput,_that.invocationMessage,_that.toolInput,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.options,_that.confirmed,_that.selectedOption,_that.content,_that.success,_that.pastTenseMessage,_that.structuredContent,_that.error,_that.auth,_that.reason,_that.reasonMessage,_that.userSuggestion,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ToolCall implements ToolCall {
  const _ToolCall({required this.toolCallId, required this.toolName, required this.displayName, @JsonKey(unknownEnumValue: ToolCallStatus.unknown) required this.status, this.intention,  JsonMap? contributor, this.partialInput, this.invocationMessage, this.toolInput, this.confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits, this.editable,  List<ConfirmationOption>? options, this.confirmed, this.selectedOption,  List<JsonMap>? content, this.success, this.pastTenseMessage,  JsonMap? structuredContent,  JsonMap? error,  JsonMap? auth, this.reason, this.reasonMessage, this.userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta}): _contributor = contributor,_riskAssessment = riskAssessment,_edits = edits,_options = options,_content = content,_structuredContent = structuredContent,_error = error,_auth = auth,_meta = meta;
  factory _ToolCall.fromJson(Map<String, dynamic> json) => _$ToolCallFromJson(json);

/// Tool call ID, unique within the turn.
@override final  String toolCallId;
/// Machine-readable tool name, e.g. `bash`.
@override final  String toolName;
/// Human-readable tool name, e.g. `Bash`.
@override final  String displayName;
/// Lifecycle status; selects which other fields apply.
@override@JsonKey(unknownEnumValue: ToolCallStatus.unknown) final  ToolCallStatus status;
/// Why the model is calling the tool.
@override final  String? intention;
/// Who runs the tool (client or MCP server), passed through.
 final  JsonMap? _contributor;
/// Who runs the tool (client or MCP server), passed through.
@override JsonMap? get contributor {
  final value = _contributor;
  if (value == null) return null;
  if (_contributor is EqualUnmodifiableMapView) return _contributor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Input JSON streamed so far (`streaming` only).
@override final  String? partialInput;
/// `StringOrMarkdown` describing the call, e.g. "Running `ls`".
@override final  Object? invocationMessage;
/// Tool input: a JSON string or a `ContentRef` map.
@override final  Object? toolInput;
/// `StringOrMarkdown` title for the approval prompt.
@override final  Object? confirmationTitle;
/// Risk assessment for the approval prompt (passed through).
 final  JsonMap? _riskAssessment;
/// Risk assessment for the approval prompt (passed through).
@override JsonMap? get riskAssessment {
  final value = _riskAssessment;
  if (value == null) return null;
  if (_riskAssessment is EqualUnmodifiableMapView) return _riskAssessment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// File edits the call would make (passed through).
 final  JsonMap? _edits;
/// File edits the call would make (passed through).
@override JsonMap? get edits {
  final value = _edits;
  if (value == null) return null;
  if (_edits is EqualUnmodifiableMapView) return _edits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Whether the user may edit [toolInput] before approving.
@override final  bool? editable;
/// Host-provided approve/deny choices.
 final  List<ConfirmationOption>? _options;
/// Host-provided approve/deny choices.
@override List<ConfirmationOption>? get options {
  final value = _options;
  if (value == null) return null;
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// How the call was confirmed: `not-needed`, `user-action` or `setting`.
@override final  String? confirmed;
/// The option the user chose.
@override final  ConfirmationOption? selectedOption;
/// Result content (text, terminals, file edits, ...), passed through.
 final  List<JsonMap>? _content;
/// Result content (text, terminals, file edits, ...), passed through.
@override List<JsonMap>? get content {
  final value = _content;
  if (value == null) return null;
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Whether the tool succeeded (finished statuses only).
@override final  bool? success;
/// `StringOrMarkdown` past-tense summary, e.g. "Ran `ls`".
@override final  Object? pastTenseMessage;
/// Structured result (passed through).
 final  JsonMap? _structuredContent;
/// Structured result (passed through).
@override JsonMap? get structuredContent {
  final value = _structuredContent;
  if (value == null) return null;
  if (_structuredContent is EqualUnmodifiableMapView) return _structuredContent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Tool error: `{message, code?}`.
 final  JsonMap? _error;
/// Tool error: `{message, code?}`.
@override JsonMap? get error {
  final value = _error;
  if (value == null) return null;
  if (_error is EqualUnmodifiableMapView) return _error;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Authentication the tool needs (`auth-required` only).
 final  JsonMap? _auth;
/// Authentication the tool needs (`auth-required` only).
@override JsonMap? get auth {
  final value = _auth;
  if (value == null) return null;
  if (_auth is EqualUnmodifiableMapView) return _auth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Why the call was cancelled: `denied`, `skipped` or `result-denied`.
@override final  String? reason;
/// `StringOrMarkdown` explanation of the cancellation.
@override final  Object? reasonMessage;
/// A message the user sent instead of approving.
@override final  Message? userSuggestion;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@override@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolCallCopyWith<_ToolCall> get copyWith => __$ToolCallCopyWithImpl<_ToolCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToolCallToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolCall&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.status, status) || other.status == status)&&(identical(other.intention, intention) || other.intention == intention)&&const DeepCollectionEquality().equals(other.contributor, _contributor)&&(identical(other.partialInput, partialInput) || other.partialInput == partialInput)&&const DeepCollectionEquality().equals(other.invocationMessage, invocationMessage)&&const DeepCollectionEquality().equals(other.toolInput, toolInput)&&const DeepCollectionEquality().equals(other.confirmationTitle, confirmationTitle)&&const DeepCollectionEquality().equals(other.riskAssessment, _riskAssessment)&&const DeepCollectionEquality().equals(other.edits, _edits)&&(identical(other.editable, editable) || other.editable == editable)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&(identical(other.selectedOption, selectedOption) || other.selectedOption == selectedOption)&&const DeepCollectionEquality().equals(other.content, _content)&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.pastTenseMessage, pastTenseMessage)&&const DeepCollectionEquality().equals(other.structuredContent, _structuredContent)&&const DeepCollectionEquality().equals(other.error, _error)&&const DeepCollectionEquality().equals(other.auth, _auth)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.reasonMessage, reasonMessage)&&(identical(other.userSuggestion, userSuggestion) || other.userSuggestion == userSuggestion)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,toolCallId,toolName,displayName,status,intention,const DeepCollectionEquality().hash(_contributor),partialInput,const DeepCollectionEquality().hash(invocationMessage),const DeepCollectionEquality().hash(toolInput),const DeepCollectionEquality().hash(confirmationTitle),const DeepCollectionEquality().hash(_riskAssessment),const DeepCollectionEquality().hash(_edits),editable,const DeepCollectionEquality().hash(_options),confirmed,selectedOption,const DeepCollectionEquality().hash(_content),success,const DeepCollectionEquality().hash(pastTenseMessage),const DeepCollectionEquality().hash(_structuredContent),const DeepCollectionEquality().hash(_error),const DeepCollectionEquality().hash(_auth),reason,const DeepCollectionEquality().hash(reasonMessage),userSuggestion,const DeepCollectionEquality().hash(_meta)]);
}

@override
String toString() {
    return 'ToolCall(toolCallId: $toolCallId, toolName: $toolName, displayName: $displayName, status: $status, intention: $intention, contributor: $contributor, partialInput: $partialInput, invocationMessage: $invocationMessage, toolInput: $toolInput, confirmationTitle: $confirmationTitle, riskAssessment: $riskAssessment, edits: $edits, editable: $editable, options: $options, confirmed: $confirmed, selectedOption: $selectedOption, content: $content, success: $success, pastTenseMessage: $pastTenseMessage, structuredContent: $structuredContent, error: $error, auth: $auth, reason: $reason, reasonMessage: $reasonMessage, userSuggestion: $userSuggestion, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$ToolCallCopyWith<$Res> implements $ToolCallCopyWith<$Res> {
  factory _$ToolCallCopyWith(_ToolCall value, $Res Function(_ToolCall) _then) = __$ToolCallCopyWithImpl;
@override @useResult
$Res call({
 String toolCallId, String toolName, String displayName,@JsonKey(unknownEnumValue: ToolCallStatus.unknown) ToolCallStatus status, String? intention, JsonMap? contributor, String? partialInput, Object? invocationMessage, Object? toolInput, Object? confirmationTitle, JsonMap? riskAssessment, JsonMap? edits, bool? editable, List<ConfirmationOption>? options, String? confirmed, ConfirmationOption? selectedOption, List<JsonMap>? content, bool? success, Object? pastTenseMessage, JsonMap? structuredContent, JsonMap? error, JsonMap? auth, String? reason, Object? reasonMessage, Message? userSuggestion,@JsonKey(name: '_meta') JsonMap? meta
});


@override $ConfirmationOptionCopyWith<$Res>? get selectedOption;@override $MessageCopyWith<$Res>? get userSuggestion;

}
/// @nodoc
class __$ToolCallCopyWithImpl<$Res>
    implements _$ToolCallCopyWith<$Res> {
  __$ToolCallCopyWithImpl(this._self, this._then);

  final _ToolCall _self;
  final $Res Function(_ToolCall) _then;

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toolCallId = null,Object? toolName = null,Object? displayName = null,Object? status = null,Object? intention = freezed,Object? contributor = freezed,Object? partialInput = freezed,Object? invocationMessage = freezed,Object? toolInput = freezed,Object? confirmationTitle = freezed,Object? riskAssessment = freezed,Object? edits = freezed,Object? editable = freezed,Object? options = freezed,Object? confirmed = freezed,Object? selectedOption = freezed,Object? content = freezed,Object? success = freezed,Object? pastTenseMessage = freezed,Object? structuredContent = freezed,Object? error = freezed,Object? auth = freezed,Object? reason = freezed,Object? reasonMessage = freezed,Object? userSuggestion = freezed,Object? meta = freezed,}) {
  return _then(_ToolCall(
toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ToolCallStatus,intention: freezed == intention ? _self.intention : intention // ignore: cast_nullable_to_non_nullable
as String?,contributor: freezed == contributor ? _self._contributor : contributor // ignore: cast_nullable_to_non_nullable
as JsonMap?,partialInput: freezed == partialInput ? _self.partialInput : partialInput // ignore: cast_nullable_to_non_nullable
as String?,invocationMessage: freezed == invocationMessage ? _self.invocationMessage : invocationMessage ,toolInput: freezed == toolInput ? _self.toolInput : toolInput ,confirmationTitle: freezed == confirmationTitle ? _self.confirmationTitle : confirmationTitle ,riskAssessment: freezed == riskAssessment ? _self._riskAssessment : riskAssessment // ignore: cast_nullable_to_non_nullable
as JsonMap?,edits: freezed == edits ? _self._edits : edits // ignore: cast_nullable_to_non_nullable
as JsonMap?,editable: freezed == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool?,options: freezed == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<ConfirmationOption>?,confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as String?,selectedOption: freezed == selectedOption ? _self.selectedOption : selectedOption // ignore: cast_nullable_to_non_nullable
as ConfirmationOption?,content: freezed == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,success: freezed == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool?,pastTenseMessage: freezed == pastTenseMessage ? _self.pastTenseMessage : pastTenseMessage ,structuredContent: freezed == structuredContent ? _self._structuredContent : structuredContent // ignore: cast_nullable_to_non_nullable
as JsonMap?,error: freezed == error ? _self._error : error // ignore: cast_nullable_to_non_nullable
as JsonMap?,auth: freezed == auth ? _self._auth : auth // ignore: cast_nullable_to_non_nullable
as JsonMap?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,reasonMessage: freezed == reasonMessage ? _self.reasonMessage : reasonMessage ,userSuggestion: freezed == userSuggestion ? _self.userSuggestion : userSuggestion // ignore: cast_nullable_to_non_nullable
as Message?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ConfirmationOptionCopyWith<$Res>? get selectedOption {
    if (_self.selectedOption == null) {
    return null;
  }

  return $ConfirmationOptionCopyWith<$Res>(_self.selectedOption!, (value) {
    return _then(_self.copyWith(selectedOption: value));
  });
}/// Create a copy of ToolCall
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get userSuggestion {
    if (_self.userSuggestion == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.userSuggestion!, (value) {
    return _then(_self.copyWith(userSuggestion: value));
  });
}
}


/// @nodoc
mixin _$ChatInputOption {

/// Option ID, sent back in the answer.
 String get id;/// Option label.
 String get label;/// Longer description.
 String? get description;/// Whether this is the suggested choice.
 bool? get recommended;
/// Create a copy of ChatInputOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputOptionCopyWith<ChatInputOption> get copyWith => _$ChatInputOptionCopyWithImpl<ChatInputOption>(this as ChatInputOption, _$identity);

  /// Serializes this ChatInputOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatInputOption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputOption&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.recommended, _this.recommended) || other.recommended == _this.recommended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatInputOption;
  return Object.hash(runtimeType,_this.id,_this.label,_this.description,_this.recommended);
}

@override
String toString() {
  final _this = this as ChatInputOption;
  return 'ChatInputOption(id: ${_this.id}, label: ${_this.label}, description: ${_this.description}, recommended: ${_this.recommended})';
}


}

/// @nodoc
abstract mixin class $ChatInputOptionCopyWith<$Res>  {
  factory $ChatInputOptionCopyWith(ChatInputOption value, $Res Function(ChatInputOption) _then) = _$ChatInputOptionCopyWithImpl;
@useResult
$Res call({
 String id, String label, String? description, bool? recommended
});




}
/// @nodoc
class _$ChatInputOptionCopyWithImpl<$Res>
    implements $ChatInputOptionCopyWith<$Res> {
  _$ChatInputOptionCopyWithImpl(this._self, this._then);

  final ChatInputOption _self;
  final $Res Function(ChatInputOption) _then;

/// Create a copy of ChatInputOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? description = freezed,Object? recommended = freezed,}) {
  return _then(ChatInputOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,recommended: freezed == recommended ? _self.recommended : recommended // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatInputOption].
extension ChatInputOptionPatterns on ChatInputOption {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatInputOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatInputOption() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatInputOption value)  $default,){
final _that = this;
switch (_that) {
case _ChatInputOption():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatInputOption value)?  $default,){
final _that = this;
switch (_that) {
case _ChatInputOption() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  String? description,  bool? recommended)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatInputOption() when $default != null:
return $default(_that.id,_that.label,_that.description,_that.recommended);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  String? description,  bool? recommended)  $default,) {final _that = this;
switch (_that) {
case _ChatInputOption():
return $default(_that.id,_that.label,_that.description,_that.recommended);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  String? description,  bool? recommended)?  $default,) {final _that = this;
switch (_that) {
case _ChatInputOption() when $default != null:
return $default(_that.id,_that.label,_that.description,_that.recommended);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatInputOption implements ChatInputOption {
  const _ChatInputOption({required this.id, required this.label, this.description, this.recommended});
  factory _ChatInputOption.fromJson(Map<String, dynamic> json) => _$ChatInputOptionFromJson(json);

/// Option ID, sent back in the answer.
@override final  String id;
/// Option label.
@override final  String label;
/// Longer description.
@override final  String? description;
/// Whether this is the suggested choice.
@override final  bool? recommended;

/// Create a copy of ChatInputOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatInputOptionCopyWith<_ChatInputOption> get copyWith => __$ChatInputOptionCopyWithImpl<_ChatInputOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputOptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatInputOption&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.recommended, recommended) || other.recommended == recommended));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,label,description,recommended);
}

@override
String toString() {
    return 'ChatInputOption(id: $id, label: $label, description: $description, recommended: $recommended)';
}


}

/// @nodoc
abstract mixin class _$ChatInputOptionCopyWith<$Res> implements $ChatInputOptionCopyWith<$Res> {
  factory _$ChatInputOptionCopyWith(_ChatInputOption value, $Res Function(_ChatInputOption) _then) = __$ChatInputOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String? description, bool? recommended
});




}
/// @nodoc
class __$ChatInputOptionCopyWithImpl<$Res>
    implements _$ChatInputOptionCopyWith<$Res> {
  __$ChatInputOptionCopyWithImpl(this._self, this._then);

  final _ChatInputOption _self;
  final $Res Function(_ChatInputOption) _then;

/// Create a copy of ChatInputOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? description = freezed,Object? recommended = freezed,}) {
  return _then(_ChatInputOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,recommended: freezed == recommended ? _self.recommended : recommended // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$ChatInputQuestion {

/// Question ID; the key of its answer.
 String get id;/// `text`, `number`, `integer`, `boolean`, `single-select` or
/// `multi-select`.
 String get kind;/// Question text.
 String get message;/// Short title.
 String? get title;/// Whether an answer is required.
 bool? get required;/// Choices for select questions.
 List<ChatInputOption>? get options;/// Whether select questions also accept free text.
 bool? get allowFreeformInput;/// Text format hint, e.g. `email` (text questions).
 String? get format;/// Minimum length, value or selection count.
 num? get min;/// Maximum length, value or selection count.
 num? get max;/// Default answer (string, number or boolean).
 Object? get defaultValue;
/// Create a copy of ChatInputQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputQuestionCopyWith<ChatInputQuestion> get copyWith => _$ChatInputQuestionCopyWithImpl<ChatInputQuestion>(this as ChatInputQuestion, _$identity);

  /// Serializes this ChatInputQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatInputQuestion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputQuestion&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.required, _this.required) || other.required == _this.required)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.allowFreeformInput, _this.allowFreeformInput) || other.allowFreeformInput == _this.allowFreeformInput)&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.min, _this.min) || other.min == _this.min)&&(identical(other.max, _this.max) || other.max == _this.max)&&const DeepCollectionEquality().equals(other.defaultValue, _this.defaultValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatInputQuestion;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.message,_this.title,_this.required,const DeepCollectionEquality().hash(_this.options),_this.allowFreeformInput,_this.format,_this.min,_this.max,const DeepCollectionEquality().hash(_this.defaultValue));
}

@override
String toString() {
  final _this = this as ChatInputQuestion;
  return 'ChatInputQuestion(id: ${_this.id}, kind: ${_this.kind}, message: ${_this.message}, title: ${_this.title}, required: ${_this.required}, options: ${_this.options}, allowFreeformInput: ${_this.allowFreeformInput}, format: ${_this.format}, min: ${_this.min}, max: ${_this.max}, defaultValue: ${_this.defaultValue})';
}


}

/// @nodoc
abstract mixin class $ChatInputQuestionCopyWith<$Res>  {
  factory $ChatInputQuestionCopyWith(ChatInputQuestion value, $Res Function(ChatInputQuestion) _then) = _$ChatInputQuestionCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String message, String? title, bool? required, List<ChatInputOption>? options, bool? allowFreeformInput, String? format, num? min, num? max, Object? defaultValue
});




}
/// @nodoc
class _$ChatInputQuestionCopyWithImpl<$Res>
    implements $ChatInputQuestionCopyWith<$Res> {
  _$ChatInputQuestionCopyWithImpl(this._self, this._then);

  final ChatInputQuestion _self;
  final $Res Function(ChatInputQuestion) _then;

/// Create a copy of ChatInputQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? message = null,Object? title = freezed,Object? required = freezed,Object? options = freezed,Object? allowFreeformInput = freezed,Object? format = freezed,Object? min = freezed,Object? max = freezed,Object? defaultValue = freezed,}) {
  return _then(ChatInputQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,required: freezed == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<ChatInputOption>?,allowFreeformInput: freezed == allowFreeformInput ? _self.allowFreeformInput : allowFreeformInput // ignore: cast_nullable_to_non_nullable
as bool?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue ,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatInputQuestion].
extension ChatInputQuestionPatterns on ChatInputQuestion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatInputQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatInputQuestion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatInputQuestion value)  $default,){
final _that = this;
switch (_that) {
case _ChatInputQuestion():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatInputQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _ChatInputQuestion() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String message,  String? title,  bool? required,  List<ChatInputOption>? options,  bool? allowFreeformInput,  String? format,  num? min,  num? max,  Object? defaultValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatInputQuestion() when $default != null:
return $default(_that.id,_that.kind,_that.message,_that.title,_that.required,_that.options,_that.allowFreeformInput,_that.format,_that.min,_that.max,_that.defaultValue);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String message,  String? title,  bool? required,  List<ChatInputOption>? options,  bool? allowFreeformInput,  String? format,  num? min,  num? max,  Object? defaultValue)  $default,) {final _that = this;
switch (_that) {
case _ChatInputQuestion():
return $default(_that.id,_that.kind,_that.message,_that.title,_that.required,_that.options,_that.allowFreeformInput,_that.format,_that.min,_that.max,_that.defaultValue);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String message,  String? title,  bool? required,  List<ChatInputOption>? options,  bool? allowFreeformInput,  String? format,  num? min,  num? max,  Object? defaultValue)?  $default,) {final _that = this;
switch (_that) {
case _ChatInputQuestion() when $default != null:
return $default(_that.id,_that.kind,_that.message,_that.title,_that.required,_that.options,_that.allowFreeformInput,_that.format,_that.min,_that.max,_that.defaultValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatInputQuestion implements ChatInputQuestion {
  const _ChatInputQuestion({required this.id, required this.kind, required this.message, this.title, this.required,  List<ChatInputOption>? options, this.allowFreeformInput, this.format, this.min, this.max, this.defaultValue}): _options = options;
  factory _ChatInputQuestion.fromJson(Map<String, dynamic> json) => _$ChatInputQuestionFromJson(json);

/// Question ID; the key of its answer.
@override final  String id;
/// `text`, `number`, `integer`, `boolean`, `single-select` or
/// `multi-select`.
@override final  String kind;
/// Question text.
@override final  String message;
/// Short title.
@override final  String? title;
/// Whether an answer is required.
@override final  bool? required;
/// Choices for select questions.
 final  List<ChatInputOption>? _options;
/// Choices for select questions.
@override List<ChatInputOption>? get options {
  final value = _options;
  if (value == null) return null;
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Whether select questions also accept free text.
@override final  bool? allowFreeformInput;
/// Text format hint, e.g. `email` (text questions).
@override final  String? format;
/// Minimum length, value or selection count.
@override final  num? min;
/// Maximum length, value or selection count.
@override final  num? max;
/// Default answer (string, number or boolean).
@override final  Object? defaultValue;

/// Create a copy of ChatInputQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatInputQuestionCopyWith<_ChatInputQuestion> get copyWith => __$ChatInputQuestionCopyWithImpl<_ChatInputQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatInputQuestion&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.message, message) || other.message == message)&&(identical(other.title, title) || other.title == title)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.allowFreeformInput, allowFreeformInput) || other.allowFreeformInput == allowFreeformInput)&&(identical(other.format, format) || other.format == format)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other.defaultValue, defaultValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,message,title,required,const DeepCollectionEquality().hash(_options),allowFreeformInput,format,min,max,const DeepCollectionEquality().hash(defaultValue));
}

@override
String toString() {
    return 'ChatInputQuestion(id: $id, kind: $kind, message: $message, title: $title, required: $required, options: $options, allowFreeformInput: $allowFreeformInput, format: $format, min: $min, max: $max, defaultValue: $defaultValue)';
}


}

/// @nodoc
abstract mixin class _$ChatInputQuestionCopyWith<$Res> implements $ChatInputQuestionCopyWith<$Res> {
  factory _$ChatInputQuestionCopyWith(_ChatInputQuestion value, $Res Function(_ChatInputQuestion) _then) = __$ChatInputQuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String message, String? title, bool? required, List<ChatInputOption>? options, bool? allowFreeformInput, String? format, num? min, num? max, Object? defaultValue
});




}
/// @nodoc
class __$ChatInputQuestionCopyWithImpl<$Res>
    implements _$ChatInputQuestionCopyWith<$Res> {
  __$ChatInputQuestionCopyWithImpl(this._self, this._then);

  final _ChatInputQuestion _self;
  final $Res Function(_ChatInputQuestion) _then;

/// Create a copy of ChatInputQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? message = null,Object? title = freezed,Object? required = freezed,Object? options = freezed,Object? allowFreeformInput = freezed,Object? format = freezed,Object? min = freezed,Object? max = freezed,Object? defaultValue = freezed,}) {
  return _then(_ChatInputQuestion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,required: freezed == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool?,options: freezed == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<ChatInputOption>?,allowFreeformInput: freezed == allowFreeformInput ? _self.allowFreeformInput : allowFreeformInput // ignore: cast_nullable_to_non_nullable
as bool?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,defaultValue: freezed == defaultValue ? _self.defaultValue : defaultValue ,
  ));
}


}


/// @nodoc
mixin _$ChatInputRequest {

/// Request ID.
 String get id;/// Text shown above the questions.
 String? get message;/// A URL the user should open instead of answering questions.
 String? get url;/// The questions to answer.
 List<ChatInputQuestion>? get questions;/// Draft or submitted answers keyed by question ID (`ChatInputAnswer`).
 Map<String, JsonMap>? get answers;
/// Create a copy of ChatInputRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputRequestCopyWith<ChatInputRequest> get copyWith => _$ChatInputRequestCopyWithImpl<ChatInputRequest>(this as ChatInputRequest, _$identity);

  /// Serializes this ChatInputRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatInputRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputRequest&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.url, _this.url) || other.url == _this.url)&&const DeepCollectionEquality().equals(other.questions, _this.questions)&&const DeepCollectionEquality().equals(other.answers, _this.answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatInputRequest;
  return Object.hash(runtimeType,_this.id,_this.message,_this.url,const DeepCollectionEquality().hash(_this.questions),const DeepCollectionEquality().hash(_this.answers));
}

@override
String toString() {
  final _this = this as ChatInputRequest;
  return 'ChatInputRequest(id: ${_this.id}, message: ${_this.message}, url: ${_this.url}, questions: ${_this.questions}, answers: ${_this.answers})';
}


}

/// @nodoc
abstract mixin class $ChatInputRequestCopyWith<$Res>  {
  factory $ChatInputRequestCopyWith(ChatInputRequest value, $Res Function(ChatInputRequest) _then) = _$ChatInputRequestCopyWithImpl;
@useResult
$Res call({
 String id, String? message, String? url, List<ChatInputQuestion>? questions, Map<String, JsonMap>? answers
});




}
/// @nodoc
class _$ChatInputRequestCopyWithImpl<$Res>
    implements $ChatInputRequestCopyWith<$Res> {
  _$ChatInputRequestCopyWithImpl(this._self, this._then);

  final ChatInputRequest _self;
  final $Res Function(ChatInputRequest) _then;

/// Create a copy of ChatInputRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = freezed,Object? url = freezed,Object? questions = freezed,Object? answers = freezed,}) {
  return _then(ChatInputRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,questions: freezed == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<ChatInputQuestion>?,answers: freezed == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, JsonMap>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatInputRequest].
extension ChatInputRequestPatterns on ChatInputRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatInputRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatInputRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatInputRequest value)  $default,){
final _that = this;
switch (_that) {
case _ChatInputRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatInputRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ChatInputRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? message,  String? url,  List<ChatInputQuestion>? questions,  Map<String, JsonMap>? answers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatInputRequest() when $default != null:
return $default(_that.id,_that.message,_that.url,_that.questions,_that.answers);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? message,  String? url,  List<ChatInputQuestion>? questions,  Map<String, JsonMap>? answers)  $default,) {final _that = this;
switch (_that) {
case _ChatInputRequest():
return $default(_that.id,_that.message,_that.url,_that.questions,_that.answers);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? message,  String? url,  List<ChatInputQuestion>? questions,  Map<String, JsonMap>? answers)?  $default,) {final _that = this;
switch (_that) {
case _ChatInputRequest() when $default != null:
return $default(_that.id,_that.message,_that.url,_that.questions,_that.answers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatInputRequest implements ChatInputRequest {
  const _ChatInputRequest({required this.id, this.message, this.url,  List<ChatInputQuestion>? questions,  Map<String, JsonMap>? answers}): _questions = questions,_answers = answers;
  factory _ChatInputRequest.fromJson(Map<String, dynamic> json) => _$ChatInputRequestFromJson(json);

/// Request ID.
@override final  String id;
/// Text shown above the questions.
@override final  String? message;
/// A URL the user should open instead of answering questions.
@override final  String? url;
/// The questions to answer.
 final  List<ChatInputQuestion>? _questions;
/// The questions to answer.
@override List<ChatInputQuestion>? get questions {
  final value = _questions;
  if (value == null) return null;
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Draft or submitted answers keyed by question ID (`ChatInputAnswer`).
 final  Map<String, JsonMap>? _answers;
/// Draft or submitted answers keyed by question ID (`ChatInputAnswer`).
@override Map<String, JsonMap>? get answers {
  final value = _answers;
  if (value == null) return null;
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ChatInputRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatInputRequestCopyWith<_ChatInputRequest> get copyWith => __$ChatInputRequestCopyWithImpl<_ChatInputRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatInputRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.questions, _questions)&&const DeepCollectionEquality().equals(other.answers, _answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,message,url,const DeepCollectionEquality().hash(_questions),const DeepCollectionEquality().hash(_answers));
}

@override
String toString() {
    return 'ChatInputRequest(id: $id, message: $message, url: $url, questions: $questions, answers: $answers)';
}


}

/// @nodoc
abstract mixin class _$ChatInputRequestCopyWith<$Res> implements $ChatInputRequestCopyWith<$Res> {
  factory _$ChatInputRequestCopyWith(_ChatInputRequest value, $Res Function(_ChatInputRequest) _then) = __$ChatInputRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String? message, String? url, List<ChatInputQuestion>? questions, Map<String, JsonMap>? answers
});




}
/// @nodoc
class __$ChatInputRequestCopyWithImpl<$Res>
    implements _$ChatInputRequestCopyWith<$Res> {
  __$ChatInputRequestCopyWithImpl(this._self, this._then);

  final _ChatInputRequest _self;
  final $Res Function(_ChatInputRequest) _then;

/// Create a copy of ChatInputRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = freezed,Object? url = freezed,Object? questions = freezed,Object? answers = freezed,}) {
  return _then(_ChatInputRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,questions: freezed == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<ChatInputQuestion>?,answers: freezed == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, JsonMap>?,
  ));
}


}

ResponsePart _$ResponsePartFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'markdown':
          return MarkdownPart.fromJson(
            json
          );
                case 'reasoning':
          return ReasoningPart.fromJson(
            json
          );
                case 'toolCall':
          return ToolCallPart.fromJson(
            json
          );
                case 'inputRequest':
          return InputRequestPart.fromJson(
            json
          );
                case 'error':
          return ErrorPart.fromJson(
            json
          );
                case 'systemNotification':
          return SystemNotificationPart.fromJson(
            json
          );
                case 'contentRef':
          return ContentRefPart.fromJson(
            json
          );
        
          default:
            return UnknownPart.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$ResponsePart {



  /// Serializes this ResponsePart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ResponsePart);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ResponsePart()';
}


}

/// @nodoc
class $ResponsePartCopyWith<$Res>  {
$ResponsePartCopyWith(ResponsePart _, $Res Function(ResponsePart) __);
}


/// Adds pattern-matching-related methods to [ResponsePart].
extension ResponsePartPatterns on ResponsePart {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkdownPart value)?  markdown,TResult Function( ReasoningPart value)?  reasoning,TResult Function( ToolCallPart value)?  toolCall,TResult Function( InputRequestPart value)?  inputRequest,TResult Function( ErrorPart value)?  error,TResult Function( SystemNotificationPart value)?  systemNotification,TResult Function( ContentRefPart value)?  contentRef,TResult Function( UnknownPart value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkdownPart() when markdown != null:
return markdown(_that);case ReasoningPart() when reasoning != null:
return reasoning(_that);case ToolCallPart() when toolCall != null:
return toolCall(_that);case InputRequestPart() when inputRequest != null:
return inputRequest(_that);case ErrorPart() when error != null:
return error(_that);case SystemNotificationPart() when systemNotification != null:
return systemNotification(_that);case ContentRefPart() when contentRef != null:
return contentRef(_that);case UnknownPart() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkdownPart value)  markdown,required TResult Function( ReasoningPart value)  reasoning,required TResult Function( ToolCallPart value)  toolCall,required TResult Function( InputRequestPart value)  inputRequest,required TResult Function( ErrorPart value)  error,required TResult Function( SystemNotificationPart value)  systemNotification,required TResult Function( ContentRefPart value)  contentRef,required TResult Function( UnknownPart value)  unknown,}){
final _that = this;
switch (_that) {
case MarkdownPart():
return markdown(_that);case ReasoningPart():
return reasoning(_that);case ToolCallPart():
return toolCall(_that);case InputRequestPart():
return inputRequest(_that);case ErrorPart():
return error(_that);case SystemNotificationPart():
return systemNotification(_that);case ContentRefPart():
return contentRef(_that);case UnknownPart():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkdownPart value)?  markdown,TResult? Function( ReasoningPart value)?  reasoning,TResult? Function( ToolCallPart value)?  toolCall,TResult? Function( InputRequestPart value)?  inputRequest,TResult? Function( ErrorPart value)?  error,TResult? Function( SystemNotificationPart value)?  systemNotification,TResult? Function( ContentRefPart value)?  contentRef,TResult? Function( UnknownPart value)?  unknown,}){
final _that = this;
switch (_that) {
case MarkdownPart() when markdown != null:
return markdown(_that);case ReasoningPart() when reasoning != null:
return reasoning(_that);case ToolCallPart() when toolCall != null:
return toolCall(_that);case InputRequestPart() when inputRequest != null:
return inputRequest(_that);case ErrorPart() when error != null:
return error(_that);case SystemNotificationPart() when systemNotification != null:
return systemNotification(_that);case ContentRefPart() when contentRef != null:
return contentRef(_that);case UnknownPart() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String content)?  markdown,TResult Function( String id,  String content)?  reasoning,TResult Function( ToolCall toolCall)?  toolCall,TResult Function( ChatInputRequest request,  String? response)?  inputRequest,TResult Function( ErrorInfo error,  bool? resumable)?  error,TResult Function( Object? content)?  systemNotification,TResult Function( String uri,  String? contentType)?  contentRef,TResult Function( String kind)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkdownPart() when markdown != null:
return markdown(_that.id,_that.content);case ReasoningPart() when reasoning != null:
return reasoning(_that.id,_that.content);case ToolCallPart() when toolCall != null:
return toolCall(_that.toolCall);case InputRequestPart() when inputRequest != null:
return inputRequest(_that.request,_that.response);case ErrorPart() when error != null:
return error(_that.error,_that.resumable);case SystemNotificationPart() when systemNotification != null:
return systemNotification(_that.content);case ContentRefPart() when contentRef != null:
return contentRef(_that.uri,_that.contentType);case UnknownPart() when unknown != null:
return unknown(_that.kind);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String content)  markdown,required TResult Function( String id,  String content)  reasoning,required TResult Function( ToolCall toolCall)  toolCall,required TResult Function( ChatInputRequest request,  String? response)  inputRequest,required TResult Function( ErrorInfo error,  bool? resumable)  error,required TResult Function( Object? content)  systemNotification,required TResult Function( String uri,  String? contentType)  contentRef,required TResult Function( String kind)  unknown,}) {final _that = this;
switch (_that) {
case MarkdownPart():
return markdown(_that.id,_that.content);case ReasoningPart():
return reasoning(_that.id,_that.content);case ToolCallPart():
return toolCall(_that.toolCall);case InputRequestPart():
return inputRequest(_that.request,_that.response);case ErrorPart():
return error(_that.error,_that.resumable);case SystemNotificationPart():
return systemNotification(_that.content);case ContentRefPart():
return contentRef(_that.uri,_that.contentType);case UnknownPart():
return unknown(_that.kind);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String content)?  markdown,TResult? Function( String id,  String content)?  reasoning,TResult? Function( ToolCall toolCall)?  toolCall,TResult? Function( ChatInputRequest request,  String? response)?  inputRequest,TResult? Function( ErrorInfo error,  bool? resumable)?  error,TResult? Function( Object? content)?  systemNotification,TResult? Function( String uri,  String? contentType)?  contentRef,TResult? Function( String kind)?  unknown,}) {final _that = this;
switch (_that) {
case MarkdownPart() when markdown != null:
return markdown(_that.id,_that.content);case ReasoningPart() when reasoning != null:
return reasoning(_that.id,_that.content);case ToolCallPart() when toolCall != null:
return toolCall(_that.toolCall);case InputRequestPart() when inputRequest != null:
return inputRequest(_that.request,_that.response);case ErrorPart() when error != null:
return error(_that.error,_that.resumable);case SystemNotificationPart() when systemNotification != null:
return systemNotification(_that.content);case ContentRefPart() when contentRef != null:
return contentRef(_that.uri,_that.contentType);case UnknownPart() when unknown != null:
return unknown(_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class MarkdownPart implements ResponsePart {
  const MarkdownPart({required this.id, required this.content,  String? $type}): $type = $type ?? 'markdown';
  factory MarkdownPart.fromJson(Map<String, dynamic> json) => _$MarkdownPartFromJson(json);

/// Part ID, addressed by `chat/delta`.
 final  String id;
/// Markdown text so far.
 final  String content;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkdownPartCopyWith<MarkdownPart> get copyWith => _$MarkdownPartCopyWithImpl<MarkdownPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarkdownPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkdownPart&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,content);
}

@override
String toString() {
    return 'ResponsePart.markdown(id: $id, content: $content)';
}


}

/// @nodoc
abstract mixin class $MarkdownPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $MarkdownPartCopyWith(MarkdownPart value, $Res Function(MarkdownPart) _then) = _$MarkdownPartCopyWithImpl;
@useResult
$Res call({
 String id, String content
});




}
/// @nodoc
class _$MarkdownPartCopyWithImpl<$Res>
    implements $MarkdownPartCopyWith<$Res> {
  _$MarkdownPartCopyWithImpl(this._self, this._then);

  final MarkdownPart _self;
  final $Res Function(MarkdownPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,}) {
  return _then(MarkdownPart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ReasoningPart implements ResponsePart {
  const ReasoningPart({required this.id, required this.content,  String? $type}): $type = $type ?? 'reasoning';
  factory ReasoningPart.fromJson(Map<String, dynamic> json) => _$ReasoningPartFromJson(json);

/// Part ID, addressed by `chat/reasoning`.
 final  String id;
/// Reasoning text so far.
 final  String content;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReasoningPartCopyWith<ReasoningPart> get copyWith => _$ReasoningPartCopyWithImpl<ReasoningPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReasoningPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReasoningPart&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,content);
}

@override
String toString() {
    return 'ResponsePart.reasoning(id: $id, content: $content)';
}


}

/// @nodoc
abstract mixin class $ReasoningPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $ReasoningPartCopyWith(ReasoningPart value, $Res Function(ReasoningPart) _then) = _$ReasoningPartCopyWithImpl;
@useResult
$Res call({
 String id, String content
});




}
/// @nodoc
class _$ReasoningPartCopyWithImpl<$Res>
    implements $ReasoningPartCopyWith<$Res> {
  _$ReasoningPartCopyWithImpl(this._self, this._then);

  final ReasoningPart _self;
  final $Res Function(ReasoningPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,}) {
  return _then(ReasoningPart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ToolCallPart implements ResponsePart {
  const ToolCallPart({required this.toolCall,  String? $type}): $type = $type ?? 'toolCall';
  factory ToolCallPart.fromJson(Map<String, dynamic> json) => _$ToolCallPartFromJson(json);

/// The tool call's state.
 final  ToolCall toolCall;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCallPartCopyWith<ToolCallPart> get copyWith => _$ToolCallPartCopyWithImpl<ToolCallPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ToolCallPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCallPart&&(identical(other.toolCall, toolCall) || other.toolCall == toolCall));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,toolCall);
}

@override
String toString() {
    return 'ResponsePart.toolCall(toolCall: $toolCall)';
}


}

/// @nodoc
abstract mixin class $ToolCallPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $ToolCallPartCopyWith(ToolCallPart value, $Res Function(ToolCallPart) _then) = _$ToolCallPartCopyWithImpl;
@useResult
$Res call({
 ToolCall toolCall
});


$ToolCallCopyWith<$Res> get toolCall;

}
/// @nodoc
class _$ToolCallPartCopyWithImpl<$Res>
    implements $ToolCallPartCopyWith<$Res> {
  _$ToolCallPartCopyWithImpl(this._self, this._then);

  final ToolCallPart _self;
  final $Res Function(ToolCallPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? toolCall = null,}) {
  return _then(ToolCallPart(
toolCall: null == toolCall ? _self.toolCall : toolCall // ignore: cast_nullable_to_non_nullable
as ToolCall,
  ));
}

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ToolCallCopyWith<$Res> get toolCall {
  
  return $ToolCallCopyWith<$Res>(_self.toolCall, (value) {
    return _then(_self.copyWith(toolCall: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class InputRequestPart implements ResponsePart {
  const InputRequestPart({required this.request, this.response,  String? $type}): $type = $type ?? 'inputRequest';
  factory InputRequestPart.fromJson(Map<String, dynamic> json) => _$InputRequestPartFromJson(json);

/// The request.
 final  ChatInputRequest request;
/// `accept`, `decline` or `cancel` once answered.
 final  String? response;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputRequestPartCopyWith<InputRequestPart> get copyWith => _$InputRequestPartCopyWithImpl<InputRequestPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InputRequestPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InputRequestPart&&(identical(other.request, request) || other.request == request)&&(identical(other.response, response) || other.response == response));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,request,response);
}

@override
String toString() {
    return 'ResponsePart.inputRequest(request: $request, response: $response)';
}


}

/// @nodoc
abstract mixin class $InputRequestPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $InputRequestPartCopyWith(InputRequestPart value, $Res Function(InputRequestPart) _then) = _$InputRequestPartCopyWithImpl;
@useResult
$Res call({
 ChatInputRequest request, String? response
});


$ChatInputRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$InputRequestPartCopyWithImpl<$Res>
    implements $InputRequestPartCopyWith<$Res> {
  _$InputRequestPartCopyWithImpl(this._self, this._then);

  final InputRequestPart _self;
  final $Res Function(InputRequestPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,Object? response = freezed,}) {
  return _then(InputRequestPart(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ChatInputRequest,response: freezed == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatInputRequestCopyWith<$Res> get request {
  
  return $ChatInputRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ErrorPart implements ResponsePart {
  const ErrorPart({required this.error, this.resumable,  String? $type}): $type = $type ?? 'error';
  factory ErrorPart.fromJson(Map<String, dynamic> json) => _$ErrorPartFromJson(json);

/// The error.
 final  ErrorInfo error;
/// Whether `chat/turnResume` can continue the turn.
 final  bool? resumable;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorPartCopyWith<ErrorPart> get copyWith => _$ErrorPartCopyWithImpl<ErrorPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorPart&&(identical(other.error, error) || other.error == error)&&(identical(other.resumable, resumable) || other.resumable == resumable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,error,resumable);
}

@override
String toString() {
    return 'ResponsePart.error(error: $error, resumable: $resumable)';
}


}

/// @nodoc
abstract mixin class $ErrorPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $ErrorPartCopyWith(ErrorPart value, $Res Function(ErrorPart) _then) = _$ErrorPartCopyWithImpl;
@useResult
$Res call({
 ErrorInfo error, bool? resumable
});


$ErrorInfoCopyWith<$Res> get error;

}
/// @nodoc
class _$ErrorPartCopyWithImpl<$Res>
    implements $ErrorPartCopyWith<$Res> {
  _$ErrorPartCopyWithImpl(this._self, this._then);

  final ErrorPart _self;
  final $Res Function(ErrorPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? resumable = freezed,}) {
  return _then(ErrorPart(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ErrorInfo,resumable: freezed == resumable ? _self.resumable : resumable // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorInfoCopyWith<$Res> get error {
  
  return $ErrorInfoCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class SystemNotificationPart implements ResponsePart {
  const SystemNotificationPart({this.content,  String? $type}): $type = $type ?? 'systemNotification';
  factory SystemNotificationPart.fromJson(Map<String, dynamic> json) => _$SystemNotificationPartFromJson(json);

/// `StringOrMarkdown` content.
 final  Object? content;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemNotificationPartCopyWith<SystemNotificationPart> get copyWith => _$SystemNotificationPartCopyWithImpl<SystemNotificationPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemNotificationPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemNotificationPart&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(content));
}

@override
String toString() {
    return 'ResponsePart.systemNotification(content: $content)';
}


}

/// @nodoc
abstract mixin class $SystemNotificationPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $SystemNotificationPartCopyWith(SystemNotificationPart value, $Res Function(SystemNotificationPart) _then) = _$SystemNotificationPartCopyWithImpl;
@useResult
$Res call({
 Object? content
});




}
/// @nodoc
class _$SystemNotificationPartCopyWithImpl<$Res>
    implements $SystemNotificationPartCopyWith<$Res> {
  _$SystemNotificationPartCopyWithImpl(this._self, this._then);

  final SystemNotificationPart _self;
  final $Res Function(SystemNotificationPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? content = freezed,}) {
  return _then(SystemNotificationPart(
content: freezed == content ? _self.content : content ,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ContentRefPart implements ResponsePart {
  const ContentRefPart({required this.uri, this.contentType,  String? $type}): $type = $type ?? 'contentRef';
  factory ContentRefPart.fromJson(Map<String, dynamic> json) => _$ContentRefPartFromJson(json);

/// Content URI.
 final  String uri;
/// MIME type.
 final  String? contentType;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentRefPartCopyWith<ContentRefPart> get copyWith => _$ContentRefPartCopyWithImpl<ContentRefPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentRefPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ContentRefPart&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.contentType, contentType) || other.contentType == contentType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uri,contentType);
}

@override
String toString() {
    return 'ResponsePart.contentRef(uri: $uri, contentType: $contentType)';
}


}

/// @nodoc
abstract mixin class $ContentRefPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $ContentRefPartCopyWith(ContentRefPart value, $Res Function(ContentRefPart) _then) = _$ContentRefPartCopyWithImpl;
@useResult
$Res call({
 String uri, String? contentType
});




}
/// @nodoc
class _$ContentRefPartCopyWithImpl<$Res>
    implements $ContentRefPartCopyWith<$Res> {
  _$ContentRefPartCopyWithImpl(this._self, this._then);

  final ContentRefPart _self;
  final $Res Function(ContentRefPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? contentType = freezed,}) {
  return _then(ContentRefPart(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,contentType: freezed == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UnknownPart implements ResponsePart {
  const UnknownPart({required this.kind});
  factory UnknownPart.fromJson(Map<String, dynamic> json) => _$UnknownPartFromJson(json);

/// The part's `kind`.
 final  String kind;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownPartCopyWith<UnknownPart> get copyWith => _$UnknownPartCopyWithImpl<UnknownPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnknownPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownPart&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind);
}

@override
String toString() {
    return 'ResponsePart.unknown(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $UnknownPartCopyWith<$Res> implements $ResponsePartCopyWith<$Res> {
  factory $UnknownPartCopyWith(UnknownPart value, $Res Function(UnknownPart) _then) = _$UnknownPartCopyWithImpl;
@useResult
$Res call({
 String kind
});




}
/// @nodoc
class _$UnknownPartCopyWithImpl<$Res>
    implements $UnknownPartCopyWith<$Res> {
  _$UnknownPartCopyWithImpl(this._self, this._then);

  final UnknownPart _self;
  final $Res Function(UnknownPart) _then;

/// Create a copy of ResponsePart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(UnknownPart(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Turn {

/// Turn ID.
 String get id;/// The message that started the turn.
 Message get message;/// Response parts in order.
 List<ResponsePart> get responseParts;/// How the turn ended.
 TurnState get state;/// Start time (ISO 8601).
 String? get startedAt;/// Duration in milliseconds.
 int? get duration;/// Token usage.
 UsageInfo? get usage;
/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnCopyWith<Turn> get copyWith => _$TurnCopyWithImpl<Turn>(this as Turn, _$identity);

  /// Serializes this Turn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Turn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Turn&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.message, _this.message) || other.message == _this.message)&&const DeepCollectionEquality().equals(other.responseParts, _this.responseParts)&&(identical(other.state, _this.state) || other.state == _this.state)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.usage, _this.usage) || other.usage == _this.usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Turn;
  return Object.hash(runtimeType,_this.id,_this.message,const DeepCollectionEquality().hash(_this.responseParts),_this.state,_this.startedAt,_this.duration,_this.usage);
}

@override
String toString() {
  final _this = this as Turn;
  return 'Turn(id: ${_this.id}, message: ${_this.message}, responseParts: ${_this.responseParts}, state: ${_this.state}, startedAt: ${_this.startedAt}, duration: ${_this.duration}, usage: ${_this.usage})';
}


}

/// @nodoc
abstract mixin class $TurnCopyWith<$Res>  {
  factory $TurnCopyWith(Turn value, $Res Function(Turn) _then) = _$TurnCopyWithImpl;
@useResult
$Res call({
 String id, Message message, List<ResponsePart> responseParts, TurnState state, String? startedAt, int? duration, UsageInfo? usage
});


$MessageCopyWith<$Res> get message;$UsageInfoCopyWith<$Res>? get usage;

}
/// @nodoc
class _$TurnCopyWithImpl<$Res>
    implements $TurnCopyWith<$Res> {
  _$TurnCopyWithImpl(this._self, this._then);

  final Turn _self;
  final $Res Function(Turn) _then;

/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? responseParts = null,Object? state = null,Object? startedAt = freezed,Object? duration = freezed,Object? usage = freezed,}) {
  return _then(Turn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,responseParts: null == responseParts ? _self.responseParts : responseParts // ignore: cast_nullable_to_non_nullable
as List<ResponsePart>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TurnState,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}
/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [Turn].
extension TurnPatterns on Turn {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Turn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Turn() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Turn value)  $default,){
final _that = this;
switch (_that) {
case _Turn():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Turn value)?  $default,){
final _that = this;
switch (_that) {
case _Turn() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Message message,  List<ResponsePart> responseParts,  TurnState state,  String? startedAt,  int? duration,  UsageInfo? usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Turn() when $default != null:
return $default(_that.id,_that.message,_that.responseParts,_that.state,_that.startedAt,_that.duration,_that.usage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Message message,  List<ResponsePart> responseParts,  TurnState state,  String? startedAt,  int? duration,  UsageInfo? usage)  $default,) {final _that = this;
switch (_that) {
case _Turn():
return $default(_that.id,_that.message,_that.responseParts,_that.state,_that.startedAt,_that.duration,_that.usage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Message message,  List<ResponsePart> responseParts,  TurnState state,  String? startedAt,  int? duration,  UsageInfo? usage)?  $default,) {final _that = this;
switch (_that) {
case _Turn() when $default != null:
return $default(_that.id,_that.message,_that.responseParts,_that.state,_that.startedAt,_that.duration,_that.usage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Turn implements Turn {
  const _Turn({required this.id, required this.message, required  List<ResponsePart> responseParts, required this.state, this.startedAt, this.duration, this.usage}): _responseParts = responseParts;
  factory _Turn.fromJson(Map<String, dynamic> json) => _$TurnFromJson(json);

/// Turn ID.
@override final  String id;
/// The message that started the turn.
@override final  Message message;
/// Response parts in order.
 final  List<ResponsePart> _responseParts;
/// Response parts in order.
@override List<ResponsePart> get responseParts {
  if (_responseParts is EqualUnmodifiableListView) return _responseParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_responseParts);
}

/// How the turn ended.
@override final  TurnState state;
/// Start time (ISO 8601).
@override final  String? startedAt;
/// Duration in milliseconds.
@override final  int? duration;
/// Token usage.
@override final  UsageInfo? usage;

/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnCopyWith<_Turn> get copyWith => __$TurnCopyWithImpl<_Turn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TurnToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Turn&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.responseParts, _responseParts)&&(identical(other.state, state) || other.state == state)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,message,const DeepCollectionEquality().hash(_responseParts),state,startedAt,duration,usage);
}

@override
String toString() {
    return 'Turn(id: $id, message: $message, responseParts: $responseParts, state: $state, startedAt: $startedAt, duration: $duration, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$TurnCopyWith<$Res> implements $TurnCopyWith<$Res> {
  factory _$TurnCopyWith(_Turn value, $Res Function(_Turn) _then) = __$TurnCopyWithImpl;
@override @useResult
$Res call({
 String id, Message message, List<ResponsePart> responseParts, TurnState state, String? startedAt, int? duration, UsageInfo? usage
});


@override $MessageCopyWith<$Res> get message;@override $UsageInfoCopyWith<$Res>? get usage;

}
/// @nodoc
class __$TurnCopyWithImpl<$Res>
    implements _$TurnCopyWith<$Res> {
  __$TurnCopyWithImpl(this._self, this._then);

  final _Turn _self;
  final $Res Function(_Turn) _then;

/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? responseParts = null,Object? state = null,Object? startedAt = freezed,Object? duration = freezed,Object? usage = freezed,}) {
  return _then(_Turn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,responseParts: null == responseParts ? _self._responseParts : responseParts // ignore: cast_nullable_to_non_nullable
as List<ResponsePart>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as TurnState,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,duration: freezed == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int?,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}

/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of Turn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// @nodoc
mixin _$ActiveTurn {

/// Turn ID.
 String get id;/// Start time (ISO 8601).
 String get startedAt;/// The message that started the turn.
 Message get message;/// Response parts so far.
 List<ResponsePart> get responseParts;/// Token usage so far.
 UsageInfo? get usage;
/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveTurnCopyWith<ActiveTurn> get copyWith => _$ActiveTurnCopyWithImpl<ActiveTurn>(this as ActiveTurn, _$identity);

  /// Serializes this ActiveTurn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActiveTurn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveTurn&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.message, _this.message) || other.message == _this.message)&&const DeepCollectionEquality().equals(other.responseParts, _this.responseParts)&&(identical(other.usage, _this.usage) || other.usage == _this.usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActiveTurn;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.message,const DeepCollectionEquality().hash(_this.responseParts),_this.usage);
}

@override
String toString() {
  final _this = this as ActiveTurn;
  return 'ActiveTurn(id: ${_this.id}, startedAt: ${_this.startedAt}, message: ${_this.message}, responseParts: ${_this.responseParts}, usage: ${_this.usage})';
}


}

/// @nodoc
abstract mixin class $ActiveTurnCopyWith<$Res>  {
  factory $ActiveTurnCopyWith(ActiveTurn value, $Res Function(ActiveTurn) _then) = _$ActiveTurnCopyWithImpl;
@useResult
$Res call({
 String id, String startedAt, Message message, List<ResponsePart> responseParts, UsageInfo? usage
});


$MessageCopyWith<$Res> get message;$UsageInfoCopyWith<$Res>? get usage;

}
/// @nodoc
class _$ActiveTurnCopyWithImpl<$Res>
    implements $ActiveTurnCopyWith<$Res> {
  _$ActiveTurnCopyWithImpl(this._self, this._then);

  final ActiveTurn _self;
  final $Res Function(ActiveTurn) _then;

/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? message = null,Object? responseParts = null,Object? usage = freezed,}) {
  return _then(ActiveTurn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,responseParts: null == responseParts ? _self.responseParts : responseParts // ignore: cast_nullable_to_non_nullable
as List<ResponsePart>,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}
/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveTurn].
extension ActiveTurnPatterns on ActiveTurn {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveTurn() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveTurn value)  $default,){
final _that = this;
switch (_that) {
case _ActiveTurn():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveTurn value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveTurn() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String startedAt,  Message message,  List<ResponsePart> responseParts,  UsageInfo? usage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveTurn() when $default != null:
return $default(_that.id,_that.startedAt,_that.message,_that.responseParts,_that.usage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String startedAt,  Message message,  List<ResponsePart> responseParts,  UsageInfo? usage)  $default,) {final _that = this;
switch (_that) {
case _ActiveTurn():
return $default(_that.id,_that.startedAt,_that.message,_that.responseParts,_that.usage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String startedAt,  Message message,  List<ResponsePart> responseParts,  UsageInfo? usage)?  $default,) {final _that = this;
switch (_that) {
case _ActiveTurn() when $default != null:
return $default(_that.id,_that.startedAt,_that.message,_that.responseParts,_that.usage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActiveTurn implements ActiveTurn {
  const _ActiveTurn({required this.id, required this.startedAt, required this.message, required  List<ResponsePart> responseParts, this.usage}): _responseParts = responseParts;
  factory _ActiveTurn.fromJson(Map<String, dynamic> json) => _$ActiveTurnFromJson(json);

/// Turn ID.
@override final  String id;
/// Start time (ISO 8601).
@override final  String startedAt;
/// The message that started the turn.
@override final  Message message;
/// Response parts so far.
 final  List<ResponsePart> _responseParts;
/// Response parts so far.
@override List<ResponsePart> get responseParts {
  if (_responseParts is EqualUnmodifiableListView) return _responseParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_responseParts);
}

/// Token usage so far.
@override final  UsageInfo? usage;

/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveTurnCopyWith<_ActiveTurn> get copyWith => __$ActiveTurnCopyWithImpl<_ActiveTurn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActiveTurnToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveTurn&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.responseParts, _responseParts)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,startedAt,message,const DeepCollectionEquality().hash(_responseParts),usage);
}

@override
String toString() {
    return 'ActiveTurn(id: $id, startedAt: $startedAt, message: $message, responseParts: $responseParts, usage: $usage)';
}


}

/// @nodoc
abstract mixin class _$ActiveTurnCopyWith<$Res> implements $ActiveTurnCopyWith<$Res> {
  factory _$ActiveTurnCopyWith(_ActiveTurn value, $Res Function(_ActiveTurn) _then) = __$ActiveTurnCopyWithImpl;
@override @useResult
$Res call({
 String id, String startedAt, Message message, List<ResponsePart> responseParts, UsageInfo? usage
});


@override $MessageCopyWith<$Res> get message;@override $UsageInfoCopyWith<$Res>? get usage;

}
/// @nodoc
class __$ActiveTurnCopyWithImpl<$Res>
    implements _$ActiveTurnCopyWith<$Res> {
  __$ActiveTurnCopyWithImpl(this._self, this._then);

  final _ActiveTurn _self;
  final $Res Function(_ActiveTurn) _then;

/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? message = null,Object? responseParts = null,Object? usage = freezed,}) {
  return _then(_ActiveTurn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,responseParts: null == responseParts ? _self._responseParts : responseParts // ignore: cast_nullable_to_non_nullable
as List<ResponsePart>,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as UsageInfo?,
  ));
}

/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ActiveTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageInfoCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// @nodoc
mixin _$PendingMessage {

/// Pending message ID.
 String get id;/// The message.
 Message get message;
/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingMessageCopyWith<PendingMessage> get copyWith => _$PendingMessageCopyWithImpl<PendingMessage>(this as PendingMessage, _$identity);

  /// Serializes this PendingMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PendingMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingMessage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.message, _this.message) || other.message == _this.message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PendingMessage;
  return Object.hash(runtimeType,_this.id,_this.message);
}

@override
String toString() {
  final _this = this as PendingMessage;
  return 'PendingMessage(id: ${_this.id}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $PendingMessageCopyWith<$Res>  {
  factory $PendingMessageCopyWith(PendingMessage value, $Res Function(PendingMessage) _then) = _$PendingMessageCopyWithImpl;
@useResult
$Res call({
 String id, Message message
});


$MessageCopyWith<$Res> get message;

}
/// @nodoc
class _$PendingMessageCopyWithImpl<$Res>
    implements $PendingMessageCopyWith<$Res> {
  _$PendingMessageCopyWithImpl(this._self, this._then);

  final PendingMessage _self;
  final $Res Function(PendingMessage) _then;

/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,}) {
  return _then(PendingMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,
  ));
}
/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingMessage].
extension PendingMessagePatterns on PendingMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingMessage value)  $default,){
final _that = this;
switch (_that) {
case _PendingMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingMessage value)?  $default,){
final _that = this;
switch (_that) {
case _PendingMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Message message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingMessage() when $default != null:
return $default(_that.id,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Message message)  $default,) {final _that = this;
switch (_that) {
case _PendingMessage():
return $default(_that.id,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Message message)?  $default,) {final _that = this;
switch (_that) {
case _PendingMessage() when $default != null:
return $default(_that.id,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingMessage implements PendingMessage {
  const _PendingMessage({required this.id, required this.message});
  factory _PendingMessage.fromJson(Map<String, dynamic> json) => _$PendingMessageFromJson(json);

/// Pending message ID.
@override final  String id;
/// The message.
@override final  Message message;

/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingMessageCopyWith<_PendingMessage> get copyWith => __$PendingMessageCopyWithImpl<_PendingMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,message);
}

@override
String toString() {
    return 'PendingMessage(id: $id, message: $message)';
}


}

/// @nodoc
abstract mixin class _$PendingMessageCopyWith<$Res> implements $PendingMessageCopyWith<$Res> {
  factory _$PendingMessageCopyWith(_PendingMessage value, $Res Function(_PendingMessage) _then) = __$PendingMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, Message message
});


@override $MessageCopyWith<$Res> get message;

}
/// @nodoc
class __$PendingMessageCopyWithImpl<$Res>
    implements _$PendingMessageCopyWith<$Res> {
  __$PendingMessageCopyWithImpl(this._self, this._then);

  final _PendingMessage _self;
  final $Res Function(_PendingMessage) _then;

/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,}) {
  return _then(_PendingMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,
  ));
}

/// Create a copy of PendingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// @nodoc
mixin _$ChatState {

/// Chat URI.
 String get resource;/// Chat title.
 String get title;/// Chat status bitset.
@SessionStatusConverter() SessionStatus get status;/// Last modification time (ISO 8601).
 String get modifiedAt;/// Finished turns, oldest first.
 List<Turn> get turns;/// What the chat is doing, e.g. `Running ls`.
 String? get activity;/// The running turn.
 ActiveTurn? get activeTurn;/// Cursor for `fetchTurns`; absent when all turns are loaded.
 String? get turnsNextCursor;/// A message delivered to the agent at its next step.
 PendingMessage? get steeringMessage;/// Messages that start turns after the current one, in order.
 List<PendingMessage>? get queuedMessages;/// Working directory URIs.
 List<String>? get workingDirectories;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);

  /// Serializes this ChatState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.modifiedAt, _this.modifiedAt) || other.modifiedAt == _this.modifiedAt)&&const DeepCollectionEquality().equals(other.turns, _this.turns)&&(identical(other.activity, _this.activity) || other.activity == _this.activity)&&(identical(other.activeTurn, _this.activeTurn) || other.activeTurn == _this.activeTurn)&&(identical(other.turnsNextCursor, _this.turnsNextCursor) || other.turnsNextCursor == _this.turnsNextCursor)&&(identical(other.steeringMessage, _this.steeringMessage) || other.steeringMessage == _this.steeringMessage)&&const DeepCollectionEquality().equals(other.queuedMessages, _this.queuedMessages)&&const DeepCollectionEquality().equals(other.workingDirectories, _this.workingDirectories)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatState;
  return Object.hash(runtimeType,_this.resource,_this.title,_this.status,_this.modifiedAt,const DeepCollectionEquality().hash(_this.turns),_this.activity,_this.activeTurn,_this.turnsNextCursor,_this.steeringMessage,const DeepCollectionEquality().hash(_this.queuedMessages),const DeepCollectionEquality().hash(_this.workingDirectories),const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as ChatState;
  return 'ChatState(resource: ${_this.resource}, title: ${_this.title}, status: ${_this.status}, modifiedAt: ${_this.modifiedAt}, turns: ${_this.turns}, activity: ${_this.activity}, activeTurn: ${_this.activeTurn}, turnsNextCursor: ${_this.turnsNextCursor}, steeringMessage: ${_this.steeringMessage}, queuedMessages: ${_this.queuedMessages}, workingDirectories: ${_this.workingDirectories}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 String resource, String title,@SessionStatusConverter() SessionStatus status, String modifiedAt, List<Turn> turns, String? activity, ActiveTurn? activeTurn, String? turnsNextCursor, PendingMessage? steeringMessage, List<PendingMessage>? queuedMessages, List<String>? workingDirectories,@JsonKey(name: '_meta') JsonMap? meta
});


$ActiveTurnCopyWith<$Res>? get activeTurn;$PendingMessageCopyWith<$Res>? get steeringMessage;

}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? title = null,Object? status = null,Object? modifiedAt = null,Object? turns = null,Object? activity = freezed,Object? activeTurn = freezed,Object? turnsNextCursor = freezed,Object? steeringMessage = freezed,Object? queuedMessages = freezed,Object? workingDirectories = freezed,Object? meta = freezed,}) {
  return _then(ChatState(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as String,turns: null == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
as List<Turn>,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,activeTurn: freezed == activeTurn ? _self.activeTurn : activeTurn // ignore: cast_nullable_to_non_nullable
as ActiveTurn?,turnsNextCursor: freezed == turnsNextCursor ? _self.turnsNextCursor : turnsNextCursor // ignore: cast_nullable_to_non_nullable
as String?,steeringMessage: freezed == steeringMessage ? _self.steeringMessage : steeringMessage // ignore: cast_nullable_to_non_nullable
as PendingMessage?,queuedMessages: freezed == queuedMessages ? _self.queuedMessages : queuedMessages // ignore: cast_nullable_to_non_nullable
as List<PendingMessage>?,workingDirectories: freezed == workingDirectories ? _self.workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveTurnCopyWith<$Res>? get activeTurn {
    if (_self.activeTurn == null) {
    return null;
  }

  return $ActiveTurnCopyWith<$Res>(_self.activeTurn!, (value) {
    return _then(_self.copyWith(activeTurn: value));
  });
}/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingMessageCopyWith<$Res>? get steeringMessage {
    if (_self.steeringMessage == null) {
    return null;
  }

  return $PendingMessageCopyWith<$Res>(_self.steeringMessage!, (value) {
    return _then(_self.copyWith(steeringMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resource,  String title, @SessionStatusConverter()  SessionStatus status,  String modifiedAt,  List<Turn> turns,  String? activity,  ActiveTurn? activeTurn,  String? turnsNextCursor,  PendingMessage? steeringMessage,  List<PendingMessage>? queuedMessages,  List<String>? workingDirectories, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.resource,_that.title,_that.status,_that.modifiedAt,_that.turns,_that.activity,_that.activeTurn,_that.turnsNextCursor,_that.steeringMessage,_that.queuedMessages,_that.workingDirectories,_that.meta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resource,  String title, @SessionStatusConverter()  SessionStatus status,  String modifiedAt,  List<Turn> turns,  String? activity,  ActiveTurn? activeTurn,  String? turnsNextCursor,  PendingMessage? steeringMessage,  List<PendingMessage>? queuedMessages,  List<String>? workingDirectories, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.resource,_that.title,_that.status,_that.modifiedAt,_that.turns,_that.activity,_that.activeTurn,_that.turnsNextCursor,_that.steeringMessage,_that.queuedMessages,_that.workingDirectories,_that.meta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resource,  String title, @SessionStatusConverter()  SessionStatus status,  String modifiedAt,  List<Turn> turns,  String? activity,  ActiveTurn? activeTurn,  String? turnsNextCursor,  PendingMessage? steeringMessage,  List<PendingMessage>? queuedMessages,  List<String>? workingDirectories, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.resource,_that.title,_that.status,_that.modifiedAt,_that.turns,_that.activity,_that.activeTurn,_that.turnsNextCursor,_that.steeringMessage,_that.queuedMessages,_that.workingDirectories,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatState implements ChatState {
  const _ChatState({required this.resource, required this.title, @SessionStatusConverter() required this.status, required this.modifiedAt,  List<Turn> turns = const <Turn>[], this.activity, this.activeTurn, this.turnsNextCursor, this.steeringMessage,  List<PendingMessage>? queuedMessages,  List<String>? workingDirectories, @JsonKey(name: '_meta')  JsonMap? meta}): _turns = turns,_queuedMessages = queuedMessages,_workingDirectories = workingDirectories,_meta = meta;
  factory _ChatState.fromJson(Map<String, dynamic> json) => _$ChatStateFromJson(json);

/// Chat URI.
@override final  String resource;
/// Chat title.
@override final  String title;
/// Chat status bitset.
@override@SessionStatusConverter() final  SessionStatus status;
/// Last modification time (ISO 8601).
@override final  String modifiedAt;
/// Finished turns, oldest first.
 final  List<Turn> _turns;
/// Finished turns, oldest first.
@override@JsonKey() List<Turn> get turns {
  if (_turns is EqualUnmodifiableListView) return _turns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_turns);
}

/// What the chat is doing, e.g. `Running ls`.
@override final  String? activity;
/// The running turn.
@override final  ActiveTurn? activeTurn;
/// Cursor for `fetchTurns`; absent when all turns are loaded.
@override final  String? turnsNextCursor;
/// A message delivered to the agent at its next step.
@override final  PendingMessage? steeringMessage;
/// Messages that start turns after the current one, in order.
 final  List<PendingMessage>? _queuedMessages;
/// Messages that start turns after the current one, in order.
@override List<PendingMessage>? get queuedMessages {
  final value = _queuedMessages;
  if (value == null) return null;
  if (_queuedMessages is EqualUnmodifiableListView) return _queuedMessages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Working directory URIs.
 final  List<String>? _workingDirectories;
/// Working directory URIs.
@override List<String>? get workingDirectories {
  final value = _workingDirectories;
  if (value == null) return null;
  if (_workingDirectories is EqualUnmodifiableListView) return _workingDirectories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@override@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&const DeepCollectionEquality().equals(other.turns, _turns)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.activeTurn, activeTurn) || other.activeTurn == activeTurn)&&(identical(other.turnsNextCursor, turnsNextCursor) || other.turnsNextCursor == turnsNextCursor)&&(identical(other.steeringMessage, steeringMessage) || other.steeringMessage == steeringMessage)&&const DeepCollectionEquality().equals(other.queuedMessages, _queuedMessages)&&const DeepCollectionEquality().equals(other.workingDirectories, _workingDirectories)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,resource,title,status,modifiedAt,const DeepCollectionEquality().hash(_turns),activity,activeTurn,turnsNextCursor,steeringMessage,const DeepCollectionEquality().hash(_queuedMessages),const DeepCollectionEquality().hash(_workingDirectories),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatState(resource: $resource, title: $title, status: $status, modifiedAt: $modifiedAt, turns: $turns, activity: $activity, activeTurn: $activeTurn, turnsNextCursor: $turnsNextCursor, steeringMessage: $steeringMessage, queuedMessages: $queuedMessages, workingDirectories: $workingDirectories, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 String resource, String title,@SessionStatusConverter() SessionStatus status, String modifiedAt, List<Turn> turns, String? activity, ActiveTurn? activeTurn, String? turnsNextCursor, PendingMessage? steeringMessage, List<PendingMessage>? queuedMessages, List<String>? workingDirectories,@JsonKey(name: '_meta') JsonMap? meta
});


@override $ActiveTurnCopyWith<$Res>? get activeTurn;@override $PendingMessageCopyWith<$Res>? get steeringMessage;

}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? title = null,Object? status = null,Object? modifiedAt = null,Object? turns = null,Object? activity = freezed,Object? activeTurn = freezed,Object? turnsNextCursor = freezed,Object? steeringMessage = freezed,Object? queuedMessages = freezed,Object? workingDirectories = freezed,Object? meta = freezed,}) {
  return _then(_ChatState(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as String,turns: null == turns ? _self._turns : turns // ignore: cast_nullable_to_non_nullable
as List<Turn>,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,activeTurn: freezed == activeTurn ? _self.activeTurn : activeTurn // ignore: cast_nullable_to_non_nullable
as ActiveTurn?,turnsNextCursor: freezed == turnsNextCursor ? _self.turnsNextCursor : turnsNextCursor // ignore: cast_nullable_to_non_nullable
as String?,steeringMessage: freezed == steeringMessage ? _self.steeringMessage : steeringMessage // ignore: cast_nullable_to_non_nullable
as PendingMessage?,queuedMessages: freezed == queuedMessages ? _self._queuedMessages : queuedMessages // ignore: cast_nullable_to_non_nullable
as List<PendingMessage>?,workingDirectories: freezed == workingDirectories ? _self._workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActiveTurnCopyWith<$Res>? get activeTurn {
    if (_self.activeTurn == null) {
    return null;
  }

  return $ActiveTurnCopyWith<$Res>(_self.activeTurn!, (value) {
    return _then(_self.copyWith(activeTurn: value));
  });
}/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingMessageCopyWith<$Res>? get steeringMessage {
    if (_self.steeringMessage == null) {
    return null;
  }

  return $PendingMessageCopyWith<$Res>(_self.steeringMessage!, (value) {
    return _then(_self.copyWith(steeringMessage: value));
  });
}
}

ChatAction _$ChatActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'chat/turnStarted':
          return ChatTurnStarted.fromJson(
            json
          );
                case 'chat/delta':
          return ChatDelta.fromJson(
            json
          );
                case 'chat/reasoning':
          return ChatReasoning.fromJson(
            json
          );
                case 'chat/responsePart':
          return ChatResponsePart.fromJson(
            json
          );
                case 'chat/toolCallStart':
          return ChatToolCallStart.fromJson(
            json
          );
                case 'chat/toolCallDelta':
          return ChatToolCallDelta.fromJson(
            json
          );
                case 'chat/toolCallReady':
          return ChatToolCallReady.fromJson(
            json
          );
                case 'chat/toolCallConfirmed':
          return ChatToolCallConfirmed.fromJson(
            json
          );
                case 'chat/toolCallComplete':
          return ChatToolCallComplete.fromJson(
            json
          );
                case 'chat/toolCallResultConfirmed':
          return ChatToolCallResultConfirmed.fromJson(
            json
          );
                case 'chat/toolCallContentChanged':
          return ChatToolCallContentChanged.fromJson(
            json
          );
                case 'chat/turnComplete':
          return ChatTurnComplete.fromJson(
            json
          );
                case 'chat/turnCancelled':
          return ChatTurnCancelled.fromJson(
            json
          );
                case 'chat/error':
          return ChatError.fromJson(
            json
          );
                case 'chat/turnResume':
          return ChatTurnResume.fromJson(
            json
          );
                case 'chat/activityChanged':
          return ChatActivityChanged.fromJson(
            json
          );
                case 'chat/usage':
          return ChatUsage.fromJson(
            json
          );
                case 'chat/truncated':
          return ChatTruncated.fromJson(
            json
          );
                case 'chat/turnsLoaded':
          return ChatTurnsLoaded.fromJson(
            json
          );
                case 'chat/pendingMessageSet':
          return ChatPendingMessageSet.fromJson(
            json
          );
                case 'chat/pendingMessageRemoved':
          return ChatPendingMessageRemoved.fromJson(
            json
          );
                case 'chat/isReadChanged':
          return ChatIsReadChanged.fromJson(
            json
          );
                case 'chat/isArchivedChanged':
          return ChatIsArchivedChanged.fromJson(
            json
          );
                case 'chat/inputRequested':
          return ChatInputRequested.fromJson(
            json
          );
                case 'chat/inputAnswerChanged':
          return ChatInputAnswerChanged.fromJson(
            json
          );
                case 'chat/inputCompleted':
          return ChatInputCompleted.fromJson(
            json
          );
        
          default:
            return ChatUnknownAction.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$ChatAction {



  /// Serializes this ChatAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatAction);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ChatAction()';
}


}

/// @nodoc
class $ChatActionCopyWith<$Res>  {
$ChatActionCopyWith(ChatAction _, $Res Function(ChatAction) __);
}


/// Adds pattern-matching-related methods to [ChatAction].
extension ChatActionPatterns on ChatAction {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatTurnStarted value)?  turnStarted,TResult Function( ChatDelta value)?  delta,TResult Function( ChatReasoning value)?  reasoning,TResult Function( ChatResponsePart value)?  responsePart,TResult Function( ChatToolCallStart value)?  toolCallStart,TResult Function( ChatToolCallDelta value)?  toolCallDelta,TResult Function( ChatToolCallReady value)?  toolCallReady,TResult Function( ChatToolCallConfirmed value)?  toolCallConfirmed,TResult Function( ChatToolCallComplete value)?  toolCallComplete,TResult Function( ChatToolCallResultConfirmed value)?  toolCallResultConfirmed,TResult Function( ChatToolCallContentChanged value)?  toolCallContentChanged,TResult Function( ChatTurnComplete value)?  turnComplete,TResult Function( ChatTurnCancelled value)?  turnCancelled,TResult Function( ChatError value)?  error,TResult Function( ChatTurnResume value)?  turnResume,TResult Function( ChatActivityChanged value)?  activityChanged,TResult Function( ChatUsage value)?  usage,TResult Function( ChatTruncated value)?  truncated,TResult Function( ChatTurnsLoaded value)?  turnsLoaded,TResult Function( ChatPendingMessageSet value)?  pendingMessageSet,TResult Function( ChatPendingMessageRemoved value)?  pendingMessageRemoved,TResult Function( ChatIsReadChanged value)?  isReadChanged,TResult Function( ChatIsArchivedChanged value)?  isArchivedChanged,TResult Function( ChatInputRequested value)?  inputRequested,TResult Function( ChatInputAnswerChanged value)?  inputAnswerChanged,TResult Function( ChatInputCompleted value)?  inputCompleted,TResult Function( ChatUnknownAction value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatTurnStarted() when turnStarted != null:
return turnStarted(_that);case ChatDelta() when delta != null:
return delta(_that);case ChatReasoning() when reasoning != null:
return reasoning(_that);case ChatResponsePart() when responsePart != null:
return responsePart(_that);case ChatToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case ChatToolCallDelta() when toolCallDelta != null:
return toolCallDelta(_that);case ChatToolCallReady() when toolCallReady != null:
return toolCallReady(_that);case ChatToolCallConfirmed() when toolCallConfirmed != null:
return toolCallConfirmed(_that);case ChatToolCallComplete() when toolCallComplete != null:
return toolCallComplete(_that);case ChatToolCallResultConfirmed() when toolCallResultConfirmed != null:
return toolCallResultConfirmed(_that);case ChatToolCallContentChanged() when toolCallContentChanged != null:
return toolCallContentChanged(_that);case ChatTurnComplete() when turnComplete != null:
return turnComplete(_that);case ChatTurnCancelled() when turnCancelled != null:
return turnCancelled(_that);case ChatError() when error != null:
return error(_that);case ChatTurnResume() when turnResume != null:
return turnResume(_that);case ChatActivityChanged() when activityChanged != null:
return activityChanged(_that);case ChatUsage() when usage != null:
return usage(_that);case ChatTruncated() when truncated != null:
return truncated(_that);case ChatTurnsLoaded() when turnsLoaded != null:
return turnsLoaded(_that);case ChatPendingMessageSet() when pendingMessageSet != null:
return pendingMessageSet(_that);case ChatPendingMessageRemoved() when pendingMessageRemoved != null:
return pendingMessageRemoved(_that);case ChatIsReadChanged() when isReadChanged != null:
return isReadChanged(_that);case ChatIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that);case ChatInputRequested() when inputRequested != null:
return inputRequested(_that);case ChatInputAnswerChanged() when inputAnswerChanged != null:
return inputAnswerChanged(_that);case ChatInputCompleted() when inputCompleted != null:
return inputCompleted(_that);case ChatUnknownAction() when unknown != null:
return unknown(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatTurnStarted value)  turnStarted,required TResult Function( ChatDelta value)  delta,required TResult Function( ChatReasoning value)  reasoning,required TResult Function( ChatResponsePart value)  responsePart,required TResult Function( ChatToolCallStart value)  toolCallStart,required TResult Function( ChatToolCallDelta value)  toolCallDelta,required TResult Function( ChatToolCallReady value)  toolCallReady,required TResult Function( ChatToolCallConfirmed value)  toolCallConfirmed,required TResult Function( ChatToolCallComplete value)  toolCallComplete,required TResult Function( ChatToolCallResultConfirmed value)  toolCallResultConfirmed,required TResult Function( ChatToolCallContentChanged value)  toolCallContentChanged,required TResult Function( ChatTurnComplete value)  turnComplete,required TResult Function( ChatTurnCancelled value)  turnCancelled,required TResult Function( ChatError value)  error,required TResult Function( ChatTurnResume value)  turnResume,required TResult Function( ChatActivityChanged value)  activityChanged,required TResult Function( ChatUsage value)  usage,required TResult Function( ChatTruncated value)  truncated,required TResult Function( ChatTurnsLoaded value)  turnsLoaded,required TResult Function( ChatPendingMessageSet value)  pendingMessageSet,required TResult Function( ChatPendingMessageRemoved value)  pendingMessageRemoved,required TResult Function( ChatIsReadChanged value)  isReadChanged,required TResult Function( ChatIsArchivedChanged value)  isArchivedChanged,required TResult Function( ChatInputRequested value)  inputRequested,required TResult Function( ChatInputAnswerChanged value)  inputAnswerChanged,required TResult Function( ChatInputCompleted value)  inputCompleted,required TResult Function( ChatUnknownAction value)  unknown,}){
final _that = this;
switch (_that) {
case ChatTurnStarted():
return turnStarted(_that);case ChatDelta():
return delta(_that);case ChatReasoning():
return reasoning(_that);case ChatResponsePart():
return responsePart(_that);case ChatToolCallStart():
return toolCallStart(_that);case ChatToolCallDelta():
return toolCallDelta(_that);case ChatToolCallReady():
return toolCallReady(_that);case ChatToolCallConfirmed():
return toolCallConfirmed(_that);case ChatToolCallComplete():
return toolCallComplete(_that);case ChatToolCallResultConfirmed():
return toolCallResultConfirmed(_that);case ChatToolCallContentChanged():
return toolCallContentChanged(_that);case ChatTurnComplete():
return turnComplete(_that);case ChatTurnCancelled():
return turnCancelled(_that);case ChatError():
return error(_that);case ChatTurnResume():
return turnResume(_that);case ChatActivityChanged():
return activityChanged(_that);case ChatUsage():
return usage(_that);case ChatTruncated():
return truncated(_that);case ChatTurnsLoaded():
return turnsLoaded(_that);case ChatPendingMessageSet():
return pendingMessageSet(_that);case ChatPendingMessageRemoved():
return pendingMessageRemoved(_that);case ChatIsReadChanged():
return isReadChanged(_that);case ChatIsArchivedChanged():
return isArchivedChanged(_that);case ChatInputRequested():
return inputRequested(_that);case ChatInputAnswerChanged():
return inputAnswerChanged(_that);case ChatInputCompleted():
return inputCompleted(_that);case ChatUnknownAction():
return unknown(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatTurnStarted value)?  turnStarted,TResult? Function( ChatDelta value)?  delta,TResult? Function( ChatReasoning value)?  reasoning,TResult? Function( ChatResponsePart value)?  responsePart,TResult? Function( ChatToolCallStart value)?  toolCallStart,TResult? Function( ChatToolCallDelta value)?  toolCallDelta,TResult? Function( ChatToolCallReady value)?  toolCallReady,TResult? Function( ChatToolCallConfirmed value)?  toolCallConfirmed,TResult? Function( ChatToolCallComplete value)?  toolCallComplete,TResult? Function( ChatToolCallResultConfirmed value)?  toolCallResultConfirmed,TResult? Function( ChatToolCallContentChanged value)?  toolCallContentChanged,TResult? Function( ChatTurnComplete value)?  turnComplete,TResult? Function( ChatTurnCancelled value)?  turnCancelled,TResult? Function( ChatError value)?  error,TResult? Function( ChatTurnResume value)?  turnResume,TResult? Function( ChatActivityChanged value)?  activityChanged,TResult? Function( ChatUsage value)?  usage,TResult? Function( ChatTruncated value)?  truncated,TResult? Function( ChatTurnsLoaded value)?  turnsLoaded,TResult? Function( ChatPendingMessageSet value)?  pendingMessageSet,TResult? Function( ChatPendingMessageRemoved value)?  pendingMessageRemoved,TResult? Function( ChatIsReadChanged value)?  isReadChanged,TResult? Function( ChatIsArchivedChanged value)?  isArchivedChanged,TResult? Function( ChatInputRequested value)?  inputRequested,TResult? Function( ChatInputAnswerChanged value)?  inputAnswerChanged,TResult? Function( ChatInputCompleted value)?  inputCompleted,TResult? Function( ChatUnknownAction value)?  unknown,}){
final _that = this;
switch (_that) {
case ChatTurnStarted() when turnStarted != null:
return turnStarted(_that);case ChatDelta() when delta != null:
return delta(_that);case ChatReasoning() when reasoning != null:
return reasoning(_that);case ChatResponsePart() when responsePart != null:
return responsePart(_that);case ChatToolCallStart() when toolCallStart != null:
return toolCallStart(_that);case ChatToolCallDelta() when toolCallDelta != null:
return toolCallDelta(_that);case ChatToolCallReady() when toolCallReady != null:
return toolCallReady(_that);case ChatToolCallConfirmed() when toolCallConfirmed != null:
return toolCallConfirmed(_that);case ChatToolCallComplete() when toolCallComplete != null:
return toolCallComplete(_that);case ChatToolCallResultConfirmed() when toolCallResultConfirmed != null:
return toolCallResultConfirmed(_that);case ChatToolCallContentChanged() when toolCallContentChanged != null:
return toolCallContentChanged(_that);case ChatTurnComplete() when turnComplete != null:
return turnComplete(_that);case ChatTurnCancelled() when turnCancelled != null:
return turnCancelled(_that);case ChatError() when error != null:
return error(_that);case ChatTurnResume() when turnResume != null:
return turnResume(_that);case ChatActivityChanged() when activityChanged != null:
return activityChanged(_that);case ChatUsage() when usage != null:
return usage(_that);case ChatTruncated() when truncated != null:
return truncated(_that);case ChatTurnsLoaded() when turnsLoaded != null:
return turnsLoaded(_that);case ChatPendingMessageSet() when pendingMessageSet != null:
return pendingMessageSet(_that);case ChatPendingMessageRemoved() when pendingMessageRemoved != null:
return pendingMessageRemoved(_that);case ChatIsReadChanged() when isReadChanged != null:
return isReadChanged(_that);case ChatIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that);case ChatInputRequested() when inputRequested != null:
return inputRequested(_that);case ChatInputAnswerChanged() when inputAnswerChanged != null:
return inputAnswerChanged(_that);case ChatInputCompleted() when inputCompleted != null:
return inputCompleted(_that);case ChatUnknownAction() when unknown != null:
return unknown(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String turnId,  String startedAt,  Message message,  String? queuedMessageId)?  turnStarted,TResult Function( String turnId,  String partId,  String content)?  delta,TResult Function( String turnId,  String partId,  String content)?  reasoning,TResult Function( String turnId,  ResponsePart part)?  responsePart,TResult Function( String turnId,  String toolCallId,  String toolName,  String displayName,  String? intention,  JsonMap? contributor, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallStart,TResult Function( String turnId,  String toolCallId,  String? content,  Object? invocationMessage, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallDelta,TResult Function( String turnId,  String toolCallId,  Object invocationMessage,  Object? toolInput,  String? intention,  JsonMap? contributor,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  String? confirmed,  List<ConfirmationOption>? options, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallReady,TResult Function( String turnId,  String toolCallId,  bool approved,  String? confirmed,  String? reason,  String? editedToolInput,  String? selectedOptionId,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallConfirmed,TResult Function( String turnId,  String toolCallId,  JsonMap result,  bool? requiresResultConfirmation, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallComplete,TResult Function( String turnId,  String toolCallId,  bool approved, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallResultConfirmed,TResult Function( String turnId,  String toolCallId,  List<JsonMap> content, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallContentChanged,TResult Function( String turnId,  int duration)?  turnComplete,TResult Function( String turnId,  int duration)?  turnCancelled,TResult Function( String turnId,  int duration,  ResponsePart part)?  error,TResult Function( String turnId)?  turnResume,TResult Function( String? activity)?  activityChanged,TResult Function( String turnId,  UsageInfo usage)?  usage,TResult Function( String? turnId)?  truncated,TResult Function( List<Turn> turns,  String? turnsNextCursor)?  turnsLoaded,TResult Function( String kind,  String id,  Message message)?  pendingMessageSet,TResult Function( String kind,  String id)?  pendingMessageRemoved,TResult Function( bool isRead)?  isReadChanged,TResult Function( bool isArchived)?  isArchivedChanged,TResult Function( ChatInputRequest request)?  inputRequested,TResult Function( String requestId,  String questionId,  JsonMap? answer)?  inputAnswerChanged,TResult Function( String requestId,  String response,  Map<String, JsonMap>? answers)?  inputCompleted,TResult Function( String type)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatTurnStarted() when turnStarted != null:
return turnStarted(_that.turnId,_that.startedAt,_that.message,_that.queuedMessageId);case ChatDelta() when delta != null:
return delta(_that.turnId,_that.partId,_that.content);case ChatReasoning() when reasoning != null:
return reasoning(_that.turnId,_that.partId,_that.content);case ChatResponsePart() when responsePart != null:
return responsePart(_that.turnId,_that.part);case ChatToolCallStart() when toolCallStart != null:
return toolCallStart(_that.turnId,_that.toolCallId,_that.toolName,_that.displayName,_that.intention,_that.contributor,_that.meta);case ChatToolCallDelta() when toolCallDelta != null:
return toolCallDelta(_that.turnId,_that.toolCallId,_that.content,_that.invocationMessage,_that.meta);case ChatToolCallReady() when toolCallReady != null:
return toolCallReady(_that.turnId,_that.toolCallId,_that.invocationMessage,_that.toolInput,_that.intention,_that.contributor,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.confirmed,_that.options,_that.meta);case ChatToolCallConfirmed() when toolCallConfirmed != null:
return toolCallConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.confirmed,_that.reason,_that.editedToolInput,_that.selectedOptionId,_that.reasonMessage,_that.userSuggestion,_that.meta);case ChatToolCallComplete() when toolCallComplete != null:
return toolCallComplete(_that.turnId,_that.toolCallId,_that.result,_that.requiresResultConfirmation,_that.meta);case ChatToolCallResultConfirmed() when toolCallResultConfirmed != null:
return toolCallResultConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.meta);case ChatToolCallContentChanged() when toolCallContentChanged != null:
return toolCallContentChanged(_that.turnId,_that.toolCallId,_that.content,_that.meta);case ChatTurnComplete() when turnComplete != null:
return turnComplete(_that.turnId,_that.duration);case ChatTurnCancelled() when turnCancelled != null:
return turnCancelled(_that.turnId,_that.duration);case ChatError() when error != null:
return error(_that.turnId,_that.duration,_that.part);case ChatTurnResume() when turnResume != null:
return turnResume(_that.turnId);case ChatActivityChanged() when activityChanged != null:
return activityChanged(_that.activity);case ChatUsage() when usage != null:
return usage(_that.turnId,_that.usage);case ChatTruncated() when truncated != null:
return truncated(_that.turnId);case ChatTurnsLoaded() when turnsLoaded != null:
return turnsLoaded(_that.turns,_that.turnsNextCursor);case ChatPendingMessageSet() when pendingMessageSet != null:
return pendingMessageSet(_that.kind,_that.id,_that.message);case ChatPendingMessageRemoved() when pendingMessageRemoved != null:
return pendingMessageRemoved(_that.kind,_that.id);case ChatIsReadChanged() when isReadChanged != null:
return isReadChanged(_that.isRead);case ChatIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that.isArchived);case ChatInputRequested() when inputRequested != null:
return inputRequested(_that.request);case ChatInputAnswerChanged() when inputAnswerChanged != null:
return inputAnswerChanged(_that.requestId,_that.questionId,_that.answer);case ChatInputCompleted() when inputCompleted != null:
return inputCompleted(_that.requestId,_that.response,_that.answers);case ChatUnknownAction() when unknown != null:
return unknown(_that.type);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String turnId,  String startedAt,  Message message,  String? queuedMessageId)  turnStarted,required TResult Function( String turnId,  String partId,  String content)  delta,required TResult Function( String turnId,  String partId,  String content)  reasoning,required TResult Function( String turnId,  ResponsePart part)  responsePart,required TResult Function( String turnId,  String toolCallId,  String toolName,  String displayName,  String? intention,  JsonMap? contributor, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallStart,required TResult Function( String turnId,  String toolCallId,  String? content,  Object? invocationMessage, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallDelta,required TResult Function( String turnId,  String toolCallId,  Object invocationMessage,  Object? toolInput,  String? intention,  JsonMap? contributor,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  String? confirmed,  List<ConfirmationOption>? options, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallReady,required TResult Function( String turnId,  String toolCallId,  bool approved,  String? confirmed,  String? reason,  String? editedToolInput,  String? selectedOptionId,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallConfirmed,required TResult Function( String turnId,  String toolCallId,  JsonMap result,  bool? requiresResultConfirmation, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallComplete,required TResult Function( String turnId,  String toolCallId,  bool approved, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallResultConfirmed,required TResult Function( String turnId,  String toolCallId,  List<JsonMap> content, @JsonKey(name: '_meta')  JsonMap? meta)  toolCallContentChanged,required TResult Function( String turnId,  int duration)  turnComplete,required TResult Function( String turnId,  int duration)  turnCancelled,required TResult Function( String turnId,  int duration,  ResponsePart part)  error,required TResult Function( String turnId)  turnResume,required TResult Function( String? activity)  activityChanged,required TResult Function( String turnId,  UsageInfo usage)  usage,required TResult Function( String? turnId)  truncated,required TResult Function( List<Turn> turns,  String? turnsNextCursor)  turnsLoaded,required TResult Function( String kind,  String id,  Message message)  pendingMessageSet,required TResult Function( String kind,  String id)  pendingMessageRemoved,required TResult Function( bool isRead)  isReadChanged,required TResult Function( bool isArchived)  isArchivedChanged,required TResult Function( ChatInputRequest request)  inputRequested,required TResult Function( String requestId,  String questionId,  JsonMap? answer)  inputAnswerChanged,required TResult Function( String requestId,  String response,  Map<String, JsonMap>? answers)  inputCompleted,required TResult Function( String type)  unknown,}) {final _that = this;
switch (_that) {
case ChatTurnStarted():
return turnStarted(_that.turnId,_that.startedAt,_that.message,_that.queuedMessageId);case ChatDelta():
return delta(_that.turnId,_that.partId,_that.content);case ChatReasoning():
return reasoning(_that.turnId,_that.partId,_that.content);case ChatResponsePart():
return responsePart(_that.turnId,_that.part);case ChatToolCallStart():
return toolCallStart(_that.turnId,_that.toolCallId,_that.toolName,_that.displayName,_that.intention,_that.contributor,_that.meta);case ChatToolCallDelta():
return toolCallDelta(_that.turnId,_that.toolCallId,_that.content,_that.invocationMessage,_that.meta);case ChatToolCallReady():
return toolCallReady(_that.turnId,_that.toolCallId,_that.invocationMessage,_that.toolInput,_that.intention,_that.contributor,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.confirmed,_that.options,_that.meta);case ChatToolCallConfirmed():
return toolCallConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.confirmed,_that.reason,_that.editedToolInput,_that.selectedOptionId,_that.reasonMessage,_that.userSuggestion,_that.meta);case ChatToolCallComplete():
return toolCallComplete(_that.turnId,_that.toolCallId,_that.result,_that.requiresResultConfirmation,_that.meta);case ChatToolCallResultConfirmed():
return toolCallResultConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.meta);case ChatToolCallContentChanged():
return toolCallContentChanged(_that.turnId,_that.toolCallId,_that.content,_that.meta);case ChatTurnComplete():
return turnComplete(_that.turnId,_that.duration);case ChatTurnCancelled():
return turnCancelled(_that.turnId,_that.duration);case ChatError():
return error(_that.turnId,_that.duration,_that.part);case ChatTurnResume():
return turnResume(_that.turnId);case ChatActivityChanged():
return activityChanged(_that.activity);case ChatUsage():
return usage(_that.turnId,_that.usage);case ChatTruncated():
return truncated(_that.turnId);case ChatTurnsLoaded():
return turnsLoaded(_that.turns,_that.turnsNextCursor);case ChatPendingMessageSet():
return pendingMessageSet(_that.kind,_that.id,_that.message);case ChatPendingMessageRemoved():
return pendingMessageRemoved(_that.kind,_that.id);case ChatIsReadChanged():
return isReadChanged(_that.isRead);case ChatIsArchivedChanged():
return isArchivedChanged(_that.isArchived);case ChatInputRequested():
return inputRequested(_that.request);case ChatInputAnswerChanged():
return inputAnswerChanged(_that.requestId,_that.questionId,_that.answer);case ChatInputCompleted():
return inputCompleted(_that.requestId,_that.response,_that.answers);case ChatUnknownAction():
return unknown(_that.type);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String turnId,  String startedAt,  Message message,  String? queuedMessageId)?  turnStarted,TResult? Function( String turnId,  String partId,  String content)?  delta,TResult? Function( String turnId,  String partId,  String content)?  reasoning,TResult? Function( String turnId,  ResponsePart part)?  responsePart,TResult? Function( String turnId,  String toolCallId,  String toolName,  String displayName,  String? intention,  JsonMap? contributor, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallStart,TResult? Function( String turnId,  String toolCallId,  String? content,  Object? invocationMessage, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallDelta,TResult? Function( String turnId,  String toolCallId,  Object invocationMessage,  Object? toolInput,  String? intention,  JsonMap? contributor,  Object? confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits,  bool? editable,  String? confirmed,  List<ConfirmationOption>? options, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallReady,TResult? Function( String turnId,  String toolCallId,  bool approved,  String? confirmed,  String? reason,  String? editedToolInput,  String? selectedOptionId,  Object? reasonMessage,  Message? userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallConfirmed,TResult? Function( String turnId,  String toolCallId,  JsonMap result,  bool? requiresResultConfirmation, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallComplete,TResult? Function( String turnId,  String toolCallId,  bool approved, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallResultConfirmed,TResult? Function( String turnId,  String toolCallId,  List<JsonMap> content, @JsonKey(name: '_meta')  JsonMap? meta)?  toolCallContentChanged,TResult? Function( String turnId,  int duration)?  turnComplete,TResult? Function( String turnId,  int duration)?  turnCancelled,TResult? Function( String turnId,  int duration,  ResponsePart part)?  error,TResult? Function( String turnId)?  turnResume,TResult? Function( String? activity)?  activityChanged,TResult? Function( String turnId,  UsageInfo usage)?  usage,TResult? Function( String? turnId)?  truncated,TResult? Function( List<Turn> turns,  String? turnsNextCursor)?  turnsLoaded,TResult? Function( String kind,  String id,  Message message)?  pendingMessageSet,TResult? Function( String kind,  String id)?  pendingMessageRemoved,TResult? Function( bool isRead)?  isReadChanged,TResult? Function( bool isArchived)?  isArchivedChanged,TResult? Function( ChatInputRequest request)?  inputRequested,TResult? Function( String requestId,  String questionId,  JsonMap? answer)?  inputAnswerChanged,TResult? Function( String requestId,  String response,  Map<String, JsonMap>? answers)?  inputCompleted,TResult? Function( String type)?  unknown,}) {final _that = this;
switch (_that) {
case ChatTurnStarted() when turnStarted != null:
return turnStarted(_that.turnId,_that.startedAt,_that.message,_that.queuedMessageId);case ChatDelta() when delta != null:
return delta(_that.turnId,_that.partId,_that.content);case ChatReasoning() when reasoning != null:
return reasoning(_that.turnId,_that.partId,_that.content);case ChatResponsePart() when responsePart != null:
return responsePart(_that.turnId,_that.part);case ChatToolCallStart() when toolCallStart != null:
return toolCallStart(_that.turnId,_that.toolCallId,_that.toolName,_that.displayName,_that.intention,_that.contributor,_that.meta);case ChatToolCallDelta() when toolCallDelta != null:
return toolCallDelta(_that.turnId,_that.toolCallId,_that.content,_that.invocationMessage,_that.meta);case ChatToolCallReady() when toolCallReady != null:
return toolCallReady(_that.turnId,_that.toolCallId,_that.invocationMessage,_that.toolInput,_that.intention,_that.contributor,_that.confirmationTitle,_that.riskAssessment,_that.edits,_that.editable,_that.confirmed,_that.options,_that.meta);case ChatToolCallConfirmed() when toolCallConfirmed != null:
return toolCallConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.confirmed,_that.reason,_that.editedToolInput,_that.selectedOptionId,_that.reasonMessage,_that.userSuggestion,_that.meta);case ChatToolCallComplete() when toolCallComplete != null:
return toolCallComplete(_that.turnId,_that.toolCallId,_that.result,_that.requiresResultConfirmation,_that.meta);case ChatToolCallResultConfirmed() when toolCallResultConfirmed != null:
return toolCallResultConfirmed(_that.turnId,_that.toolCallId,_that.approved,_that.meta);case ChatToolCallContentChanged() when toolCallContentChanged != null:
return toolCallContentChanged(_that.turnId,_that.toolCallId,_that.content,_that.meta);case ChatTurnComplete() when turnComplete != null:
return turnComplete(_that.turnId,_that.duration);case ChatTurnCancelled() when turnCancelled != null:
return turnCancelled(_that.turnId,_that.duration);case ChatError() when error != null:
return error(_that.turnId,_that.duration,_that.part);case ChatTurnResume() when turnResume != null:
return turnResume(_that.turnId);case ChatActivityChanged() when activityChanged != null:
return activityChanged(_that.activity);case ChatUsage() when usage != null:
return usage(_that.turnId,_that.usage);case ChatTruncated() when truncated != null:
return truncated(_that.turnId);case ChatTurnsLoaded() when turnsLoaded != null:
return turnsLoaded(_that.turns,_that.turnsNextCursor);case ChatPendingMessageSet() when pendingMessageSet != null:
return pendingMessageSet(_that.kind,_that.id,_that.message);case ChatPendingMessageRemoved() when pendingMessageRemoved != null:
return pendingMessageRemoved(_that.kind,_that.id);case ChatIsReadChanged() when isReadChanged != null:
return isReadChanged(_that.isRead);case ChatIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that.isArchived);case ChatInputRequested() when inputRequested != null:
return inputRequested(_that.request);case ChatInputAnswerChanged() when inputAnswerChanged != null:
return inputAnswerChanged(_that.requestId,_that.questionId,_that.answer);case ChatInputCompleted() when inputCompleted != null:
return inputCompleted(_that.requestId,_that.response,_that.answers);case ChatUnknownAction() when unknown != null:
return unknown(_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ChatTurnStarted implements ChatAction {
  const ChatTurnStarted({required this.turnId, required this.startedAt, required this.message, this.queuedMessageId,  String? $type}): $type = $type ?? 'chat/turnStarted';
  factory ChatTurnStarted.fromJson(Map<String, dynamic> json) => _$ChatTurnStartedFromJson(json);

/// New turn ID (client-chosen when dispatched by a client).
 final  String turnId;
/// Start time (ISO 8601).
 final  String startedAt;
/// The message.
 final  Message message;
/// The pending message this turn consumes, if any.
 final  String? queuedMessageId;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnStartedCopyWith<ChatTurnStarted> get copyWith => _$ChatTurnStartedCopyWithImpl<ChatTurnStarted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTurnStartedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurnStarted&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.message, message) || other.message == message)&&(identical(other.queuedMessageId, queuedMessageId) || other.queuedMessageId == queuedMessageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,startedAt,message,queuedMessageId);
}

@override
String toString() {
    return 'ChatAction.turnStarted(turnId: $turnId, startedAt: $startedAt, message: $message, queuedMessageId: $queuedMessageId)';
}


}

/// @nodoc
abstract mixin class $ChatTurnStartedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTurnStartedCopyWith(ChatTurnStarted value, $Res Function(ChatTurnStarted) _then) = _$ChatTurnStartedCopyWithImpl;
@useResult
$Res call({
 String turnId, String startedAt, Message message, String? queuedMessageId
});


$MessageCopyWith<$Res> get message;

}
/// @nodoc
class _$ChatTurnStartedCopyWithImpl<$Res>
    implements $ChatTurnStartedCopyWith<$Res> {
  _$ChatTurnStartedCopyWithImpl(this._self, this._then);

  final ChatTurnStarted _self;
  final $Res Function(ChatTurnStarted) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? startedAt = null,Object? message = null,Object? queuedMessageId = freezed,}) {
  return _then(ChatTurnStarted(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,queuedMessageId: freezed == queuedMessageId ? _self.queuedMessageId : queuedMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatDelta implements ChatAction {
  const ChatDelta({required this.turnId, required this.partId, required this.content,  String? $type}): $type = $type ?? 'chat/delta';
  factory ChatDelta.fromJson(Map<String, dynamic> json) => _$ChatDeltaFromJson(json);

/// Turn ID.
 final  String turnId;
/// Markdown part ID.
 final  String partId;
/// Text to append.
 final  String content;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatDeltaCopyWith<ChatDelta> get copyWith => _$ChatDeltaCopyWithImpl<ChatDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatDelta&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.partId, partId) || other.partId == partId)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,partId,content);
}

@override
String toString() {
    return 'ChatAction.delta(turnId: $turnId, partId: $partId, content: $content)';
}


}

/// @nodoc
abstract mixin class $ChatDeltaCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatDeltaCopyWith(ChatDelta value, $Res Function(ChatDelta) _then) = _$ChatDeltaCopyWithImpl;
@useResult
$Res call({
 String turnId, String partId, String content
});




}
/// @nodoc
class _$ChatDeltaCopyWithImpl<$Res>
    implements $ChatDeltaCopyWith<$Res> {
  _$ChatDeltaCopyWithImpl(this._self, this._then);

  final ChatDelta _self;
  final $Res Function(ChatDelta) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? partId = null,Object? content = null,}) {
  return _then(ChatDelta(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatReasoning implements ChatAction {
  const ChatReasoning({required this.turnId, required this.partId, required this.content,  String? $type}): $type = $type ?? 'chat/reasoning';
  factory ChatReasoning.fromJson(Map<String, dynamic> json) => _$ChatReasoningFromJson(json);

/// Turn ID.
 final  String turnId;
/// Reasoning part ID.
 final  String partId;
/// Text to append.
 final  String content;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatReasoningCopyWith<ChatReasoning> get copyWith => _$ChatReasoningCopyWithImpl<ChatReasoning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatReasoningToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatReasoning&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.partId, partId) || other.partId == partId)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,partId,content);
}

@override
String toString() {
    return 'ChatAction.reasoning(turnId: $turnId, partId: $partId, content: $content)';
}


}

/// @nodoc
abstract mixin class $ChatReasoningCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatReasoningCopyWith(ChatReasoning value, $Res Function(ChatReasoning) _then) = _$ChatReasoningCopyWithImpl;
@useResult
$Res call({
 String turnId, String partId, String content
});




}
/// @nodoc
class _$ChatReasoningCopyWithImpl<$Res>
    implements $ChatReasoningCopyWith<$Res> {
  _$ChatReasoningCopyWithImpl(this._self, this._then);

  final ChatReasoning _self;
  final $Res Function(ChatReasoning) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? partId = null,Object? content = null,}) {
  return _then(ChatReasoning(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,partId: null == partId ? _self.partId : partId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatResponsePart implements ChatAction {
  const ChatResponsePart({required this.turnId, required this.part,  String? $type}): $type = $type ?? 'chat/responsePart';
  factory ChatResponsePart.fromJson(Map<String, dynamic> json) => _$ChatResponsePartFromJson(json);

/// Turn ID.
 final  String turnId;
/// The new part.
 final  ResponsePart part;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatResponsePartCopyWith<ChatResponsePart> get copyWith => _$ChatResponsePartCopyWithImpl<ChatResponsePart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatResponsePartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatResponsePart&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.part, part) || other.part == part));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,part);
}

@override
String toString() {
    return 'ChatAction.responsePart(turnId: $turnId, part: $part)';
}


}

/// @nodoc
abstract mixin class $ChatResponsePartCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatResponsePartCopyWith(ChatResponsePart value, $Res Function(ChatResponsePart) _then) = _$ChatResponsePartCopyWithImpl;
@useResult
$Res call({
 String turnId, ResponsePart part
});


$ResponsePartCopyWith<$Res> get part;

}
/// @nodoc
class _$ChatResponsePartCopyWithImpl<$Res>
    implements $ChatResponsePartCopyWith<$Res> {
  _$ChatResponsePartCopyWithImpl(this._self, this._then);

  final ChatResponsePart _self;
  final $Res Function(ChatResponsePart) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? part = null,}) {
  return _then(ChatResponsePart(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as ResponsePart,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResponsePartCopyWith<$Res> get part {
  
  return $ResponsePartCopyWith<$Res>(_self.part, (value) {
    return _then(_self.copyWith(part: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatToolCallStart implements ChatAction {
  const ChatToolCallStart({required this.turnId, required this.toolCallId, required this.toolName, required this.displayName, this.intention,  JsonMap? contributor, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _contributor = contributor,_meta = meta,$type = $type ?? 'chat/toolCallStart';
  factory ChatToolCallStart.fromJson(Map<String, dynamic> json) => _$ChatToolCallStartFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// Tool name.
 final  String toolName;
/// Tool display name.
 final  String displayName;
/// Why the model is calling the tool.
 final  String? intention;
/// Who runs the tool (passed through).
 final  JsonMap? _contributor;
/// Who runs the tool (passed through).
 JsonMap? get contributor {
  final value = _contributor;
  if (value == null) return null;
  if (_contributor is EqualUnmodifiableMapView) return _contributor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallStartCopyWith<ChatToolCallStart> get copyWith => _$ChatToolCallStartCopyWithImpl<ChatToolCallStart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallStartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallStart&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.toolName, toolName) || other.toolName == toolName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.intention, intention) || other.intention == intention)&&const DeepCollectionEquality().equals(other.contributor, _contributor)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,toolName,displayName,intention,const DeepCollectionEquality().hash(_contributor),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallStart(turnId: $turnId, toolCallId: $toolCallId, toolName: $toolName, displayName: $displayName, intention: $intention, contributor: $contributor, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallStartCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallStartCopyWith(ChatToolCallStart value, $Res Function(ChatToolCallStart) _then) = _$ChatToolCallStartCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, String toolName, String displayName, String? intention, JsonMap? contributor,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallStartCopyWithImpl<$Res>
    implements $ChatToolCallStartCopyWith<$Res> {
  _$ChatToolCallStartCopyWithImpl(this._self, this._then);

  final ChatToolCallStart _self;
  final $Res Function(ChatToolCallStart) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? toolName = null,Object? displayName = null,Object? intention = freezed,Object? contributor = freezed,Object? meta = freezed,}) {
  return _then(ChatToolCallStart(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,toolName: null == toolName ? _self.toolName : toolName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,intention: freezed == intention ? _self.intention : intention // ignore: cast_nullable_to_non_nullable
as String?,contributor: freezed == contributor ? _self._contributor : contributor // ignore: cast_nullable_to_non_nullable
as JsonMap?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatToolCallDelta implements ChatAction {
  const ChatToolCallDelta({required this.turnId, required this.toolCallId, this.content, this.invocationMessage, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _meta = meta,$type = $type ?? 'chat/toolCallDelta';
  factory ChatToolCallDelta.fromJson(Map<String, dynamic> json) => _$ChatToolCallDeltaFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// Input JSON to append.
 final  String? content;
/// Updated `StringOrMarkdown` invocation message.
 final  Object? invocationMessage;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallDeltaCopyWith<ChatToolCallDelta> get copyWith => _$ChatToolCallDeltaCopyWithImpl<ChatToolCallDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallDelta&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.content, content) || other.content == content)&&const DeepCollectionEquality().equals(other.invocationMessage, invocationMessage)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,content,const DeepCollectionEquality().hash(invocationMessage),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallDelta(turnId: $turnId, toolCallId: $toolCallId, content: $content, invocationMessage: $invocationMessage, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallDeltaCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallDeltaCopyWith(ChatToolCallDelta value, $Res Function(ChatToolCallDelta) _then) = _$ChatToolCallDeltaCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, String? content, Object? invocationMessage,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallDeltaCopyWithImpl<$Res>
    implements $ChatToolCallDeltaCopyWith<$Res> {
  _$ChatToolCallDeltaCopyWithImpl(this._self, this._then);

  final ChatToolCallDelta _self;
  final $Res Function(ChatToolCallDelta) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? content = freezed,Object? invocationMessage = freezed,Object? meta = freezed,}) {
  return _then(ChatToolCallDelta(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,invocationMessage: freezed == invocationMessage ? _self.invocationMessage : invocationMessage ,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatToolCallReady implements ChatAction {
  const ChatToolCallReady({required this.turnId, required this.toolCallId, required this.invocationMessage, this.toolInput, this.intention,  JsonMap? contributor, this.confirmationTitle,  JsonMap? riskAssessment,  JsonMap? edits, this.editable, this.confirmed,  List<ConfirmationOption>? options, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _contributor = contributor,_riskAssessment = riskAssessment,_edits = edits,_options = options,_meta = meta,$type = $type ?? 'chat/toolCallReady';
  factory ChatToolCallReady.fromJson(Map<String, dynamic> json) => _$ChatToolCallReadyFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// `StringOrMarkdown` invocation message.
 final  Object invocationMessage;
/// Tool input.
 final  Object? toolInput;
/// Why the model is calling the tool.
 final  String? intention;
/// Who runs the tool (passed through).
 final  JsonMap? _contributor;
/// Who runs the tool (passed through).
 JsonMap? get contributor {
  final value = _contributor;
  if (value == null) return null;
  if (_contributor is EqualUnmodifiableMapView) return _contributor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// `StringOrMarkdown` approval title.
 final  Object? confirmationTitle;
/// Risk assessment (passed through).
 final  JsonMap? _riskAssessment;
/// Risk assessment (passed through).
 JsonMap? get riskAssessment {
  final value = _riskAssessment;
  if (value == null) return null;
  if (_riskAssessment is EqualUnmodifiableMapView) return _riskAssessment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// File edits (passed through).
 final  JsonMap? _edits;
/// File edits (passed through).
 JsonMap? get edits {
  final value = _edits;
  if (value == null) return null;
  if (_edits is EqualUnmodifiableMapView) return _edits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Whether the input is editable before approval.
 final  bool? editable;
/// Set when no confirmation is needed; the call starts running.
 final  String? confirmed;
/// Approve/deny choices.
 final  List<ConfirmationOption>? _options;
/// Approve/deny choices.
 List<ConfirmationOption>? get options {
  final value = _options;
  if (value == null) return null;
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallReadyCopyWith<ChatToolCallReady> get copyWith => _$ChatToolCallReadyCopyWithImpl<ChatToolCallReady>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallReadyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallReady&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.invocationMessage, invocationMessage)&&const DeepCollectionEquality().equals(other.toolInput, toolInput)&&(identical(other.intention, intention) || other.intention == intention)&&const DeepCollectionEquality().equals(other.contributor, _contributor)&&const DeepCollectionEquality().equals(other.confirmationTitle, confirmationTitle)&&const DeepCollectionEquality().equals(other.riskAssessment, _riskAssessment)&&const DeepCollectionEquality().equals(other.edits, _edits)&&(identical(other.editable, editable) || other.editable == editable)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&const DeepCollectionEquality().equals(other.options, _options)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,const DeepCollectionEquality().hash(invocationMessage),const DeepCollectionEquality().hash(toolInput),intention,const DeepCollectionEquality().hash(_contributor),const DeepCollectionEquality().hash(confirmationTitle),const DeepCollectionEquality().hash(_riskAssessment),const DeepCollectionEquality().hash(_edits),editable,confirmed,const DeepCollectionEquality().hash(_options),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallReady(turnId: $turnId, toolCallId: $toolCallId, invocationMessage: $invocationMessage, toolInput: $toolInput, intention: $intention, contributor: $contributor, confirmationTitle: $confirmationTitle, riskAssessment: $riskAssessment, edits: $edits, editable: $editable, confirmed: $confirmed, options: $options, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallReadyCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallReadyCopyWith(ChatToolCallReady value, $Res Function(ChatToolCallReady) _then) = _$ChatToolCallReadyCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, Object invocationMessage, Object? toolInput, String? intention, JsonMap? contributor, Object? confirmationTitle, JsonMap? riskAssessment, JsonMap? edits, bool? editable, String? confirmed, List<ConfirmationOption>? options,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallReadyCopyWithImpl<$Res>
    implements $ChatToolCallReadyCopyWith<$Res> {
  _$ChatToolCallReadyCopyWithImpl(this._self, this._then);

  final ChatToolCallReady _self;
  final $Res Function(ChatToolCallReady) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? invocationMessage = null,Object? toolInput = freezed,Object? intention = freezed,Object? contributor = freezed,Object? confirmationTitle = freezed,Object? riskAssessment = freezed,Object? edits = freezed,Object? editable = freezed,Object? confirmed = freezed,Object? options = freezed,Object? meta = freezed,}) {
  return _then(ChatToolCallReady(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,invocationMessage: null == invocationMessage ? _self.invocationMessage : invocationMessage ,toolInput: freezed == toolInput ? _self.toolInput : toolInput ,intention: freezed == intention ? _self.intention : intention // ignore: cast_nullable_to_non_nullable
as String?,contributor: freezed == contributor ? _self._contributor : contributor // ignore: cast_nullable_to_non_nullable
as JsonMap?,confirmationTitle: freezed == confirmationTitle ? _self.confirmationTitle : confirmationTitle ,riskAssessment: freezed == riskAssessment ? _self._riskAssessment : riskAssessment // ignore: cast_nullable_to_non_nullable
as JsonMap?,edits: freezed == edits ? _self._edits : edits // ignore: cast_nullable_to_non_nullable
as JsonMap?,editable: freezed == editable ? _self.editable : editable // ignore: cast_nullable_to_non_nullable
as bool?,confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as String?,options: freezed == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<ConfirmationOption>?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatToolCallConfirmed implements ChatAction {
  const ChatToolCallConfirmed({required this.turnId, required this.toolCallId, required this.approved, this.confirmed, this.reason, this.editedToolInput, this.selectedOptionId, this.reasonMessage, this.userSuggestion, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _meta = meta,$type = $type ?? 'chat/toolCallConfirmed';
  factory ChatToolCallConfirmed.fromJson(Map<String, dynamic> json) => _$ChatToolCallConfirmedFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// Whether the call was approved.
 final  bool approved;
/// When approved: `user-action` or `setting`.
 final  String? confirmed;
/// When denied: `denied` or `skipped`.
 final  String? reason;
/// Replacement input, when approved with edits.
 final  String? editedToolInput;
/// The chosen host-provided option.
 final  String? selectedOptionId;
/// `StringOrMarkdown` explanation of a denial.
 final  Object? reasonMessage;
/// A message to send instead, when denied.
 final  Message? userSuggestion;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallConfirmedCopyWith<ChatToolCallConfirmed> get copyWith => _$ChatToolCallConfirmedCopyWithImpl<ChatToolCallConfirmed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallConfirmedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallConfirmed&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.confirmed, confirmed) || other.confirmed == confirmed)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.editedToolInput, editedToolInput) || other.editedToolInput == editedToolInput)&&(identical(other.selectedOptionId, selectedOptionId) || other.selectedOptionId == selectedOptionId)&&const DeepCollectionEquality().equals(other.reasonMessage, reasonMessage)&&(identical(other.userSuggestion, userSuggestion) || other.userSuggestion == userSuggestion)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,approved,confirmed,reason,editedToolInput,selectedOptionId,const DeepCollectionEquality().hash(reasonMessage),userSuggestion,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallConfirmed(turnId: $turnId, toolCallId: $toolCallId, approved: $approved, confirmed: $confirmed, reason: $reason, editedToolInput: $editedToolInput, selectedOptionId: $selectedOptionId, reasonMessage: $reasonMessage, userSuggestion: $userSuggestion, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallConfirmedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallConfirmedCopyWith(ChatToolCallConfirmed value, $Res Function(ChatToolCallConfirmed) _then) = _$ChatToolCallConfirmedCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, bool approved, String? confirmed, String? reason, String? editedToolInput, String? selectedOptionId, Object? reasonMessage, Message? userSuggestion,@JsonKey(name: '_meta') JsonMap? meta
});


$MessageCopyWith<$Res>? get userSuggestion;

}
/// @nodoc
class _$ChatToolCallConfirmedCopyWithImpl<$Res>
    implements $ChatToolCallConfirmedCopyWith<$Res> {
  _$ChatToolCallConfirmedCopyWithImpl(this._self, this._then);

  final ChatToolCallConfirmed _self;
  final $Res Function(ChatToolCallConfirmed) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? approved = null,Object? confirmed = freezed,Object? reason = freezed,Object? editedToolInput = freezed,Object? selectedOptionId = freezed,Object? reasonMessage = freezed,Object? userSuggestion = freezed,Object? meta = freezed,}) {
  return _then(ChatToolCallConfirmed(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,confirmed: freezed == confirmed ? _self.confirmed : confirmed // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,editedToolInput: freezed == editedToolInput ? _self.editedToolInput : editedToolInput // ignore: cast_nullable_to_non_nullable
as String?,selectedOptionId: freezed == selectedOptionId ? _self.selectedOptionId : selectedOptionId // ignore: cast_nullable_to_non_nullable
as String?,reasonMessage: freezed == reasonMessage ? _self.reasonMessage : reasonMessage ,userSuggestion: freezed == userSuggestion ? _self.userSuggestion : userSuggestion // ignore: cast_nullable_to_non_nullable
as Message?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get userSuggestion {
    if (_self.userSuggestion == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.userSuggestion!, (value) {
    return _then(_self.copyWith(userSuggestion: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatToolCallComplete implements ChatAction {
  const ChatToolCallComplete({required this.turnId, required this.toolCallId, required  JsonMap result, this.requiresResultConfirmation, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _result = result,_meta = meta,$type = $type ?? 'chat/toolCallComplete';
  factory ChatToolCallComplete.fromJson(Map<String, dynamic> json) => _$ChatToolCallCompleteFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// `ToolCallResult`: `success`, `pastTenseMessage`, `content`, ...
 final  JsonMap _result;
/// `ToolCallResult`: `success`, `pastTenseMessage`, `content`, ...
 JsonMap get result {
  if (_result is EqualUnmodifiableMapView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_result);
}

/// Whether the result waits for the user's approval.
 final  bool? requiresResultConfirmation;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallCompleteCopyWith<ChatToolCallComplete> get copyWith => _$ChatToolCallCompleteCopyWithImpl<ChatToolCallComplete>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallCompleteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallComplete&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.result, _result)&&(identical(other.requiresResultConfirmation, requiresResultConfirmation) || other.requiresResultConfirmation == requiresResultConfirmation)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,const DeepCollectionEquality().hash(_result),requiresResultConfirmation,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallComplete(turnId: $turnId, toolCallId: $toolCallId, result: $result, requiresResultConfirmation: $requiresResultConfirmation, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallCompleteCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallCompleteCopyWith(ChatToolCallComplete value, $Res Function(ChatToolCallComplete) _then) = _$ChatToolCallCompleteCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, JsonMap result, bool? requiresResultConfirmation,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallCompleteCopyWithImpl<$Res>
    implements $ChatToolCallCompleteCopyWith<$Res> {
  _$ChatToolCallCompleteCopyWithImpl(this._self, this._then);

  final ChatToolCallComplete _self;
  final $Res Function(ChatToolCallComplete) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? result = null,Object? requiresResultConfirmation = freezed,Object? meta = freezed,}) {
  return _then(ChatToolCallComplete(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,result: null == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as JsonMap,requiresResultConfirmation: freezed == requiresResultConfirmation ? _self.requiresResultConfirmation : requiresResultConfirmation // ignore: cast_nullable_to_non_nullable
as bool?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatToolCallResultConfirmed implements ChatAction {
  const ChatToolCallResultConfirmed({required this.turnId, required this.toolCallId, required this.approved, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _meta = meta,$type = $type ?? 'chat/toolCallResultConfirmed';
  factory ChatToolCallResultConfirmed.fromJson(Map<String, dynamic> json) => _$ChatToolCallResultConfirmedFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// Whether the result was approved.
 final  bool approved;
/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallResultConfirmedCopyWith<ChatToolCallResultConfirmed> get copyWith => _$ChatToolCallResultConfirmedCopyWithImpl<ChatToolCallResultConfirmed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallResultConfirmedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallResultConfirmed&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&(identical(other.approved, approved) || other.approved == approved)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,approved,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallResultConfirmed(turnId: $turnId, toolCallId: $toolCallId, approved: $approved, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallResultConfirmedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallResultConfirmedCopyWith(ChatToolCallResultConfirmed value, $Res Function(ChatToolCallResultConfirmed) _then) = _$ChatToolCallResultConfirmedCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, bool approved,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallResultConfirmedCopyWithImpl<$Res>
    implements $ChatToolCallResultConfirmedCopyWith<$Res> {
  _$ChatToolCallResultConfirmedCopyWithImpl(this._self, this._then);

  final ChatToolCallResultConfirmed _self;
  final $Res Function(ChatToolCallResultConfirmed) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? approved = null,Object? meta = freezed,}) {
  return _then(ChatToolCallResultConfirmed(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatToolCallContentChanged implements ChatAction {
  const ChatToolCallContentChanged({required this.turnId, required this.toolCallId, required  List<JsonMap> content, @JsonKey(name: '_meta')  JsonMap? meta,  String? $type}): _content = content,_meta = meta,$type = $type ?? 'chat/toolCallContentChanged';
  factory ChatToolCallContentChanged.fromJson(Map<String, dynamic> json) => _$ChatToolCallContentChangedFromJson(json);

/// Turn ID.
 final  String turnId;
/// Tool call ID.
 final  String toolCallId;
/// The tool's content so far.
 final  List<JsonMap> _content;
/// The tool's content so far.
 List<JsonMap> get content {
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_content);
}

/// Server-defined metadata.
 final  JsonMap? _meta;
/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatToolCallContentChangedCopyWith<ChatToolCallContentChanged> get copyWith => _$ChatToolCallContentChangedCopyWithImpl<ChatToolCallContentChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatToolCallContentChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatToolCallContentChanged&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.toolCallId, toolCallId) || other.toolCallId == toolCallId)&&const DeepCollectionEquality().equals(other.content, _content)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,toolCallId,const DeepCollectionEquality().hash(_content),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'ChatAction.toolCallContentChanged(turnId: $turnId, toolCallId: $toolCallId, content: $content, meta: $meta)';
}


}

/// @nodoc
abstract mixin class $ChatToolCallContentChangedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatToolCallContentChangedCopyWith(ChatToolCallContentChanged value, $Res Function(ChatToolCallContentChanged) _then) = _$ChatToolCallContentChangedCopyWithImpl;
@useResult
$Res call({
 String turnId, String toolCallId, List<JsonMap> content,@JsonKey(name: '_meta') JsonMap? meta
});




}
/// @nodoc
class _$ChatToolCallContentChangedCopyWithImpl<$Res>
    implements $ChatToolCallContentChangedCopyWith<$Res> {
  _$ChatToolCallContentChangedCopyWithImpl(this._self, this._then);

  final ChatToolCallContentChanged _self;
  final $Res Function(ChatToolCallContentChanged) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? toolCallId = null,Object? content = null,Object? meta = freezed,}) {
  return _then(ChatToolCallContentChanged(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,toolCallId: null == toolCallId ? _self.toolCallId : toolCallId // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<JsonMap>,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatTurnComplete implements ChatAction {
  const ChatTurnComplete({required this.turnId, required this.duration,  String? $type}): $type = $type ?? 'chat/turnComplete';
  factory ChatTurnComplete.fromJson(Map<String, dynamic> json) => _$ChatTurnCompleteFromJson(json);

/// Turn ID.
 final  String turnId;
/// Duration in milliseconds.
 final  int duration;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnCompleteCopyWith<ChatTurnComplete> get copyWith => _$ChatTurnCompleteCopyWithImpl<ChatTurnComplete>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTurnCompleteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurnComplete&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,duration);
}

@override
String toString() {
    return 'ChatAction.turnComplete(turnId: $turnId, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $ChatTurnCompleteCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTurnCompleteCopyWith(ChatTurnComplete value, $Res Function(ChatTurnComplete) _then) = _$ChatTurnCompleteCopyWithImpl;
@useResult
$Res call({
 String turnId, int duration
});




}
/// @nodoc
class _$ChatTurnCompleteCopyWithImpl<$Res>
    implements $ChatTurnCompleteCopyWith<$Res> {
  _$ChatTurnCompleteCopyWithImpl(this._self, this._then);

  final ChatTurnComplete _self;
  final $Res Function(ChatTurnComplete) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? duration = null,}) {
  return _then(ChatTurnComplete(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatTurnCancelled implements ChatAction {
  const ChatTurnCancelled({required this.turnId, required this.duration,  String? $type}): $type = $type ?? 'chat/turnCancelled';
  factory ChatTurnCancelled.fromJson(Map<String, dynamic> json) => _$ChatTurnCancelledFromJson(json);

/// Turn ID.
 final  String turnId;
/// Duration in milliseconds.
 final  int duration;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnCancelledCopyWith<ChatTurnCancelled> get copyWith => _$ChatTurnCancelledCopyWithImpl<ChatTurnCancelled>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTurnCancelledToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurnCancelled&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.duration, duration) || other.duration == duration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,duration);
}

@override
String toString() {
    return 'ChatAction.turnCancelled(turnId: $turnId, duration: $duration)';
}


}

/// @nodoc
abstract mixin class $ChatTurnCancelledCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTurnCancelledCopyWith(ChatTurnCancelled value, $Res Function(ChatTurnCancelled) _then) = _$ChatTurnCancelledCopyWithImpl;
@useResult
$Res call({
 String turnId, int duration
});




}
/// @nodoc
class _$ChatTurnCancelledCopyWithImpl<$Res>
    implements $ChatTurnCancelledCopyWith<$Res> {
  _$ChatTurnCancelledCopyWithImpl(this._self, this._then);

  final ChatTurnCancelled _self;
  final $Res Function(ChatTurnCancelled) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? duration = null,}) {
  return _then(ChatTurnCancelled(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatError implements ChatAction {
  const ChatError({required this.turnId, required this.duration, required this.part,  String? $type}): $type = $type ?? 'chat/error';
  factory ChatError.fromJson(Map<String, dynamic> json) => _$ChatErrorFromJson(json);

/// Turn ID.
 final  String turnId;
/// Duration in milliseconds.
 final  int duration;
/// The [ErrorPart] appended to the turn.
 final  ResponsePart part;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatErrorCopyWith<ChatError> get copyWith => _$ChatErrorCopyWithImpl<ChatError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatErrorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatError&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.part, part) || other.part == part));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,duration,part);
}

@override
String toString() {
    return 'ChatAction.error(turnId: $turnId, duration: $duration, part: $part)';
}


}

/// @nodoc
abstract mixin class $ChatErrorCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatErrorCopyWith(ChatError value, $Res Function(ChatError) _then) = _$ChatErrorCopyWithImpl;
@useResult
$Res call({
 String turnId, int duration, ResponsePart part
});


$ResponsePartCopyWith<$Res> get part;

}
/// @nodoc
class _$ChatErrorCopyWithImpl<$Res>
    implements $ChatErrorCopyWith<$Res> {
  _$ChatErrorCopyWithImpl(this._self, this._then);

  final ChatError _self;
  final $Res Function(ChatError) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? duration = null,Object? part = null,}) {
  return _then(ChatError(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as ResponsePart,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResponsePartCopyWith<$Res> get part {
  
  return $ResponsePartCopyWith<$Res>(_self.part, (value) {
    return _then(_self.copyWith(part: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatTurnResume implements ChatAction {
  const ChatTurnResume({required this.turnId,  String? $type}): $type = $type ?? 'chat/turnResume';
  factory ChatTurnResume.fromJson(Map<String, dynamic> json) => _$ChatTurnResumeFromJson(json);

/// Turn ID.
 final  String turnId;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnResumeCopyWith<ChatTurnResume> get copyWith => _$ChatTurnResumeCopyWithImpl<ChatTurnResume>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTurnResumeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurnResume&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId);
}

@override
String toString() {
    return 'ChatAction.turnResume(turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class $ChatTurnResumeCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTurnResumeCopyWith(ChatTurnResume value, $Res Function(ChatTurnResume) _then) = _$ChatTurnResumeCopyWithImpl;
@useResult
$Res call({
 String turnId
});




}
/// @nodoc
class _$ChatTurnResumeCopyWithImpl<$Res>
    implements $ChatTurnResumeCopyWith<$Res> {
  _$ChatTurnResumeCopyWithImpl(this._self, this._then);

  final ChatTurnResume _self;
  final $Res Function(ChatTurnResume) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,}) {
  return _then(ChatTurnResume(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatActivityChanged implements ChatAction {
  const ChatActivityChanged({this.activity,  String? $type}): $type = $type ?? 'chat/activityChanged';
  factory ChatActivityChanged.fromJson(Map<String, dynamic> json) => _$ChatActivityChangedFromJson(json);

/// New activity, or null when idle.
 final  String? activity;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatActivityChangedCopyWith<ChatActivityChanged> get copyWith => _$ChatActivityChangedCopyWithImpl<ChatActivityChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatActivityChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatActivityChanged&&(identical(other.activity, activity) || other.activity == activity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,activity);
}

@override
String toString() {
    return 'ChatAction.activityChanged(activity: $activity)';
}


}

/// @nodoc
abstract mixin class $ChatActivityChangedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatActivityChangedCopyWith(ChatActivityChanged value, $Res Function(ChatActivityChanged) _then) = _$ChatActivityChangedCopyWithImpl;
@useResult
$Res call({
 String? activity
});




}
/// @nodoc
class _$ChatActivityChangedCopyWithImpl<$Res>
    implements $ChatActivityChangedCopyWith<$Res> {
  _$ChatActivityChangedCopyWithImpl(this._self, this._then);

  final ChatActivityChanged _self;
  final $Res Function(ChatActivityChanged) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? activity = freezed,}) {
  return _then(ChatActivityChanged(
activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatUsage implements ChatAction {
  const ChatUsage({required this.turnId, required this.usage,  String? $type}): $type = $type ?? 'chat/usage';
  factory ChatUsage.fromJson(Map<String, dynamic> json) => _$ChatUsageFromJson(json);

/// Turn ID.
 final  String turnId;
/// Usage so far.
 final  UsageInfo usage;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUsageCopyWith<ChatUsage> get copyWith => _$ChatUsageCopyWithImpl<ChatUsage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatUsageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUsage&&(identical(other.turnId, turnId) || other.turnId == turnId)&&(identical(other.usage, usage) || other.usage == usage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId,usage);
}

@override
String toString() {
    return 'ChatAction.usage(turnId: $turnId, usage: $usage)';
}


}

/// @nodoc
abstract mixin class $ChatUsageCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatUsageCopyWith(ChatUsage value, $Res Function(ChatUsage) _then) = _$ChatUsageCopyWithImpl;
@useResult
$Res call({
 String turnId, UsageInfo usage
});


$UsageInfoCopyWith<$Res> get usage;

}
/// @nodoc
class _$ChatUsageCopyWithImpl<$Res>
    implements $ChatUsageCopyWith<$Res> {
  _$ChatUsageCopyWithImpl(this._self, this._then);

  final ChatUsage _self;
  final $Res Function(ChatUsage) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = null,Object? usage = null,}) {
  return _then(ChatUsage(
turnId: null == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String,usage: null == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as UsageInfo,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageInfoCopyWith<$Res> get usage {
  
  return $UsageInfoCopyWith<$Res>(_self.usage, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatTruncated implements ChatAction {
  const ChatTruncated({this.turnId,  String? $type}): $type = $type ?? 'chat/truncated';
  factory ChatTruncated.fromJson(Map<String, dynamic> json) => _$ChatTruncatedFromJson(json);

/// Last turn to keep.
 final  String? turnId;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTruncatedCopyWith<ChatTruncated> get copyWith => _$ChatTruncatedCopyWithImpl<ChatTruncated>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTruncatedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTruncated&&(identical(other.turnId, turnId) || other.turnId == turnId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,turnId);
}

@override
String toString() {
    return 'ChatAction.truncated(turnId: $turnId)';
}


}

/// @nodoc
abstract mixin class $ChatTruncatedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTruncatedCopyWith(ChatTruncated value, $Res Function(ChatTruncated) _then) = _$ChatTruncatedCopyWithImpl;
@useResult
$Res call({
 String? turnId
});




}
/// @nodoc
class _$ChatTruncatedCopyWithImpl<$Res>
    implements $ChatTruncatedCopyWith<$Res> {
  _$ChatTruncatedCopyWithImpl(this._self, this._then);

  final ChatTruncated _self;
  final $Res Function(ChatTruncated) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turnId = freezed,}) {
  return _then(ChatTruncated(
turnId: freezed == turnId ? _self.turnId : turnId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatTurnsLoaded implements ChatAction {
  const ChatTurnsLoaded({required  List<Turn> turns, this.turnsNextCursor,  String? $type}): _turns = turns,$type = $type ?? 'chat/turnsLoaded';
  factory ChatTurnsLoaded.fromJson(Map<String, dynamic> json) => _$ChatTurnsLoadedFromJson(json);

/// Older turns, oldest first.
 final  List<Turn> _turns;
/// Older turns, oldest first.
 List<Turn> get turns {
  if (_turns is EqualUnmodifiableListView) return _turns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_turns);
}

/// Cursor for the next page.
 final  String? turnsNextCursor;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatTurnsLoadedCopyWith<ChatTurnsLoaded> get copyWith => _$ChatTurnsLoadedCopyWithImpl<ChatTurnsLoaded>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatTurnsLoadedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatTurnsLoaded&&const DeepCollectionEquality().equals(other.turns, _turns)&&(identical(other.turnsNextCursor, turnsNextCursor) || other.turnsNextCursor == turnsNextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_turns),turnsNextCursor);
}

@override
String toString() {
    return 'ChatAction.turnsLoaded(turns: $turns, turnsNextCursor: $turnsNextCursor)';
}


}

/// @nodoc
abstract mixin class $ChatTurnsLoadedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatTurnsLoadedCopyWith(ChatTurnsLoaded value, $Res Function(ChatTurnsLoaded) _then) = _$ChatTurnsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Turn> turns, String? turnsNextCursor
});




}
/// @nodoc
class _$ChatTurnsLoadedCopyWithImpl<$Res>
    implements $ChatTurnsLoadedCopyWith<$Res> {
  _$ChatTurnsLoadedCopyWithImpl(this._self, this._then);

  final ChatTurnsLoaded _self;
  final $Res Function(ChatTurnsLoaded) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turns = null,Object? turnsNextCursor = freezed,}) {
  return _then(ChatTurnsLoaded(
turns: null == turns ? _self._turns : turns // ignore: cast_nullable_to_non_nullable
as List<Turn>,turnsNextCursor: freezed == turnsNextCursor ? _self.turnsNextCursor : turnsNextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatPendingMessageSet implements ChatAction {
  const ChatPendingMessageSet({required this.kind, required this.id, required this.message,  String? $type}): $type = $type ?? 'chat/pendingMessageSet';
  factory ChatPendingMessageSet.fromJson(Map<String, dynamic> json) => _$ChatPendingMessageSetFromJson(json);

/// `steering` or `queued`.
 final  String kind;
/// Pending message ID.
 final  String id;
/// The message.
 final  Message message;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatPendingMessageSetCopyWith<ChatPendingMessageSet> get copyWith => _$ChatPendingMessageSetCopyWithImpl<ChatPendingMessageSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatPendingMessageSetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatPendingMessageSet&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,id,message);
}

@override
String toString() {
    return 'ChatAction.pendingMessageSet(kind: $kind, id: $id, message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatPendingMessageSetCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatPendingMessageSetCopyWith(ChatPendingMessageSet value, $Res Function(ChatPendingMessageSet) _then) = _$ChatPendingMessageSetCopyWithImpl;
@useResult
$Res call({
 String kind, String id, Message message
});


$MessageCopyWith<$Res> get message;

}
/// @nodoc
class _$ChatPendingMessageSetCopyWithImpl<$Res>
    implements $ChatPendingMessageSetCopyWith<$Res> {
  _$ChatPendingMessageSetCopyWithImpl(this._self, this._then);

  final ChatPendingMessageSet _self;
  final $Res Function(ChatPendingMessageSet) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,Object? message = null,}) {
  return _then(ChatPendingMessageSet(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as Message,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res> get message {
  
  return $MessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatPendingMessageRemoved implements ChatAction {
  const ChatPendingMessageRemoved({required this.kind, required this.id,  String? $type}): $type = $type ?? 'chat/pendingMessageRemoved';
  factory ChatPendingMessageRemoved.fromJson(Map<String, dynamic> json) => _$ChatPendingMessageRemovedFromJson(json);

/// `steering` or `queued`.
 final  String kind;
/// Pending message ID.
 final  String id;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatPendingMessageRemovedCopyWith<ChatPendingMessageRemoved> get copyWith => _$ChatPendingMessageRemovedCopyWithImpl<ChatPendingMessageRemoved>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatPendingMessageRemovedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatPendingMessageRemoved&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,kind,id);
}

@override
String toString() {
    return 'ChatAction.pendingMessageRemoved(kind: $kind, id: $id)';
}


}

/// @nodoc
abstract mixin class $ChatPendingMessageRemovedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatPendingMessageRemovedCopyWith(ChatPendingMessageRemoved value, $Res Function(ChatPendingMessageRemoved) _then) = _$ChatPendingMessageRemovedCopyWithImpl;
@useResult
$Res call({
 String kind, String id
});




}
/// @nodoc
class _$ChatPendingMessageRemovedCopyWithImpl<$Res>
    implements $ChatPendingMessageRemovedCopyWith<$Res> {
  _$ChatPendingMessageRemovedCopyWithImpl(this._self, this._then);

  final ChatPendingMessageRemoved _self;
  final $Res Function(ChatPendingMessageRemoved) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,}) {
  return _then(ChatPendingMessageRemoved(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatIsReadChanged implements ChatAction {
  const ChatIsReadChanged({required this.isRead,  String? $type}): $type = $type ?? 'chat/isReadChanged';
  factory ChatIsReadChanged.fromJson(Map<String, dynamic> json) => _$ChatIsReadChangedFromJson(json);

/// Whether the chat is read.
 final  bool isRead;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatIsReadChangedCopyWith<ChatIsReadChanged> get copyWith => _$ChatIsReadChangedCopyWithImpl<ChatIsReadChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatIsReadChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatIsReadChanged&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isRead);
}

@override
String toString() {
    return 'ChatAction.isReadChanged(isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class $ChatIsReadChangedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatIsReadChangedCopyWith(ChatIsReadChanged value, $Res Function(ChatIsReadChanged) _then) = _$ChatIsReadChangedCopyWithImpl;
@useResult
$Res call({
 bool isRead
});




}
/// @nodoc
class _$ChatIsReadChangedCopyWithImpl<$Res>
    implements $ChatIsReadChangedCopyWith<$Res> {
  _$ChatIsReadChangedCopyWithImpl(this._self, this._then);

  final ChatIsReadChanged _self;
  final $Res Function(ChatIsReadChanged) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isRead = null,}) {
  return _then(ChatIsReadChanged(
isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatIsArchivedChanged implements ChatAction {
  const ChatIsArchivedChanged({required this.isArchived,  String? $type}): $type = $type ?? 'chat/isArchivedChanged';
  factory ChatIsArchivedChanged.fromJson(Map<String, dynamic> json) => _$ChatIsArchivedChangedFromJson(json);

/// Whether the chat is archived.
 final  bool isArchived;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatIsArchivedChangedCopyWith<ChatIsArchivedChanged> get copyWith => _$ChatIsArchivedChangedCopyWithImpl<ChatIsArchivedChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatIsArchivedChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatIsArchivedChanged&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isArchived);
}

@override
String toString() {
    return 'ChatAction.isArchivedChanged(isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $ChatIsArchivedChangedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatIsArchivedChangedCopyWith(ChatIsArchivedChanged value, $Res Function(ChatIsArchivedChanged) _then) = _$ChatIsArchivedChangedCopyWithImpl;
@useResult
$Res call({
 bool isArchived
});




}
/// @nodoc
class _$ChatIsArchivedChangedCopyWithImpl<$Res>
    implements $ChatIsArchivedChangedCopyWith<$Res> {
  _$ChatIsArchivedChangedCopyWithImpl(this._self, this._then);

  final ChatIsArchivedChanged _self;
  final $Res Function(ChatIsArchivedChanged) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isArchived = null,}) {
  return _then(ChatIsArchivedChanged(
isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatInputRequested implements ChatAction {
  const ChatInputRequested({required this.request,  String? $type}): $type = $type ?? 'chat/inputRequested';
  factory ChatInputRequested.fromJson(Map<String, dynamic> json) => _$ChatInputRequestedFromJson(json);

/// The request.
 final  ChatInputRequest request;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputRequestedCopyWith<ChatInputRequested> get copyWith => _$ChatInputRequestedCopyWithImpl<ChatInputRequested>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputRequestedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputRequested&&(identical(other.request, request) || other.request == request));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,request);
}

@override
String toString() {
    return 'ChatAction.inputRequested(request: $request)';
}


}

/// @nodoc
abstract mixin class $ChatInputRequestedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatInputRequestedCopyWith(ChatInputRequested value, $Res Function(ChatInputRequested) _then) = _$ChatInputRequestedCopyWithImpl;
@useResult
$Res call({
 ChatInputRequest request
});


$ChatInputRequestCopyWith<$Res> get request;

}
/// @nodoc
class _$ChatInputRequestedCopyWithImpl<$Res>
    implements $ChatInputRequestedCopyWith<$Res> {
  _$ChatInputRequestedCopyWithImpl(this._self, this._then);

  final ChatInputRequested _self;
  final $Res Function(ChatInputRequested) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? request = null,}) {
  return _then(ChatInputRequested(
request: null == request ? _self.request : request // ignore: cast_nullable_to_non_nullable
as ChatInputRequest,
  ));
}

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatInputRequestCopyWith<$Res> get request {
  
  return $ChatInputRequestCopyWith<$Res>(_self.request, (value) {
    return _then(_self.copyWith(request: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ChatInputAnswerChanged implements ChatAction {
  const ChatInputAnswerChanged({required this.requestId, required this.questionId,  JsonMap? answer,  String? $type}): _answer = answer,$type = $type ?? 'chat/inputAnswerChanged';
  factory ChatInputAnswerChanged.fromJson(Map<String, dynamic> json) => _$ChatInputAnswerChangedFromJson(json);

/// Request ID.
 final  String requestId;
/// Question ID.
 final  String questionId;
/// The answer (`ChatInputAnswer`), or null to clear it.
 final  JsonMap? _answer;
/// The answer (`ChatInputAnswer`), or null to clear it.
 JsonMap? get answer {
  final value = _answer;
  if (value == null) return null;
  if (_answer is EqualUnmodifiableMapView) return _answer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputAnswerChangedCopyWith<ChatInputAnswerChanged> get copyWith => _$ChatInputAnswerChangedCopyWithImpl<ChatInputAnswerChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputAnswerChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputAnswerChanged&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&const DeepCollectionEquality().equals(other.answer, _answer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,requestId,questionId,const DeepCollectionEquality().hash(_answer));
}

@override
String toString() {
    return 'ChatAction.inputAnswerChanged(requestId: $requestId, questionId: $questionId, answer: $answer)';
}


}

/// @nodoc
abstract mixin class $ChatInputAnswerChangedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatInputAnswerChangedCopyWith(ChatInputAnswerChanged value, $Res Function(ChatInputAnswerChanged) _then) = _$ChatInputAnswerChangedCopyWithImpl;
@useResult
$Res call({
 String requestId, String questionId, JsonMap? answer
});




}
/// @nodoc
class _$ChatInputAnswerChangedCopyWithImpl<$Res>
    implements $ChatInputAnswerChangedCopyWith<$Res> {
  _$ChatInputAnswerChangedCopyWithImpl(this._self, this._then);

  final ChatInputAnswerChanged _self;
  final $Res Function(ChatInputAnswerChanged) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? questionId = null,Object? answer = freezed,}) {
  return _then(ChatInputAnswerChanged(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,answer: freezed == answer ? _self._answer : answer // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatInputCompleted implements ChatAction {
  const ChatInputCompleted({required this.requestId, required this.response,  Map<String, JsonMap>? answers,  String? $type}): _answers = answers,$type = $type ?? 'chat/inputCompleted';
  factory ChatInputCompleted.fromJson(Map<String, dynamic> json) => _$ChatInputCompletedFromJson(json);

/// Request ID.
 final  String requestId;
/// `accept`, `decline` or `cancel`.
 final  String response;
/// Final answers keyed by question ID.
 final  Map<String, JsonMap>? _answers;
/// Final answers keyed by question ID.
 Map<String, JsonMap>? get answers {
  final value = _answers;
  if (value == null) return null;
  if (_answers is EqualUnmodifiableMapView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatInputCompletedCopyWith<ChatInputCompleted> get copyWith => _$ChatInputCompletedCopyWithImpl<ChatInputCompleted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatInputCompletedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatInputCompleted&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.response, response) || other.response == response)&&const DeepCollectionEquality().equals(other.answers, _answers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,requestId,response,const DeepCollectionEquality().hash(_answers));
}

@override
String toString() {
    return 'ChatAction.inputCompleted(requestId: $requestId, response: $response, answers: $answers)';
}


}

/// @nodoc
abstract mixin class $ChatInputCompletedCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatInputCompletedCopyWith(ChatInputCompleted value, $Res Function(ChatInputCompleted) _then) = _$ChatInputCompletedCopyWithImpl;
@useResult
$Res call({
 String requestId, String response, Map<String, JsonMap>? answers
});




}
/// @nodoc
class _$ChatInputCompletedCopyWithImpl<$Res>
    implements $ChatInputCompletedCopyWith<$Res> {
  _$ChatInputCompletedCopyWithImpl(this._self, this._then);

  final ChatInputCompleted _self;
  final $Res Function(ChatInputCompleted) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? response = null,Object? answers = freezed,}) {
  return _then(ChatInputCompleted(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,response: null == response ? _self.response : response // ignore: cast_nullable_to_non_nullable
as String,answers: freezed == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as Map<String, JsonMap>?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChatUnknownAction implements ChatAction {
  const ChatUnknownAction({required this.type});
  factory ChatUnknownAction.fromJson(Map<String, dynamic> json) => _$ChatUnknownActionFromJson(json);

/// The action's `type`.
 final  String type;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatUnknownActionCopyWith<ChatUnknownAction> get copyWith => _$ChatUnknownActionCopyWithImpl<ChatUnknownAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatUnknownActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatUnknownAction&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'ChatAction.unknown(type: $type)';
}


}

/// @nodoc
abstract mixin class $ChatUnknownActionCopyWith<$Res> implements $ChatActionCopyWith<$Res> {
  factory $ChatUnknownActionCopyWith(ChatUnknownAction value, $Res Function(ChatUnknownAction) _then) = _$ChatUnknownActionCopyWithImpl;
@useResult
$Res call({
 String type
});




}
/// @nodoc
class _$ChatUnknownActionCopyWithImpl<$Res>
    implements $ChatUnknownActionCopyWith<$Res> {
  _$ChatUnknownActionCopyWithImpl(this._self, this._then);

  final ChatUnknownAction _self;
  final $Res Function(ChatUnknownAction) _then;

/// Create a copy of ChatAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(ChatUnknownAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
