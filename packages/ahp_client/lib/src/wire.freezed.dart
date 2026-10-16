// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wire.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Implementation {

/// Machine-readable name, e.g. `pi-agent-host-protocol`.
 String get name;/// Version string.
 String? get version;/// Human-readable title.
 String? get title;
/// Create a copy of Implementation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImplementationCopyWith<Implementation> get copyWith => _$ImplementationCopyWithImpl<Implementation>(this as Implementation, _$identity);

  /// Serializes this Implementation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Implementation;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Implementation&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.title, _this.title) || other.title == _this.title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Implementation;
  return Object.hash(runtimeType,_this.name,_this.version,_this.title);
}

@override
String toString() {
  final _this = this as Implementation;
  return 'Implementation(name: ${_this.name}, version: ${_this.version}, title: ${_this.title})';
}


}

/// @nodoc
abstract mixin class $ImplementationCopyWith<$Res>  {
  factory $ImplementationCopyWith(Implementation value, $Res Function(Implementation) _then) = _$ImplementationCopyWithImpl;
@useResult
$Res call({
 String name, String? version, String? title
});




}
/// @nodoc
class _$ImplementationCopyWithImpl<$Res>
    implements $ImplementationCopyWith<$Res> {
  _$ImplementationCopyWithImpl(this._self, this._then);

  final Implementation _self;
  final $Res Function(Implementation) _then;

/// Create a copy of Implementation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? version = freezed,Object? title = freezed,}) {
  return _then(Implementation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Implementation].
extension ImplementationPatterns on Implementation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Implementation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Implementation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Implementation value)  $default,){
final _that = this;
switch (_that) {
case _Implementation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Implementation value)?  $default,){
final _that = this;
switch (_that) {
case _Implementation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? version,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Implementation() when $default != null:
return $default(_that.name,_that.version,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? version,  String? title)  $default,) {final _that = this;
switch (_that) {
case _Implementation():
return $default(_that.name,_that.version,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? version,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _Implementation() when $default != null:
return $default(_that.name,_that.version,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Implementation implements Implementation {
  const _Implementation({required this.name, this.version, this.title});
  factory _Implementation.fromJson(Map<String, dynamic> json) => _$ImplementationFromJson(json);

/// Machine-readable name, e.g. `pi-agent-host-protocol`.
@override final  String name;
/// Version string.
@override final  String? version;
/// Human-readable title.
@override final  String? title;

/// Create a copy of Implementation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImplementationCopyWith<_Implementation> get copyWith => __$ImplementationCopyWithImpl<_Implementation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImplementationToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Implementation&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,version,title);
}

@override
String toString() {
    return 'Implementation(name: $name, version: $version, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ImplementationCopyWith<$Res> implements $ImplementationCopyWith<$Res> {
  factory _$ImplementationCopyWith(_Implementation value, $Res Function(_Implementation) _then) = __$ImplementationCopyWithImpl;
@override @useResult
$Res call({
 String name, String? version, String? title
});




}
/// @nodoc
class __$ImplementationCopyWithImpl<$Res>
    implements _$ImplementationCopyWith<$Res> {
  __$ImplementationCopyWithImpl(this._self, this._then);

  final _Implementation _self;
  final $Res Function(_Implementation) _then;

/// Create a copy of Implementation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? version = freezed,Object? title = freezed,}) {
  return _then(_Implementation(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ProjectInfo {

/// Project URI.
 String get uri;/// Human-readable project name.
 String get displayName;
/// Create a copy of ProjectInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectInfoCopyWith<ProjectInfo> get copyWith => _$ProjectInfoCopyWithImpl<ProjectInfo>(this as ProjectInfo, _$identity);

  /// Serializes this ProjectInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectInfo&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectInfo;
  return Object.hash(runtimeType,_this.uri,_this.displayName);
}

@override
String toString() {
  final _this = this as ProjectInfo;
  return 'ProjectInfo(uri: ${_this.uri}, displayName: ${_this.displayName})';
}


}

/// @nodoc
abstract mixin class $ProjectInfoCopyWith<$Res>  {
  factory $ProjectInfoCopyWith(ProjectInfo value, $Res Function(ProjectInfo) _then) = _$ProjectInfoCopyWithImpl;
@useResult
$Res call({
 String uri, String displayName
});




}
/// @nodoc
class _$ProjectInfoCopyWithImpl<$Res>
    implements $ProjectInfoCopyWith<$Res> {
  _$ProjectInfoCopyWithImpl(this._self, this._then);

  final ProjectInfo _self;
  final $Res Function(ProjectInfo) _then;

/// Create a copy of ProjectInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? displayName = null,}) {
  return _then(ProjectInfo(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectInfo].
extension ProjectInfoPatterns on ProjectInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectInfo value)  $default,){
final _that = this;
switch (_that) {
case _ProjectInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uri,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectInfo() when $default != null:
return $default(_that.uri,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uri,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _ProjectInfo():
return $default(_that.uri,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uri,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _ProjectInfo() when $default != null:
return $default(_that.uri,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectInfo implements ProjectInfo {
  const _ProjectInfo({required this.uri, required this.displayName});
  factory _ProjectInfo.fromJson(Map<String, dynamic> json) => _$ProjectInfoFromJson(json);

/// Project URI.
@override final  String uri;
/// Human-readable project name.
@override final  String displayName;

/// Create a copy of ProjectInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectInfoCopyWith<_ProjectInfo> get copyWith => __$ProjectInfoCopyWithImpl<_ProjectInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectInfo&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uri,displayName);
}

@override
String toString() {
    return 'ProjectInfo(uri: $uri, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$ProjectInfoCopyWith<$Res> implements $ProjectInfoCopyWith<$Res> {
  factory _$ProjectInfoCopyWith(_ProjectInfo value, $Res Function(_ProjectInfo) _then) = __$ProjectInfoCopyWithImpl;
@override @useResult
$Res call({
 String uri, String displayName
});




}
/// @nodoc
class __$ProjectInfoCopyWithImpl<$Res>
    implements _$ProjectInfoCopyWith<$Res> {
  __$ProjectInfoCopyWithImpl(this._self, this._then);

  final _ProjectInfo _self;
  final $Res Function(_ProjectInfo) _then;

/// Create a copy of ProjectInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? displayName = null,}) {
  return _then(_ProjectInfo(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChangesSummary {

/// Total inserted lines across all changed files.
 int? get additions;/// Total deleted lines across all changed files.
 int? get deletions;/// Number of files that have changes.
 int? get files;
/// Create a copy of ChangesSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChangesSummaryCopyWith<ChangesSummary> get copyWith => _$ChangesSummaryCopyWithImpl<ChangesSummary>(this as ChangesSummary, _$identity);

  /// Serializes this ChangesSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChangesSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChangesSummary&&(identical(other.additions, _this.additions) || other.additions == _this.additions)&&(identical(other.deletions, _this.deletions) || other.deletions == _this.deletions)&&(identical(other.files, _this.files) || other.files == _this.files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChangesSummary;
  return Object.hash(runtimeType,_this.additions,_this.deletions,_this.files);
}

@override
String toString() {
  final _this = this as ChangesSummary;
  return 'ChangesSummary(additions: ${_this.additions}, deletions: ${_this.deletions}, files: ${_this.files})';
}


}

/// @nodoc
abstract mixin class $ChangesSummaryCopyWith<$Res>  {
  factory $ChangesSummaryCopyWith(ChangesSummary value, $Res Function(ChangesSummary) _then) = _$ChangesSummaryCopyWithImpl;
@useResult
$Res call({
 int? additions, int? deletions, int? files
});




}
/// @nodoc
class _$ChangesSummaryCopyWithImpl<$Res>
    implements $ChangesSummaryCopyWith<$Res> {
  _$ChangesSummaryCopyWithImpl(this._self, this._then);

  final ChangesSummary _self;
  final $Res Function(ChangesSummary) _then;

/// Create a copy of ChangesSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? additions = freezed,Object? deletions = freezed,Object? files = freezed,}) {
  return _then(ChangesSummary(
additions: freezed == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int?,deletions: freezed == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int?,files: freezed == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChangesSummary].
extension ChangesSummaryPatterns on ChangesSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChangesSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChangesSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChangesSummary value)  $default,){
final _that = this;
switch (_that) {
case _ChangesSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChangesSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ChangesSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? additions,  int? deletions,  int? files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChangesSummary() when $default != null:
return $default(_that.additions,_that.deletions,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? additions,  int? deletions,  int? files)  $default,) {final _that = this;
switch (_that) {
case _ChangesSummary():
return $default(_that.additions,_that.deletions,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? additions,  int? deletions,  int? files)?  $default,) {final _that = this;
switch (_that) {
case _ChangesSummary() when $default != null:
return $default(_that.additions,_that.deletions,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChangesSummary implements ChangesSummary {
  const _ChangesSummary({this.additions, this.deletions, this.files});
  factory _ChangesSummary.fromJson(Map<String, dynamic> json) => _$ChangesSummaryFromJson(json);

/// Total inserted lines across all changed files.
@override final  int? additions;
/// Total deleted lines across all changed files.
@override final  int? deletions;
/// Number of files that have changes.
@override final  int? files;

/// Create a copy of ChangesSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChangesSummaryCopyWith<_ChangesSummary> get copyWith => __$ChangesSummaryCopyWithImpl<_ChangesSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChangesSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChangesSummary&&(identical(other.additions, additions) || other.additions == additions)&&(identical(other.deletions, deletions) || other.deletions == deletions)&&(identical(other.files, files) || other.files == files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,additions,deletions,files);
}

@override
String toString() {
    return 'ChangesSummary(additions: $additions, deletions: $deletions, files: $files)';
}


}

/// @nodoc
abstract mixin class _$ChangesSummaryCopyWith<$Res> implements $ChangesSummaryCopyWith<$Res> {
  factory _$ChangesSummaryCopyWith(_ChangesSummary value, $Res Function(_ChangesSummary) _then) = __$ChangesSummaryCopyWithImpl;
@override @useResult
$Res call({
 int? additions, int? deletions, int? files
});




}
/// @nodoc
class __$ChangesSummaryCopyWithImpl<$Res>
    implements _$ChangesSummaryCopyWith<$Res> {
  __$ChangesSummaryCopyWithImpl(this._self, this._then);

  final _ChangesSummary _self;
  final $Res Function(_ChangesSummary) _then;

/// Create a copy of ChangesSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? additions = freezed,Object? deletions = freezed,Object? files = freezed,}) {
  return _then(_ChangesSummary(
additions: freezed == additions ? _self.additions : additions // ignore: cast_nullable_to_non_nullable
as int?,deletions: freezed == deletions ? _self.deletions : deletions // ignore: cast_nullable_to_non_nullable
as int?,files: freezed == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SessionChatSummary {

/// Canonical chat URI.
 String get resource;/// Human-readable chat title.
 String get title;/// `full`, `readOnly` or `hidden`; absent means `full`.
 String? get interactivity;/// Chat status bits; absent means unknown.
@SessionStatusConverter() SessionStatus? get status;
/// Create a copy of SessionChatSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionChatSummaryCopyWith<SessionChatSummary> get copyWith => _$SessionChatSummaryCopyWithImpl<SessionChatSummary>(this as SessionChatSummary, _$identity);

  /// Serializes this SessionChatSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionChatSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionChatSummary&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.interactivity, _this.interactivity) || other.interactivity == _this.interactivity)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionChatSummary;
  return Object.hash(runtimeType,_this.resource,_this.title,_this.interactivity,_this.status);
}

@override
String toString() {
  final _this = this as SessionChatSummary;
  return 'SessionChatSummary(resource: ${_this.resource}, title: ${_this.title}, interactivity: ${_this.interactivity}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $SessionChatSummaryCopyWith<$Res>  {
  factory $SessionChatSummaryCopyWith(SessionChatSummary value, $Res Function(SessionChatSummary) _then) = _$SessionChatSummaryCopyWithImpl;
@useResult
$Res call({
 String resource, String title, String? interactivity,@SessionStatusConverter() SessionStatus? status
});




}
/// @nodoc
class _$SessionChatSummaryCopyWithImpl<$Res>
    implements $SessionChatSummaryCopyWith<$Res> {
  _$SessionChatSummaryCopyWithImpl(this._self, this._then);

  final SessionChatSummary _self;
  final $Res Function(SessionChatSummary) _then;

/// Create a copy of SessionChatSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? title = null,Object? interactivity = freezed,Object? status = freezed,}) {
  return _then(SessionChatSummary(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,interactivity: freezed == interactivity ? _self.interactivity : interactivity // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionChatSummary].
extension SessionChatSummaryPatterns on SessionChatSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionChatSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionChatSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionChatSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionChatSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionChatSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionChatSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resource,  String title,  String? interactivity, @SessionStatusConverter()  SessionStatus? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionChatSummary() when $default != null:
return $default(_that.resource,_that.title,_that.interactivity,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resource,  String title,  String? interactivity, @SessionStatusConverter()  SessionStatus? status)  $default,) {final _that = this;
switch (_that) {
case _SessionChatSummary():
return $default(_that.resource,_that.title,_that.interactivity,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resource,  String title,  String? interactivity, @SessionStatusConverter()  SessionStatus? status)?  $default,) {final _that = this;
switch (_that) {
case _SessionChatSummary() when $default != null:
return $default(_that.resource,_that.title,_that.interactivity,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionChatSummary implements SessionChatSummary {
  const _SessionChatSummary({required this.resource, required this.title, this.interactivity, @SessionStatusConverter() this.status});
  factory _SessionChatSummary.fromJson(Map<String, dynamic> json) => _$SessionChatSummaryFromJson(json);

/// Canonical chat URI.
@override final  String resource;
/// Human-readable chat title.
@override final  String title;
/// `full`, `readOnly` or `hidden`; absent means `full`.
@override final  String? interactivity;
/// Chat status bits; absent means unknown.
@override@SessionStatusConverter() final  SessionStatus? status;

/// Create a copy of SessionChatSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionChatSummaryCopyWith<_SessionChatSummary> get copyWith => __$SessionChatSummaryCopyWithImpl<_SessionChatSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionChatSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionChatSummary&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.title, title) || other.title == title)&&(identical(other.interactivity, interactivity) || other.interactivity == interactivity)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,resource,title,interactivity,status);
}

@override
String toString() {
    return 'SessionChatSummary(resource: $resource, title: $title, interactivity: $interactivity, status: $status)';
}


}

/// @nodoc
abstract mixin class _$SessionChatSummaryCopyWith<$Res> implements $SessionChatSummaryCopyWith<$Res> {
  factory _$SessionChatSummaryCopyWith(_SessionChatSummary value, $Res Function(_SessionChatSummary) _then) = __$SessionChatSummaryCopyWithImpl;
@override @useResult
$Res call({
 String resource, String title, String? interactivity,@SessionStatusConverter() SessionStatus? status
});




}
/// @nodoc
class __$SessionChatSummaryCopyWithImpl<$Res>
    implements _$SessionChatSummaryCopyWith<$Res> {
  __$SessionChatSummaryCopyWithImpl(this._self, this._then);

  final _SessionChatSummary _self;
  final $Res Function(_SessionChatSummary) _then;

/// Create a copy of SessionChatSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? title = null,Object? interactivity = freezed,Object? status = freezed,}) {
  return _then(_SessionChatSummary(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,interactivity: freezed == interactivity ? _self.interactivity : interactivity // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus?,
  ));
}


}


/// @nodoc
mixin _$SessionSummary {

/// Session URI. Treat as opaque: hosts may use `ahp-session:/<id>` or
/// their own scheme (pi uses `pi:/<id>`).
 String get resource;/// Agent provider ID.
 String get provider;/// Session title.
 String get title;/// Session status bitset.
@SessionStatusConverter() SessionStatus get status;/// Creation timestamp (ISO 8601).
 String get createdAt;/// Last modification timestamp (ISO 8601).
 String get modifiedAt;/// What the session is currently doing, e.g. `Running npm test`.
 String? get activity;/// Server-owned project.
 ProjectInfo? get project;/// Working directory URIs; the first is the primary one.
 List<String>? get workingDirectories;/// Aggregate file-change counts.
 ChangesSummary? get changes;/// Ordered chat catalogue.
 List<SessionChatSummary>? get chats;/// Chat that receives input when none is selected.
 String? get defaultChat;/// Server-defined presentation metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryCopyWith<SessionSummary> get copyWith => _$SessionSummaryCopyWithImpl<SessionSummary>(this as SessionSummary, _$identity);

  /// Serializes this SessionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummary&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.modifiedAt, _this.modifiedAt) || other.modifiedAt == _this.modifiedAt)&&(identical(other.activity, _this.activity) || other.activity == _this.activity)&&(identical(other.project, _this.project) || other.project == _this.project)&&const DeepCollectionEquality().equals(other.workingDirectories, _this.workingDirectories)&&(identical(other.changes, _this.changes) || other.changes == _this.changes)&&const DeepCollectionEquality().equals(other.chats, _this.chats)&&(identical(other.defaultChat, _this.defaultChat) || other.defaultChat == _this.defaultChat)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionSummary;
  return Object.hash(runtimeType,_this.resource,_this.provider,_this.title,_this.status,_this.createdAt,_this.modifiedAt,_this.activity,_this.project,const DeepCollectionEquality().hash(_this.workingDirectories),_this.changes,const DeepCollectionEquality().hash(_this.chats),_this.defaultChat,const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as SessionSummary;
  return 'SessionSummary(resource: ${_this.resource}, provider: ${_this.provider}, title: ${_this.title}, status: ${_this.status}, createdAt: ${_this.createdAt}, modifiedAt: ${_this.modifiedAt}, activity: ${_this.activity}, project: ${_this.project}, workingDirectories: ${_this.workingDirectories}, changes: ${_this.changes}, chats: ${_this.chats}, defaultChat: ${_this.defaultChat}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $SessionSummaryCopyWith<$Res>  {
  factory $SessionSummaryCopyWith(SessionSummary value, $Res Function(SessionSummary) _then) = _$SessionSummaryCopyWithImpl;
@useResult
$Res call({
 String resource, String provider, String title,@SessionStatusConverter() SessionStatus status, String createdAt, String modifiedAt, String? activity, ProjectInfo? project, List<String>? workingDirectories, ChangesSummary? changes, List<SessionChatSummary>? chats, String? defaultChat,@JsonKey(name: '_meta') JsonMap? meta
});


$ProjectInfoCopyWith<$Res>? get project;$ChangesSummaryCopyWith<$Res>? get changes;

}
/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._self, this._then);

  final SessionSummary _self;
  final $Res Function(SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? provider = null,Object? title = null,Object? status = null,Object? createdAt = null,Object? modifiedAt = null,Object? activity = freezed,Object? project = freezed,Object? workingDirectories = freezed,Object? changes = freezed,Object? chats = freezed,Object? defaultChat = freezed,Object? meta = freezed,}) {
  return _then(SessionSummary(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as String,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectInfo?,workingDirectories: freezed == workingDirectories ? _self.workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,changes: freezed == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as ChangesSummary?,chats: freezed == chats ? _self.chats : chats // ignore: cast_nullable_to_non_nullable
as List<SessionChatSummary>?,defaultChat: freezed == defaultChat ? _self.defaultChat : defaultChat // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectInfoCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectInfoCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChangesSummaryCopyWith<$Res>? get changes {
    if (_self.changes == null) {
    return null;
  }

  return $ChangesSummaryCopyWith<$Res>(_self.changes!, (value) {
    return _then(_self.copyWith(changes: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionSummary].
extension SessionSummaryPatterns on SessionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resource,  String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String createdAt,  String modifiedAt,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  ChangesSummary? changes,  List<SessionChatSummary>? chats,  String? defaultChat, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.resource,_that.provider,_that.title,_that.status,_that.createdAt,_that.modifiedAt,_that.activity,_that.project,_that.workingDirectories,_that.changes,_that.chats,_that.defaultChat,_that.meta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resource,  String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String createdAt,  String modifiedAt,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  ChangesSummary? changes,  List<SessionChatSummary>? chats,  String? defaultChat, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that.resource,_that.provider,_that.title,_that.status,_that.createdAt,_that.modifiedAt,_that.activity,_that.project,_that.workingDirectories,_that.changes,_that.chats,_that.defaultChat,_that.meta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resource,  String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String createdAt,  String modifiedAt,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  ChangesSummary? changes,  List<SessionChatSummary>? chats,  String? defaultChat, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.resource,_that.provider,_that.title,_that.status,_that.createdAt,_that.modifiedAt,_that.activity,_that.project,_that.workingDirectories,_that.changes,_that.chats,_that.defaultChat,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSummary implements SessionSummary {
  const _SessionSummary({required this.resource, required this.provider, required this.title, @SessionStatusConverter() required this.status, required this.createdAt, required this.modifiedAt, this.activity, this.project,  List<String>? workingDirectories, this.changes,  List<SessionChatSummary>? chats, this.defaultChat, @JsonKey(name: '_meta')  JsonMap? meta}): _workingDirectories = workingDirectories,_chats = chats,_meta = meta;
  factory _SessionSummary.fromJson(Map<String, dynamic> json) => _$SessionSummaryFromJson(json);

/// Session URI. Treat as opaque: hosts may use `ahp-session:/<id>` or
/// their own scheme (pi uses `pi:/<id>`).
@override final  String resource;
/// Agent provider ID.
@override final  String provider;
/// Session title.
@override final  String title;
/// Session status bitset.
@override@SessionStatusConverter() final  SessionStatus status;
/// Creation timestamp (ISO 8601).
@override final  String createdAt;
/// Last modification timestamp (ISO 8601).
@override final  String modifiedAt;
/// What the session is currently doing, e.g. `Running npm test`.
@override final  String? activity;
/// Server-owned project.
@override final  ProjectInfo? project;
/// Working directory URIs; the first is the primary one.
 final  List<String>? _workingDirectories;
/// Working directory URIs; the first is the primary one.
@override List<String>? get workingDirectories {
  final value = _workingDirectories;
  if (value == null) return null;
  if (_workingDirectories is EqualUnmodifiableListView) return _workingDirectories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Aggregate file-change counts.
@override final  ChangesSummary? changes;
/// Ordered chat catalogue.
 final  List<SessionChatSummary>? _chats;
/// Ordered chat catalogue.
@override List<SessionChatSummary>? get chats {
  final value = _chats;
  if (value == null) return null;
  if (_chats is EqualUnmodifiableListView) return _chats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Chat that receives input when none is selected.
@override final  String? defaultChat;
/// Server-defined presentation metadata.
 final  JsonMap? _meta;
/// Server-defined presentation metadata.
@override@JsonKey(name: '_meta') JsonMap? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryCopyWith<_SessionSummary> get copyWith => __$SessionSummaryCopyWithImpl<_SessionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummary&&(identical(other.resource, resource) || other.resource == resource)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.modifiedAt, modifiedAt) || other.modifiedAt == modifiedAt)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.project, project) || other.project == project)&&const DeepCollectionEquality().equals(other.workingDirectories, _workingDirectories)&&(identical(other.changes, changes) || other.changes == changes)&&const DeepCollectionEquality().equals(other.chats, _chats)&&(identical(other.defaultChat, defaultChat) || other.defaultChat == defaultChat)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,resource,provider,title,status,createdAt,modifiedAt,activity,project,const DeepCollectionEquality().hash(_workingDirectories),changes,const DeepCollectionEquality().hash(_chats),defaultChat,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'SessionSummary(resource: $resource, provider: $provider, title: $title, status: $status, createdAt: $createdAt, modifiedAt: $modifiedAt, activity: $activity, project: $project, workingDirectories: $workingDirectories, changes: $changes, chats: $chats, defaultChat: $defaultChat, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryCopyWith<$Res> implements $SessionSummaryCopyWith<$Res> {
  factory _$SessionSummaryCopyWith(_SessionSummary value, $Res Function(_SessionSummary) _then) = __$SessionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String resource, String provider, String title,@SessionStatusConverter() SessionStatus status, String createdAt, String modifiedAt, String? activity, ProjectInfo? project, List<String>? workingDirectories, ChangesSummary? changes, List<SessionChatSummary>? chats, String? defaultChat,@JsonKey(name: '_meta') JsonMap? meta
});


@override $ProjectInfoCopyWith<$Res>? get project;@override $ChangesSummaryCopyWith<$Res>? get changes;

}
/// @nodoc
class __$SessionSummaryCopyWithImpl<$Res>
    implements _$SessionSummaryCopyWith<$Res> {
  __$SessionSummaryCopyWithImpl(this._self, this._then);

  final _SessionSummary _self;
  final $Res Function(_SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? provider = null,Object? title = null,Object? status = null,Object? createdAt = null,Object? modifiedAt = null,Object? activity = freezed,Object? project = freezed,Object? workingDirectories = freezed,Object? changes = freezed,Object? chats = freezed,Object? defaultChat = freezed,Object? meta = freezed,}) {
  return _then(_SessionSummary(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,modifiedAt: null == modifiedAt ? _self.modifiedAt : modifiedAt // ignore: cast_nullable_to_non_nullable
as String,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectInfo?,workingDirectories: freezed == workingDirectories ? _self._workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,changes: freezed == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as ChangesSummary?,chats: freezed == chats ? _self._chats : chats // ignore: cast_nullable_to_non_nullable
as List<SessionChatSummary>?,defaultChat: freezed == defaultChat ? _self.defaultChat : defaultChat // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectInfoCopyWith<$Res>? get project {
    if (_self.project == null) {
    return null;
  }

  return $ProjectInfoCopyWith<$Res>(_self.project!, (value) {
    return _then(_self.copyWith(project: value));
  });
}/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChangesSummaryCopyWith<$Res>? get changes {
    if (_self.changes == null) {
    return null;
  }

  return $ChangesSummaryCopyWith<$Res>(_self.changes!, (value) {
    return _then(_self.copyWith(changes: value));
  });
}
}


/// @nodoc
mixin _$SessionModelInfo {

/// Model ID.
 String get id;/// Provider that serves the model.
 String get provider;/// Human-readable model name.
 String get name;/// Context window size in tokens.
 int? get maxContextWindow;/// Whether the model accepts images.
 bool? get supportsVision;/// `enabled`, `disabled` or `unconfigured`.
 String? get policyState;/// Per-model config schema (passed through).
 JsonMap? get configSchema;
/// Create a copy of SessionModelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionModelInfoCopyWith<SessionModelInfo> get copyWith => _$SessionModelInfoCopyWithImpl<SessionModelInfo>(this as SessionModelInfo, _$identity);

  /// Serializes this SessionModelInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionModelInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionModelInfo&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.maxContextWindow, _this.maxContextWindow) || other.maxContextWindow == _this.maxContextWindow)&&(identical(other.supportsVision, _this.supportsVision) || other.supportsVision == _this.supportsVision)&&(identical(other.policyState, _this.policyState) || other.policyState == _this.policyState)&&const DeepCollectionEquality().equals(other.configSchema, _this.configSchema));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionModelInfo;
  return Object.hash(runtimeType,_this.id,_this.provider,_this.name,_this.maxContextWindow,_this.supportsVision,_this.policyState,const DeepCollectionEquality().hash(_this.configSchema));
}

@override
String toString() {
  final _this = this as SessionModelInfo;
  return 'SessionModelInfo(id: ${_this.id}, provider: ${_this.provider}, name: ${_this.name}, maxContextWindow: ${_this.maxContextWindow}, supportsVision: ${_this.supportsVision}, policyState: ${_this.policyState}, configSchema: ${_this.configSchema})';
}


}

/// @nodoc
abstract mixin class $SessionModelInfoCopyWith<$Res>  {
  factory $SessionModelInfoCopyWith(SessionModelInfo value, $Res Function(SessionModelInfo) _then) = _$SessionModelInfoCopyWithImpl;
@useResult
$Res call({
 String id, String provider, String name, int? maxContextWindow, bool? supportsVision, String? policyState, JsonMap? configSchema
});




}
/// @nodoc
class _$SessionModelInfoCopyWithImpl<$Res>
    implements $SessionModelInfoCopyWith<$Res> {
  _$SessionModelInfoCopyWithImpl(this._self, this._then);

  final SessionModelInfo _self;
  final $Res Function(SessionModelInfo) _then;

/// Create a copy of SessionModelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provider = null,Object? name = null,Object? maxContextWindow = freezed,Object? supportsVision = freezed,Object? policyState = freezed,Object? configSchema = freezed,}) {
  return _then(SessionModelInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxContextWindow: freezed == maxContextWindow ? _self.maxContextWindow : maxContextWindow // ignore: cast_nullable_to_non_nullable
as int?,supportsVision: freezed == supportsVision ? _self.supportsVision : supportsVision // ignore: cast_nullable_to_non_nullable
as bool?,policyState: freezed == policyState ? _self.policyState : policyState // ignore: cast_nullable_to_non_nullable
as String?,configSchema: freezed == configSchema ? _self.configSchema : configSchema // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionModelInfo].
extension SessionModelInfoPatterns on SessionModelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionModelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionModelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionModelInfo value)  $default,){
final _that = this;
switch (_that) {
case _SessionModelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionModelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _SessionModelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String provider,  String name,  int? maxContextWindow,  bool? supportsVision,  String? policyState,  JsonMap? configSchema)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionModelInfo() when $default != null:
return $default(_that.id,_that.provider,_that.name,_that.maxContextWindow,_that.supportsVision,_that.policyState,_that.configSchema);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String provider,  String name,  int? maxContextWindow,  bool? supportsVision,  String? policyState,  JsonMap? configSchema)  $default,) {final _that = this;
switch (_that) {
case _SessionModelInfo():
return $default(_that.id,_that.provider,_that.name,_that.maxContextWindow,_that.supportsVision,_that.policyState,_that.configSchema);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String provider,  String name,  int? maxContextWindow,  bool? supportsVision,  String? policyState,  JsonMap? configSchema)?  $default,) {final _that = this;
switch (_that) {
case _SessionModelInfo() when $default != null:
return $default(_that.id,_that.provider,_that.name,_that.maxContextWindow,_that.supportsVision,_that.policyState,_that.configSchema);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionModelInfo implements SessionModelInfo {
  const _SessionModelInfo({required this.id, required this.provider, required this.name, this.maxContextWindow, this.supportsVision, this.policyState,  JsonMap? configSchema}): _configSchema = configSchema;
  factory _SessionModelInfo.fromJson(Map<String, dynamic> json) => _$SessionModelInfoFromJson(json);

/// Model ID.
@override final  String id;
/// Provider that serves the model.
@override final  String provider;
/// Human-readable model name.
@override final  String name;
/// Context window size in tokens.
@override final  int? maxContextWindow;
/// Whether the model accepts images.
@override final  bool? supportsVision;
/// `enabled`, `disabled` or `unconfigured`.
@override final  String? policyState;
/// Per-model config schema (passed through).
 final  JsonMap? _configSchema;
/// Per-model config schema (passed through).
@override JsonMap? get configSchema {
  final value = _configSchema;
  if (value == null) return null;
  if (_configSchema is EqualUnmodifiableMapView) return _configSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of SessionModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionModelInfoCopyWith<_SessionModelInfo> get copyWith => __$SessionModelInfoCopyWithImpl<_SessionModelInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionModelInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionModelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.name, name) || other.name == name)&&(identical(other.maxContextWindow, maxContextWindow) || other.maxContextWindow == maxContextWindow)&&(identical(other.supportsVision, supportsVision) || other.supportsVision == supportsVision)&&(identical(other.policyState, policyState) || other.policyState == policyState)&&const DeepCollectionEquality().equals(other.configSchema, _configSchema));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,provider,name,maxContextWindow,supportsVision,policyState,const DeepCollectionEquality().hash(_configSchema));
}

@override
String toString() {
    return 'SessionModelInfo(id: $id, provider: $provider, name: $name, maxContextWindow: $maxContextWindow, supportsVision: $supportsVision, policyState: $policyState, configSchema: $configSchema)';
}


}

/// @nodoc
abstract mixin class _$SessionModelInfoCopyWith<$Res> implements $SessionModelInfoCopyWith<$Res> {
  factory _$SessionModelInfoCopyWith(_SessionModelInfo value, $Res Function(_SessionModelInfo) _then) = __$SessionModelInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String provider, String name, int? maxContextWindow, bool? supportsVision, String? policyState, JsonMap? configSchema
});




}
/// @nodoc
class __$SessionModelInfoCopyWithImpl<$Res>
    implements _$SessionModelInfoCopyWith<$Res> {
  __$SessionModelInfoCopyWithImpl(this._self, this._then);

  final _SessionModelInfo _self;
  final $Res Function(_SessionModelInfo) _then;

/// Create a copy of SessionModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provider = null,Object? name = null,Object? maxContextWindow = freezed,Object? supportsVision = freezed,Object? policyState = freezed,Object? configSchema = freezed,}) {
  return _then(_SessionModelInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,maxContextWindow: freezed == maxContextWindow ? _self.maxContextWindow : maxContextWindow // ignore: cast_nullable_to_non_nullable
as int?,supportsVision: freezed == supportsVision ? _self.supportsVision : supportsVision // ignore: cast_nullable_to_non_nullable
as bool?,policyState: freezed == policyState ? _self.policyState : policyState // ignore: cast_nullable_to_non_nullable
as String?,configSchema: freezed == configSchema ? _self._configSchema : configSchema // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}


/// @nodoc
mixin _$AgentInfo {

/// Agent provider ID, used as `createSession.provider`.
 String get provider;/// Human-readable agent name.
 String get displayName;/// Agent description.
 String get description;/// Models the agent offers.
 List<SessionModelInfo> get models;/// RFC 9728 protected resources the agent needs tokens for.
 List<JsonMap>? get protectedResources;/// Agent capabilities (passed through).
 JsonMap? get capabilities;
/// Create a copy of AgentInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentInfoCopyWith<AgentInfo> get copyWith => _$AgentInfoCopyWithImpl<AgentInfo>(this as AgentInfo, _$identity);

  /// Serializes this AgentInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AgentInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentInfo&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.description, _this.description) || other.description == _this.description)&&const DeepCollectionEquality().equals(other.models, _this.models)&&const DeepCollectionEquality().equals(other.protectedResources, _this.protectedResources)&&const DeepCollectionEquality().equals(other.capabilities, _this.capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AgentInfo;
  return Object.hash(runtimeType,_this.provider,_this.displayName,_this.description,const DeepCollectionEquality().hash(_this.models),const DeepCollectionEquality().hash(_this.protectedResources),const DeepCollectionEquality().hash(_this.capabilities));
}

@override
String toString() {
  final _this = this as AgentInfo;
  return 'AgentInfo(provider: ${_this.provider}, displayName: ${_this.displayName}, description: ${_this.description}, models: ${_this.models}, protectedResources: ${_this.protectedResources}, capabilities: ${_this.capabilities})';
}


}

/// @nodoc
abstract mixin class $AgentInfoCopyWith<$Res>  {
  factory $AgentInfoCopyWith(AgentInfo value, $Res Function(AgentInfo) _then) = _$AgentInfoCopyWithImpl;
@useResult
$Res call({
 String provider, String displayName, String description, List<SessionModelInfo> models, List<JsonMap>? protectedResources, JsonMap? capabilities
});




}
/// @nodoc
class _$AgentInfoCopyWithImpl<$Res>
    implements $AgentInfoCopyWith<$Res> {
  _$AgentInfoCopyWithImpl(this._self, this._then);

  final AgentInfo _self;
  final $Res Function(AgentInfo) _then;

/// Create a copy of AgentInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? displayName = null,Object? description = null,Object? models = null,Object? protectedResources = freezed,Object? capabilities = freezed,}) {
  return _then(AgentInfo(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,models: null == models ? _self.models : models // ignore: cast_nullable_to_non_nullable
as List<SessionModelInfo>,protectedResources: freezed == protectedResources ? _self.protectedResources : protectedResources // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,capabilities: freezed == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentInfo].
extension AgentInfoPatterns on AgentInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentInfo value)  $default,){
final _that = this;
switch (_that) {
case _AgentInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentInfo value)?  $default,){
final _that = this;
switch (_that) {
case _AgentInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String displayName,  String description,  List<SessionModelInfo> models,  List<JsonMap>? protectedResources,  JsonMap? capabilities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentInfo() when $default != null:
return $default(_that.provider,_that.displayName,_that.description,_that.models,_that.protectedResources,_that.capabilities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String displayName,  String description,  List<SessionModelInfo> models,  List<JsonMap>? protectedResources,  JsonMap? capabilities)  $default,) {final _that = this;
switch (_that) {
case _AgentInfo():
return $default(_that.provider,_that.displayName,_that.description,_that.models,_that.protectedResources,_that.capabilities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String displayName,  String description,  List<SessionModelInfo> models,  List<JsonMap>? protectedResources,  JsonMap? capabilities)?  $default,) {final _that = this;
switch (_that) {
case _AgentInfo() when $default != null:
return $default(_that.provider,_that.displayName,_that.description,_that.models,_that.protectedResources,_that.capabilities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentInfo implements AgentInfo {
  const _AgentInfo({required this.provider, required this.displayName, required this.description,  List<SessionModelInfo> models = const <SessionModelInfo>[],  List<JsonMap>? protectedResources,  JsonMap? capabilities}): _models = models,_protectedResources = protectedResources,_capabilities = capabilities;
  factory _AgentInfo.fromJson(Map<String, dynamic> json) => _$AgentInfoFromJson(json);

/// Agent provider ID, used as `createSession.provider`.
@override final  String provider;
/// Human-readable agent name.
@override final  String displayName;
/// Agent description.
@override final  String description;
/// Models the agent offers.
 final  List<SessionModelInfo> _models;
/// Models the agent offers.
@override@JsonKey() List<SessionModelInfo> get models {
  if (_models is EqualUnmodifiableListView) return _models;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_models);
}

/// RFC 9728 protected resources the agent needs tokens for.
 final  List<JsonMap>? _protectedResources;
/// RFC 9728 protected resources the agent needs tokens for.
@override List<JsonMap>? get protectedResources {
  final value = _protectedResources;
  if (value == null) return null;
  if (_protectedResources is EqualUnmodifiableListView) return _protectedResources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Agent capabilities (passed through).
 final  JsonMap? _capabilities;
/// Agent capabilities (passed through).
@override JsonMap? get capabilities {
  final value = _capabilities;
  if (value == null) return null;
  if (_capabilities is EqualUnmodifiableMapView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AgentInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentInfoCopyWith<_AgentInfo> get copyWith => __$AgentInfoCopyWithImpl<_AgentInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentInfo&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.models, _models)&&const DeepCollectionEquality().equals(other.protectedResources, _protectedResources)&&const DeepCollectionEquality().equals(other.capabilities, _capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,provider,displayName,description,const DeepCollectionEquality().hash(_models),const DeepCollectionEquality().hash(_protectedResources),const DeepCollectionEquality().hash(_capabilities));
}

@override
String toString() {
    return 'AgentInfo(provider: $provider, displayName: $displayName, description: $description, models: $models, protectedResources: $protectedResources, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class _$AgentInfoCopyWith<$Res> implements $AgentInfoCopyWith<$Res> {
  factory _$AgentInfoCopyWith(_AgentInfo value, $Res Function(_AgentInfo) _then) = __$AgentInfoCopyWithImpl;
@override @useResult
$Res call({
 String provider, String displayName, String description, List<SessionModelInfo> models, List<JsonMap>? protectedResources, JsonMap? capabilities
});




}
/// @nodoc
class __$AgentInfoCopyWithImpl<$Res>
    implements _$AgentInfoCopyWith<$Res> {
  __$AgentInfoCopyWithImpl(this._self, this._then);

  final _AgentInfo _self;
  final $Res Function(_AgentInfo) _then;

/// Create a copy of AgentInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? displayName = null,Object? description = null,Object? models = null,Object? protectedResources = freezed,Object? capabilities = freezed,}) {
  return _then(_AgentInfo(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,models: null == models ? _self._models : models // ignore: cast_nullable_to_non_nullable
as List<SessionModelInfo>,protectedResources: freezed == protectedResources ? _self._protectedResources : protectedResources // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,capabilities: freezed == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}


}


/// @nodoc
mixin _$RootConfigState {

/// JSON Schema for the values.
 JsonMap get schema;/// Current config values.
 JsonMap get values;
/// Create a copy of RootConfigState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootConfigStateCopyWith<RootConfigState> get copyWith => _$RootConfigStateCopyWithImpl<RootConfigState>(this as RootConfigState, _$identity);

  /// Serializes this RootConfigState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RootConfigState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RootConfigState&&const DeepCollectionEquality().equals(other.schema, _this.schema)&&const DeepCollectionEquality().equals(other.values, _this.values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RootConfigState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.schema),const DeepCollectionEquality().hash(_this.values));
}

@override
String toString() {
  final _this = this as RootConfigState;
  return 'RootConfigState(schema: ${_this.schema}, values: ${_this.values})';
}


}

/// @nodoc
abstract mixin class $RootConfigStateCopyWith<$Res>  {
  factory $RootConfigStateCopyWith(RootConfigState value, $Res Function(RootConfigState) _then) = _$RootConfigStateCopyWithImpl;
@useResult
$Res call({
 JsonMap schema, JsonMap values
});




}
/// @nodoc
class _$RootConfigStateCopyWithImpl<$Res>
    implements $RootConfigStateCopyWith<$Res> {
  _$RootConfigStateCopyWithImpl(this._self, this._then);

  final RootConfigState _self;
  final $Res Function(RootConfigState) _then;

/// Create a copy of RootConfigState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schema = null,Object? values = null,}) {
  return _then(RootConfigState(
schema: null == schema ? _self.schema : schema // ignore: cast_nullable_to_non_nullable
as JsonMap,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as JsonMap,
  ));
}

}


/// Adds pattern-matching-related methods to [RootConfigState].
extension RootConfigStatePatterns on RootConfigState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RootConfigState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RootConfigState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RootConfigState value)  $default,){
final _that = this;
switch (_that) {
case _RootConfigState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RootConfigState value)?  $default,){
final _that = this;
switch (_that) {
case _RootConfigState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( JsonMap schema,  JsonMap values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RootConfigState() when $default != null:
return $default(_that.schema,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( JsonMap schema,  JsonMap values)  $default,) {final _that = this;
switch (_that) {
case _RootConfigState():
return $default(_that.schema,_that.values);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( JsonMap schema,  JsonMap values)?  $default,) {final _that = this;
switch (_that) {
case _RootConfigState() when $default != null:
return $default(_that.schema,_that.values);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RootConfigState implements RootConfigState {
  const _RootConfigState({required  JsonMap schema, required  JsonMap values}): _schema = schema,_values = values;
  factory _RootConfigState.fromJson(Map<String, dynamic> json) => _$RootConfigStateFromJson(json);

/// JSON Schema for the values.
 final  JsonMap _schema;
/// JSON Schema for the values.
@override JsonMap get schema {
  if (_schema is EqualUnmodifiableMapView) return _schema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_schema);
}

/// Current config values.
 final  JsonMap _values;
/// Current config values.
@override JsonMap get values {
  if (_values is EqualUnmodifiableMapView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_values);
}


/// Create a copy of RootConfigState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RootConfigStateCopyWith<_RootConfigState> get copyWith => __$RootConfigStateCopyWithImpl<_RootConfigState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootConfigStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RootConfigState&&const DeepCollectionEquality().equals(other.schema, _schema)&&const DeepCollectionEquality().equals(other.values, _values));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_schema),const DeepCollectionEquality().hash(_values));
}

@override
String toString() {
    return 'RootConfigState(schema: $schema, values: $values)';
}


}

/// @nodoc
abstract mixin class _$RootConfigStateCopyWith<$Res> implements $RootConfigStateCopyWith<$Res> {
  factory _$RootConfigStateCopyWith(_RootConfigState value, $Res Function(_RootConfigState) _then) = __$RootConfigStateCopyWithImpl;
@override @useResult
$Res call({
 JsonMap schema, JsonMap values
});




}
/// @nodoc
class __$RootConfigStateCopyWithImpl<$Res>
    implements _$RootConfigStateCopyWith<$Res> {
  __$RootConfigStateCopyWithImpl(this._self, this._then);

  final _RootConfigState _self;
  final $Res Function(_RootConfigState) _then;

/// Create a copy of RootConfigState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schema = null,Object? values = null,}) {
  return _then(_RootConfigState(
schema: null == schema ? _self._schema : schema // ignore: cast_nullable_to_non_nullable
as JsonMap,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as JsonMap,
  ));
}


}


/// @nodoc
mixin _$RootState {

/// Agents the host offers.
 List<AgentInfo> get agents;/// Number of sessions with a running turn.
 int? get activeSessions;/// Host terminals (passed through).
 List<JsonMap>? get terminals;/// Host configuration.
 RootConfigState? get config;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootStateCopyWith<RootState> get copyWith => _$RootStateCopyWithImpl<RootState>(this as RootState, _$identity);

  /// Serializes this RootState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RootState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RootState&&const DeepCollectionEquality().equals(other.agents, _this.agents)&&(identical(other.activeSessions, _this.activeSessions) || other.activeSessions == _this.activeSessions)&&const DeepCollectionEquality().equals(other.terminals, _this.terminals)&&(identical(other.config, _this.config) || other.config == _this.config)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RootState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.agents),_this.activeSessions,const DeepCollectionEquality().hash(_this.terminals),_this.config,const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as RootState;
  return 'RootState(agents: ${_this.agents}, activeSessions: ${_this.activeSessions}, terminals: ${_this.terminals}, config: ${_this.config}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $RootStateCopyWith<$Res>  {
  factory $RootStateCopyWith(RootState value, $Res Function(RootState) _then) = _$RootStateCopyWithImpl;
@useResult
$Res call({
 List<AgentInfo> agents, int? activeSessions, List<JsonMap>? terminals, RootConfigState? config,@JsonKey(name: '_meta') JsonMap? meta
});


$RootConfigStateCopyWith<$Res>? get config;

}
/// @nodoc
class _$RootStateCopyWithImpl<$Res>
    implements $RootStateCopyWith<$Res> {
  _$RootStateCopyWithImpl(this._self, this._then);

  final RootState _self;
  final $Res Function(RootState) _then;

/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? agents = null,Object? activeSessions = freezed,Object? terminals = freezed,Object? config = freezed,Object? meta = freezed,}) {
  return _then(RootState(
agents: null == agents ? _self.agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentInfo>,activeSessions: freezed == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int?,terminals: freezed == terminals ? _self.terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as RootConfigState?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RootConfigStateCopyWith<$Res>? get config {
    if (_self.config == null) {
    return null;
  }

  return $RootConfigStateCopyWith<$Res>(_self.config!, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [RootState].
extension RootStatePatterns on RootState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RootState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RootState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RootState value)  $default,){
final _that = this;
switch (_that) {
case _RootState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RootState value)?  $default,){
final _that = this;
switch (_that) {
case _RootState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AgentInfo> agents,  int? activeSessions,  List<JsonMap>? terminals,  RootConfigState? config, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RootState() when $default != null:
return $default(_that.agents,_that.activeSessions,_that.terminals,_that.config,_that.meta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AgentInfo> agents,  int? activeSessions,  List<JsonMap>? terminals,  RootConfigState? config, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _RootState():
return $default(_that.agents,_that.activeSessions,_that.terminals,_that.config,_that.meta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AgentInfo> agents,  int? activeSessions,  List<JsonMap>? terminals,  RootConfigState? config, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _RootState() when $default != null:
return $default(_that.agents,_that.activeSessions,_that.terminals,_that.config,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RootState implements RootState {
  const _RootState({ List<AgentInfo> agents = const <AgentInfo>[], this.activeSessions,  List<JsonMap>? terminals, this.config, @JsonKey(name: '_meta')  JsonMap? meta}): _agents = agents,_terminals = terminals,_meta = meta;
  factory _RootState.fromJson(Map<String, dynamic> json) => _$RootStateFromJson(json);

/// Agents the host offers.
 final  List<AgentInfo> _agents;
/// Agents the host offers.
@override@JsonKey() List<AgentInfo> get agents {
  if (_agents is EqualUnmodifiableListView) return _agents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agents);
}

/// Number of sessions with a running turn.
@override final  int? activeSessions;
/// Host terminals (passed through).
 final  List<JsonMap>? _terminals;
/// Host terminals (passed through).
@override List<JsonMap>? get terminals {
  final value = _terminals;
  if (value == null) return null;
  if (_terminals is EqualUnmodifiableListView) return _terminals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Host configuration.
@override final  RootConfigState? config;
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


/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RootStateCopyWith<_RootState> get copyWith => __$RootStateCopyWithImpl<_RootState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RootState&&const DeepCollectionEquality().equals(other.agents, _agents)&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions)&&const DeepCollectionEquality().equals(other.terminals, _terminals)&&(identical(other.config, config) || other.config == config)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_agents),activeSessions,const DeepCollectionEquality().hash(_terminals),config,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'RootState(agents: $agents, activeSessions: $activeSessions, terminals: $terminals, config: $config, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$RootStateCopyWith<$Res> implements $RootStateCopyWith<$Res> {
  factory _$RootStateCopyWith(_RootState value, $Res Function(_RootState) _then) = __$RootStateCopyWithImpl;
@override @useResult
$Res call({
 List<AgentInfo> agents, int? activeSessions, List<JsonMap>? terminals, RootConfigState? config,@JsonKey(name: '_meta') JsonMap? meta
});


@override $RootConfigStateCopyWith<$Res>? get config;

}
/// @nodoc
class __$RootStateCopyWithImpl<$Res>
    implements _$RootStateCopyWith<$Res> {
  __$RootStateCopyWithImpl(this._self, this._then);

  final _RootState _self;
  final $Res Function(_RootState) _then;

/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? agents = null,Object? activeSessions = freezed,Object? terminals = freezed,Object? config = freezed,Object? meta = freezed,}) {
  return _then(_RootState(
agents: null == agents ? _self._agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentInfo>,activeSessions: freezed == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int?,terminals: freezed == terminals ? _self._terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as RootConfigState?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of RootState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RootConfigStateCopyWith<$Res>? get config {
    if (_self.config == null) {
    return null;
  }

  return $RootConfigStateCopyWith<$Res>(_self.config!, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// @nodoc
mixin _$Snapshot {

/// The channel URI.
 String get resource;/// The channel state; decode it according to the channel kind.
 JsonMap get state;/// Server sequence the snapshot was taken at.
 int get fromSeq;
/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnapshotCopyWith<Snapshot> get copyWith => _$SnapshotCopyWithImpl<Snapshot>(this as Snapshot, _$identity);

  /// Serializes this Snapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Snapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Snapshot&&(identical(other.resource, _this.resource) || other.resource == _this.resource)&&const DeepCollectionEquality().equals(other.state, _this.state)&&(identical(other.fromSeq, _this.fromSeq) || other.fromSeq == _this.fromSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Snapshot;
  return Object.hash(runtimeType,_this.resource,const DeepCollectionEquality().hash(_this.state),_this.fromSeq);
}

@override
String toString() {
  final _this = this as Snapshot;
  return 'Snapshot(resource: ${_this.resource}, state: ${_this.state}, fromSeq: ${_this.fromSeq})';
}


}

/// @nodoc
abstract mixin class $SnapshotCopyWith<$Res>  {
  factory $SnapshotCopyWith(Snapshot value, $Res Function(Snapshot) _then) = _$SnapshotCopyWithImpl;
@useResult
$Res call({
 String resource, JsonMap state, int fromSeq
});




}
/// @nodoc
class _$SnapshotCopyWithImpl<$Res>
    implements $SnapshotCopyWith<$Res> {
  _$SnapshotCopyWithImpl(this._self, this._then);

  final Snapshot _self;
  final $Res Function(Snapshot) _then;

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? resource = null,Object? state = null,Object? fromSeq = null,}) {
  return _then(Snapshot(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as JsonMap,fromSeq: null == fromSeq ? _self.fromSeq : fromSeq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Snapshot].
extension SnapshotPatterns on Snapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Snapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Snapshot value)  $default,){
final _that = this;
switch (_that) {
case _Snapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Snapshot value)?  $default,){
final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String resource,  JsonMap state,  int fromSeq)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that.resource,_that.state,_that.fromSeq);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String resource,  JsonMap state,  int fromSeq)  $default,) {final _that = this;
switch (_that) {
case _Snapshot():
return $default(_that.resource,_that.state,_that.fromSeq);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String resource,  JsonMap state,  int fromSeq)?  $default,) {final _that = this;
switch (_that) {
case _Snapshot() when $default != null:
return $default(_that.resource,_that.state,_that.fromSeq);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Snapshot implements Snapshot {
  const _Snapshot({required this.resource, required  JsonMap state, required this.fromSeq}): _state = state;
  factory _Snapshot.fromJson(Map<String, dynamic> json) => _$SnapshotFromJson(json);

/// The channel URI.
@override final  String resource;
/// The channel state; decode it according to the channel kind.
 final  JsonMap _state;
/// The channel state; decode it according to the channel kind.
@override JsonMap get state {
  if (_state is EqualUnmodifiableMapView) return _state;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_state);
}

/// Server sequence the snapshot was taken at.
@override final  int fromSeq;

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnapshotCopyWith<_Snapshot> get copyWith => __$SnapshotCopyWithImpl<_Snapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Snapshot&&(identical(other.resource, resource) || other.resource == resource)&&const DeepCollectionEquality().equals(other.state, _state)&&(identical(other.fromSeq, fromSeq) || other.fromSeq == fromSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,resource,const DeepCollectionEquality().hash(_state),fromSeq);
}

@override
String toString() {
    return 'Snapshot(resource: $resource, state: $state, fromSeq: $fromSeq)';
}


}

/// @nodoc
abstract mixin class _$SnapshotCopyWith<$Res> implements $SnapshotCopyWith<$Res> {
  factory _$SnapshotCopyWith(_Snapshot value, $Res Function(_Snapshot) _then) = __$SnapshotCopyWithImpl;
@override @useResult
$Res call({
 String resource, JsonMap state, int fromSeq
});




}
/// @nodoc
class __$SnapshotCopyWithImpl<$Res>
    implements _$SnapshotCopyWith<$Res> {
  __$SnapshotCopyWithImpl(this._self, this._then);

  final _Snapshot _self;
  final $Res Function(_Snapshot) _then;

/// Create a copy of Snapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? resource = null,Object? state = null,Object? fromSeq = null,}) {
  return _then(_Snapshot(
resource: null == resource ? _self.resource : resource // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self._state : state // ignore: cast_nullable_to_non_nullable
as JsonMap,fromSeq: null == fromSeq ? _self.fromSeq : fromSeq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InitializeResult {

/// The negotiated protocol version.
 String get protocolVersion;/// The host's current server sequence.
 int get serverSeq;/// Snapshots for `initialSubscriptions`.
 List<Snapshot> get snapshots;/// Host name and version.
 Implementation? get serverInfo;/// Default working directory URI for new sessions.
 String? get defaultDirectory;/// Characters that trigger `completions` in the composer.
 List<String>? get completionTriggerCharacters;/// Prefix that marks a composer message as a terminal command.
 String? get terminalCommandPrefix;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InitializeResultCopyWith<InitializeResult> get copyWith => _$InitializeResultCopyWithImpl<InitializeResult>(this as InitializeResult, _$identity);

  /// Serializes this InitializeResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InitializeResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InitializeResult&&(identical(other.protocolVersion, _this.protocolVersion) || other.protocolVersion == _this.protocolVersion)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq)&&const DeepCollectionEquality().equals(other.snapshots, _this.snapshots)&&(identical(other.serverInfo, _this.serverInfo) || other.serverInfo == _this.serverInfo)&&(identical(other.defaultDirectory, _this.defaultDirectory) || other.defaultDirectory == _this.defaultDirectory)&&const DeepCollectionEquality().equals(other.completionTriggerCharacters, _this.completionTriggerCharacters)&&(identical(other.terminalCommandPrefix, _this.terminalCommandPrefix) || other.terminalCommandPrefix == _this.terminalCommandPrefix)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InitializeResult;
  return Object.hash(runtimeType,_this.protocolVersion,_this.serverSeq,const DeepCollectionEquality().hash(_this.snapshots),_this.serverInfo,_this.defaultDirectory,const DeepCollectionEquality().hash(_this.completionTriggerCharacters),_this.terminalCommandPrefix,const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as InitializeResult;
  return 'InitializeResult(protocolVersion: ${_this.protocolVersion}, serverSeq: ${_this.serverSeq}, snapshots: ${_this.snapshots}, serverInfo: ${_this.serverInfo}, defaultDirectory: ${_this.defaultDirectory}, completionTriggerCharacters: ${_this.completionTriggerCharacters}, terminalCommandPrefix: ${_this.terminalCommandPrefix}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $InitializeResultCopyWith<$Res>  {
  factory $InitializeResultCopyWith(InitializeResult value, $Res Function(InitializeResult) _then) = _$InitializeResultCopyWithImpl;
@useResult
$Res call({
 String protocolVersion, int serverSeq, List<Snapshot> snapshots, Implementation? serverInfo, String? defaultDirectory, List<String>? completionTriggerCharacters, String? terminalCommandPrefix,@JsonKey(name: '_meta') JsonMap? meta
});


$ImplementationCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class _$InitializeResultCopyWithImpl<$Res>
    implements $InitializeResultCopyWith<$Res> {
  _$InitializeResultCopyWithImpl(this._self, this._then);

  final InitializeResult _self;
  final $Res Function(InitializeResult) _then;

/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolVersion = null,Object? serverSeq = null,Object? snapshots = null,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? completionTriggerCharacters = freezed,Object? terminalCommandPrefix = freezed,Object? meta = freezed,}) {
  return _then(InitializeResult(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,snapshots: null == snapshots ? _self.snapshots : snapshots // ignore: cast_nullable_to_non_nullable
as List<Snapshot>,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,completionTriggerCharacters: freezed == completionTriggerCharacters ? _self.completionTriggerCharacters : completionTriggerCharacters // ignore: cast_nullable_to_non_nullable
as List<String>?,terminalCommandPrefix: freezed == terminalCommandPrefix ? _self.terminalCommandPrefix : terminalCommandPrefix // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImplementationCopyWith<$Res>? get serverInfo {
    if (_self.serverInfo == null) {
    return null;
  }

  return $ImplementationCopyWith<$Res>(_self.serverInfo!, (value) {
    return _then(_self.copyWith(serverInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [InitializeResult].
extension InitializeResultPatterns on InitializeResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InitializeResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InitializeResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InitializeResult value)  $default,){
final _that = this;
switch (_that) {
case _InitializeResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InitializeResult value)?  $default,){
final _that = this;
switch (_that) {
case _InitializeResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String protocolVersion,  int serverSeq,  List<Snapshot> snapshots,  Implementation? serverInfo,  String? defaultDirectory,  List<String>? completionTriggerCharacters,  String? terminalCommandPrefix, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InitializeResult() when $default != null:
return $default(_that.protocolVersion,_that.serverSeq,_that.snapshots,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.terminalCommandPrefix,_that.meta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String protocolVersion,  int serverSeq,  List<Snapshot> snapshots,  Implementation? serverInfo,  String? defaultDirectory,  List<String>? completionTriggerCharacters,  String? terminalCommandPrefix, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _InitializeResult():
return $default(_that.protocolVersion,_that.serverSeq,_that.snapshots,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.terminalCommandPrefix,_that.meta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String protocolVersion,  int serverSeq,  List<Snapshot> snapshots,  Implementation? serverInfo,  String? defaultDirectory,  List<String>? completionTriggerCharacters,  String? terminalCommandPrefix, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _InitializeResult() when $default != null:
return $default(_that.protocolVersion,_that.serverSeq,_that.snapshots,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.terminalCommandPrefix,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InitializeResult implements InitializeResult {
  const _InitializeResult({required this.protocolVersion, required this.serverSeq,  List<Snapshot> snapshots = const <Snapshot>[], this.serverInfo, this.defaultDirectory,  List<String>? completionTriggerCharacters, this.terminalCommandPrefix, @JsonKey(name: '_meta')  JsonMap? meta}): _snapshots = snapshots,_completionTriggerCharacters = completionTriggerCharacters,_meta = meta;
  factory _InitializeResult.fromJson(Map<String, dynamic> json) => _$InitializeResultFromJson(json);

/// The negotiated protocol version.
@override final  String protocolVersion;
/// The host's current server sequence.
@override final  int serverSeq;
/// Snapshots for `initialSubscriptions`.
 final  List<Snapshot> _snapshots;
/// Snapshots for `initialSubscriptions`.
@override@JsonKey() List<Snapshot> get snapshots {
  if (_snapshots is EqualUnmodifiableListView) return _snapshots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_snapshots);
}

/// Host name and version.
@override final  Implementation? serverInfo;
/// Default working directory URI for new sessions.
@override final  String? defaultDirectory;
/// Characters that trigger `completions` in the composer.
 final  List<String>? _completionTriggerCharacters;
/// Characters that trigger `completions` in the composer.
@override List<String>? get completionTriggerCharacters {
  final value = _completionTriggerCharacters;
  if (value == null) return null;
  if (_completionTriggerCharacters is EqualUnmodifiableListView) return _completionTriggerCharacters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Prefix that marks a composer message as a terminal command.
@override final  String? terminalCommandPrefix;
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


/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitializeResultCopyWith<_InitializeResult> get copyWith => __$InitializeResultCopyWithImpl<_InitializeResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InitializeResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InitializeResult&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq)&&const DeepCollectionEquality().equals(other.snapshots, _snapshots)&&(identical(other.serverInfo, serverInfo) || other.serverInfo == serverInfo)&&(identical(other.defaultDirectory, defaultDirectory) || other.defaultDirectory == defaultDirectory)&&const DeepCollectionEquality().equals(other.completionTriggerCharacters, _completionTriggerCharacters)&&(identical(other.terminalCommandPrefix, terminalCommandPrefix) || other.terminalCommandPrefix == terminalCommandPrefix)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,protocolVersion,serverSeq,const DeepCollectionEquality().hash(_snapshots),serverInfo,defaultDirectory,const DeepCollectionEquality().hash(_completionTriggerCharacters),terminalCommandPrefix,const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'InitializeResult(protocolVersion: $protocolVersion, serverSeq: $serverSeq, snapshots: $snapshots, serverInfo: $serverInfo, defaultDirectory: $defaultDirectory, completionTriggerCharacters: $completionTriggerCharacters, terminalCommandPrefix: $terminalCommandPrefix, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$InitializeResultCopyWith<$Res> implements $InitializeResultCopyWith<$Res> {
  factory _$InitializeResultCopyWith(_InitializeResult value, $Res Function(_InitializeResult) _then) = __$InitializeResultCopyWithImpl;
@override @useResult
$Res call({
 String protocolVersion, int serverSeq, List<Snapshot> snapshots, Implementation? serverInfo, String? defaultDirectory, List<String>? completionTriggerCharacters, String? terminalCommandPrefix,@JsonKey(name: '_meta') JsonMap? meta
});


@override $ImplementationCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class __$InitializeResultCopyWithImpl<$Res>
    implements _$InitializeResultCopyWith<$Res> {
  __$InitializeResultCopyWithImpl(this._self, this._then);

  final _InitializeResult _self;
  final $Res Function(_InitializeResult) _then;

/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolVersion = null,Object? serverSeq = null,Object? snapshots = null,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? completionTriggerCharacters = freezed,Object? terminalCommandPrefix = freezed,Object? meta = freezed,}) {
  return _then(_InitializeResult(
protocolVersion: null == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,snapshots: null == snapshots ? _self._snapshots : snapshots // ignore: cast_nullable_to_non_nullable
as List<Snapshot>,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,completionTriggerCharacters: freezed == completionTriggerCharacters ? _self._completionTriggerCharacters : completionTriggerCharacters // ignore: cast_nullable_to_non_nullable
as List<String>?,terminalCommandPrefix: freezed == terminalCommandPrefix ? _self.terminalCommandPrefix : terminalCommandPrefix // ignore: cast_nullable_to_non_nullable
as String?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of InitializeResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ImplementationCopyWith<$Res>? get serverInfo {
    if (_self.serverInfo == null) {
    return null;
  }

  return $ImplementationCopyWith<$Res>(_self.serverInfo!, (value) {
    return _then(_self.copyWith(serverInfo: value));
  });
}
}


/// @nodoc
mixin _$ListSessionsResult {

/// The sessions on this page.
 List<SessionSummary> get items;/// Cursor for the next page; absent on the last page.
 String? get nextCursor;
/// Create a copy of ListSessionsResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListSessionsResultCopyWith<ListSessionsResult> get copyWith => _$ListSessionsResultCopyWithImpl<ListSessionsResult>(this as ListSessionsResult, _$identity);

  /// Serializes this ListSessionsResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ListSessionsResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListSessionsResult&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.nextCursor, _this.nextCursor) || other.nextCursor == _this.nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ListSessionsResult;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.nextCursor);
}

@override
String toString() {
  final _this = this as ListSessionsResult;
  return 'ListSessionsResult(items: ${_this.items}, nextCursor: ${_this.nextCursor})';
}


}

/// @nodoc
abstract mixin class $ListSessionsResultCopyWith<$Res>  {
  factory $ListSessionsResultCopyWith(ListSessionsResult value, $Res Function(ListSessionsResult) _then) = _$ListSessionsResultCopyWithImpl;
@useResult
$Res call({
 List<SessionSummary> items, String? nextCursor
});




}
/// @nodoc
class _$ListSessionsResultCopyWithImpl<$Res>
    implements $ListSessionsResultCopyWith<$Res> {
  _$ListSessionsResultCopyWithImpl(this._self, this._then);

  final ListSessionsResult _self;
  final $Res Function(ListSessionsResult) _then;

/// Create a copy of ListSessionsResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(ListSessionsResult(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SessionSummary>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ListSessionsResult].
extension ListSessionsResultPatterns on ListSessionsResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListSessionsResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListSessionsResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListSessionsResult value)  $default,){
final _that = this;
switch (_that) {
case _ListSessionsResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListSessionsResult value)?  $default,){
final _that = this;
switch (_that) {
case _ListSessionsResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SessionSummary> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListSessionsResult() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SessionSummary> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _ListSessionsResult():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SessionSummary> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _ListSessionsResult() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListSessionsResult implements ListSessionsResult {
  const _ListSessionsResult({required  List<SessionSummary> items, this.nextCursor}): _items = items;
  factory _ListSessionsResult.fromJson(Map<String, dynamic> json) => _$ListSessionsResultFromJson(json);

/// The sessions on this page.
 final  List<SessionSummary> _items;
/// The sessions on this page.
@override List<SessionSummary> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Cursor for the next page; absent on the last page.
@override final  String? nextCursor;

/// Create a copy of ListSessionsResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListSessionsResultCopyWith<_ListSessionsResult> get copyWith => __$ListSessionsResultCopyWithImpl<_ListSessionsResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListSessionsResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListSessionsResult&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);
}

@override
String toString() {
    return 'ListSessionsResult(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$ListSessionsResultCopyWith<$Res> implements $ListSessionsResultCopyWith<$Res> {
  factory _$ListSessionsResultCopyWith(_ListSessionsResult value, $Res Function(_ListSessionsResult) _then) = __$ListSessionsResultCopyWithImpl;
@override @useResult
$Res call({
 List<SessionSummary> items, String? nextCursor
});




}
/// @nodoc
class __$ListSessionsResultCopyWithImpl<$Res>
    implements _$ListSessionsResultCopyWith<$Res> {
  __$ListSessionsResultCopyWithImpl(this._self, this._then);

  final _ListSessionsResult _self;
  final $Res Function(_ListSessionsResult) _then;

/// Create a copy of ListSessionsResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_ListSessionsResult(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SessionSummary>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ActionOrigin {

/// The dispatching client's ID.
 String get clientId;/// The client's sequence number for the action.
 int get clientSeq;
/// Create a copy of ActionOrigin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionOriginCopyWith<ActionOrigin> get copyWith => _$ActionOriginCopyWithImpl<ActionOrigin>(this as ActionOrigin, _$identity);

  /// Serializes this ActionOrigin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActionOrigin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionOrigin&&(identical(other.clientId, _this.clientId) || other.clientId == _this.clientId)&&(identical(other.clientSeq, _this.clientSeq) || other.clientSeq == _this.clientSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActionOrigin;
  return Object.hash(runtimeType,_this.clientId,_this.clientSeq);
}

@override
String toString() {
  final _this = this as ActionOrigin;
  return 'ActionOrigin(clientId: ${_this.clientId}, clientSeq: ${_this.clientSeq})';
}


}

/// @nodoc
abstract mixin class $ActionOriginCopyWith<$Res>  {
  factory $ActionOriginCopyWith(ActionOrigin value, $Res Function(ActionOrigin) _then) = _$ActionOriginCopyWithImpl;
@useResult
$Res call({
 String clientId, int clientSeq
});




}
/// @nodoc
class _$ActionOriginCopyWithImpl<$Res>
    implements $ActionOriginCopyWith<$Res> {
  _$ActionOriginCopyWithImpl(this._self, this._then);

  final ActionOrigin _self;
  final $Res Function(ActionOrigin) _then;

/// Create a copy of ActionOrigin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientId = null,Object? clientSeq = null,}) {
  return _then(ActionOrigin(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientSeq: null == clientSeq ? _self.clientSeq : clientSeq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionOrigin].
extension ActionOriginPatterns on ActionOrigin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionOrigin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionOrigin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionOrigin value)  $default,){
final _that = this;
switch (_that) {
case _ActionOrigin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionOrigin value)?  $default,){
final _that = this;
switch (_that) {
case _ActionOrigin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientId,  int clientSeq)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionOrigin() when $default != null:
return $default(_that.clientId,_that.clientSeq);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientId,  int clientSeq)  $default,) {final _that = this;
switch (_that) {
case _ActionOrigin():
return $default(_that.clientId,_that.clientSeq);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientId,  int clientSeq)?  $default,) {final _that = this;
switch (_that) {
case _ActionOrigin() when $default != null:
return $default(_that.clientId,_that.clientSeq);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionOrigin implements ActionOrigin {
  const _ActionOrigin({required this.clientId, required this.clientSeq});
  factory _ActionOrigin.fromJson(Map<String, dynamic> json) => _$ActionOriginFromJson(json);

/// The dispatching client's ID.
@override final  String clientId;
/// The client's sequence number for the action.
@override final  int clientSeq;

/// Create a copy of ActionOrigin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionOriginCopyWith<_ActionOrigin> get copyWith => __$ActionOriginCopyWithImpl<_ActionOrigin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionOriginToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionOrigin&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.clientSeq, clientSeq) || other.clientSeq == clientSeq));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientId,clientSeq);
}

@override
String toString() {
    return 'ActionOrigin(clientId: $clientId, clientSeq: $clientSeq)';
}


}

/// @nodoc
abstract mixin class _$ActionOriginCopyWith<$Res> implements $ActionOriginCopyWith<$Res> {
  factory _$ActionOriginCopyWith(_ActionOrigin value, $Res Function(_ActionOrigin) _then) = __$ActionOriginCopyWithImpl;
@override @useResult
$Res call({
 String clientId, int clientSeq
});




}
/// @nodoc
class __$ActionOriginCopyWithImpl<$Res>
    implements _$ActionOriginCopyWith<$Res> {
  __$ActionOriginCopyWithImpl(this._self, this._then);

  final _ActionOrigin _self;
  final $Res Function(_ActionOrigin) _then;

/// Create a copy of ActionOrigin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientId = null,Object? clientSeq = null,}) {
  return _then(_ActionOrigin(
clientId: null == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as String,clientSeq: null == clientSeq ? _self.clientSeq : clientSeq // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ActionEnvelope {

/// Channel URI the action belongs to.
 String get channel;/// The raw action; its `type` field selects the variant.
 JsonMap get action;/// The host's sequence number for this action.
 int get serverSeq;/// Who dispatched it; absent for host-originated actions.
 ActionOrigin? get origin;/// Set when the host rejected a client-dispatched action.
 String? get rejectionReason;
/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionEnvelopeCopyWith<ActionEnvelope> get copyWith => _$ActionEnvelopeCopyWithImpl<ActionEnvelope>(this as ActionEnvelope, _$identity);

  /// Serializes this ActionEnvelope to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActionEnvelope;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionEnvelope&&(identical(other.channel, _this.channel) || other.channel == _this.channel)&&const DeepCollectionEquality().equals(other.action, _this.action)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq)&&(identical(other.origin, _this.origin) || other.origin == _this.origin)&&(identical(other.rejectionReason, _this.rejectionReason) || other.rejectionReason == _this.rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActionEnvelope;
  return Object.hash(runtimeType,_this.channel,const DeepCollectionEquality().hash(_this.action),_this.serverSeq,_this.origin,_this.rejectionReason);
}

@override
String toString() {
  final _this = this as ActionEnvelope;
  return 'ActionEnvelope(channel: ${_this.channel}, action: ${_this.action}, serverSeq: ${_this.serverSeq}, origin: ${_this.origin}, rejectionReason: ${_this.rejectionReason})';
}


}

/// @nodoc
abstract mixin class $ActionEnvelopeCopyWith<$Res>  {
  factory $ActionEnvelopeCopyWith(ActionEnvelope value, $Res Function(ActionEnvelope) _then) = _$ActionEnvelopeCopyWithImpl;
@useResult
$Res call({
 String channel, JsonMap action, int serverSeq, ActionOrigin? origin, String? rejectionReason
});


$ActionOriginCopyWith<$Res>? get origin;

}
/// @nodoc
class _$ActionEnvelopeCopyWithImpl<$Res>
    implements $ActionEnvelopeCopyWith<$Res> {
  _$ActionEnvelopeCopyWithImpl(this._self, this._then);

  final ActionEnvelope _self;
  final $Res Function(ActionEnvelope) _then;

/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channel = null,Object? action = null,Object? serverSeq = null,Object? origin = freezed,Object? rejectionReason = freezed,}) {
  return _then(ActionEnvelope(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as JsonMap,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ActionOrigin?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActionOriginCopyWith<$Res>? get origin {
    if (_self.origin == null) {
    return null;
  }

  return $ActionOriginCopyWith<$Res>(_self.origin!, (value) {
    return _then(_self.copyWith(origin: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActionEnvelope].
extension ActionEnvelopePatterns on ActionEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _ActionEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _ActionEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String channel,  JsonMap action,  int serverSeq,  ActionOrigin? origin,  String? rejectionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionEnvelope() when $default != null:
return $default(_that.channel,_that.action,_that.serverSeq,_that.origin,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String channel,  JsonMap action,  int serverSeq,  ActionOrigin? origin,  String? rejectionReason)  $default,) {final _that = this;
switch (_that) {
case _ActionEnvelope():
return $default(_that.channel,_that.action,_that.serverSeq,_that.origin,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String channel,  JsonMap action,  int serverSeq,  ActionOrigin? origin,  String? rejectionReason)?  $default,) {final _that = this;
switch (_that) {
case _ActionEnvelope() when $default != null:
return $default(_that.channel,_that.action,_that.serverSeq,_that.origin,_that.rejectionReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionEnvelope implements ActionEnvelope {
  const _ActionEnvelope({required this.channel, required  JsonMap action, required this.serverSeq, this.origin, this.rejectionReason}): _action = action;
  factory _ActionEnvelope.fromJson(Map<String, dynamic> json) => _$ActionEnvelopeFromJson(json);

/// Channel URI the action belongs to.
@override final  String channel;
/// The raw action; its `type` field selects the variant.
 final  JsonMap _action;
/// The raw action; its `type` field selects the variant.
@override JsonMap get action {
  if (_action is EqualUnmodifiableMapView) return _action;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_action);
}

/// The host's sequence number for this action.
@override final  int serverSeq;
/// Who dispatched it; absent for host-originated actions.
@override final  ActionOrigin? origin;
/// Set when the host rejected a client-dispatched action.
@override final  String? rejectionReason;

/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionEnvelopeCopyWith<_ActionEnvelope> get copyWith => __$ActionEnvelopeCopyWithImpl<_ActionEnvelope>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionEnvelopeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionEnvelope&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other.action, _action)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq)&&(identical(other.origin, origin) || other.origin == origin)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,channel,const DeepCollectionEquality().hash(_action),serverSeq,origin,rejectionReason);
}

@override
String toString() {
    return 'ActionEnvelope(channel: $channel, action: $action, serverSeq: $serverSeq, origin: $origin, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class _$ActionEnvelopeCopyWith<$Res> implements $ActionEnvelopeCopyWith<$Res> {
  factory _$ActionEnvelopeCopyWith(_ActionEnvelope value, $Res Function(_ActionEnvelope) _then) = __$ActionEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 String channel, JsonMap action, int serverSeq, ActionOrigin? origin, String? rejectionReason
});


@override $ActionOriginCopyWith<$Res>? get origin;

}
/// @nodoc
class __$ActionEnvelopeCopyWithImpl<$Res>
    implements _$ActionEnvelopeCopyWith<$Res> {
  __$ActionEnvelopeCopyWithImpl(this._self, this._then);

  final _ActionEnvelope _self;
  final $Res Function(_ActionEnvelope) _then;

/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channel = null,Object? action = null,Object? serverSeq = null,Object? origin = freezed,Object? rejectionReason = freezed,}) {
  return _then(_ActionEnvelope(
channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self._action : action // ignore: cast_nullable_to_non_nullable
as JsonMap,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,origin: freezed == origin ? _self.origin : origin // ignore: cast_nullable_to_non_nullable
as ActionOrigin?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ActionEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActionOriginCopyWith<$Res>? get origin {
    if (_self.origin == null) {
    return null;
  }

  return $ActionOriginCopyWith<$Res>(_self.origin!, (value) {
    return _then(_self.copyWith(origin: value));
  });
}
}

ReconnectResult _$ReconnectResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'replay':
          return ReconnectReplay.fromJson(
            json
          );
                case 'snapshot':
          return ReconnectSnapshot.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ReconnectResult',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ReconnectResult {



  /// Serializes this ReconnectResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconnectResult);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ReconnectResult()';
}


}

/// @nodoc
class $ReconnectResultCopyWith<$Res>  {
$ReconnectResultCopyWith(ReconnectResult _, $Res Function(ReconnectResult) __);
}


/// Adds pattern-matching-related methods to [ReconnectResult].
extension ReconnectResultPatterns on ReconnectResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ReconnectReplay value)?  replay,TResult Function( ReconnectSnapshot value)?  snapshot,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ReconnectReplay() when replay != null:
return replay(_that);case ReconnectSnapshot() when snapshot != null:
return snapshot(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ReconnectReplay value)  replay,required TResult Function( ReconnectSnapshot value)  snapshot,}){
final _that = this;
switch (_that) {
case ReconnectReplay():
return replay(_that);case ReconnectSnapshot():
return snapshot(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ReconnectReplay value)?  replay,TResult? Function( ReconnectSnapshot value)?  snapshot,}){
final _that = this;
switch (_that) {
case ReconnectReplay() when replay != null:
return replay(_that);case ReconnectSnapshot() when snapshot != null:
return snapshot(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<ActionEnvelope> actions,  List<String> missing)?  replay,TResult Function( List<Snapshot> snapshots)?  snapshot,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ReconnectReplay() when replay != null:
return replay(_that.actions,_that.missing);case ReconnectSnapshot() when snapshot != null:
return snapshot(_that.snapshots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<ActionEnvelope> actions,  List<String> missing)  replay,required TResult Function( List<Snapshot> snapshots)  snapshot,}) {final _that = this;
switch (_that) {
case ReconnectReplay():
return replay(_that.actions,_that.missing);case ReconnectSnapshot():
return snapshot(_that.snapshots);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<ActionEnvelope> actions,  List<String> missing)?  replay,TResult? Function( List<Snapshot> snapshots)?  snapshot,}) {final _that = this;
switch (_that) {
case ReconnectReplay() when replay != null:
return replay(_that.actions,_that.missing);case ReconnectSnapshot() when snapshot != null:
return snapshot(_that.snapshots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ReconnectReplay implements ReconnectResult {
  const ReconnectReplay({required  List<ActionEnvelope> actions,  List<String> missing = const <String>[],  String? $type}): _actions = actions,_missing = missing,$type = $type ?? 'replay';
  factory ReconnectReplay.fromJson(Map<String, dynamic> json) => _$ReconnectReplayFromJson(json);

/// Actions to apply, in order.
 final  List<ActionEnvelope> _actions;
/// Actions to apply, in order.
 List<ActionEnvelope> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

/// Requested channels the host no longer has.
 final  List<String> _missing;
/// Requested channels the host no longer has.
@JsonKey() List<String> get missing {
  if (_missing is EqualUnmodifiableListView) return _missing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missing);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ReconnectResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconnectReplayCopyWith<ReconnectReplay> get copyWith => _$ReconnectReplayCopyWithImpl<ReconnectReplay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReconnectReplayToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconnectReplay&&const DeepCollectionEquality().equals(other.actions, _actions)&&const DeepCollectionEquality().equals(other.missing, _missing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_actions),const DeepCollectionEquality().hash(_missing));
}

@override
String toString() {
    return 'ReconnectResult.replay(actions: $actions, missing: $missing)';
}


}

/// @nodoc
abstract mixin class $ReconnectReplayCopyWith<$Res> implements $ReconnectResultCopyWith<$Res> {
  factory $ReconnectReplayCopyWith(ReconnectReplay value, $Res Function(ReconnectReplay) _then) = _$ReconnectReplayCopyWithImpl;
@useResult
$Res call({
 List<ActionEnvelope> actions, List<String> missing
});




}
/// @nodoc
class _$ReconnectReplayCopyWithImpl<$Res>
    implements $ReconnectReplayCopyWith<$Res> {
  _$ReconnectReplayCopyWithImpl(this._self, this._then);

  final ReconnectReplay _self;
  final $Res Function(ReconnectReplay) _then;

/// Create a copy of ReconnectResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? actions = null,Object? missing = null,}) {
  return _then(ReconnectReplay(
actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<ActionEnvelope>,missing: null == missing ? _self._missing : missing // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ReconnectSnapshot implements ReconnectResult {
  const ReconnectSnapshot({required  List<Snapshot> snapshots,  String? $type}): _snapshots = snapshots,$type = $type ?? 'snapshot';
  factory ReconnectSnapshot.fromJson(Map<String, dynamic> json) => _$ReconnectSnapshotFromJson(json);

/// Snapshots for the requested subscriptions.
 final  List<Snapshot> _snapshots;
/// Snapshots for the requested subscriptions.
 List<Snapshot> get snapshots {
  if (_snapshots is EqualUnmodifiableListView) return _snapshots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_snapshots);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ReconnectResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReconnectSnapshotCopyWith<ReconnectSnapshot> get copyWith => _$ReconnectSnapshotCopyWithImpl<ReconnectSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReconnectSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReconnectSnapshot&&const DeepCollectionEquality().equals(other.snapshots, _snapshots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_snapshots));
}

@override
String toString() {
    return 'ReconnectResult.snapshot(snapshots: $snapshots)';
}


}

/// @nodoc
abstract mixin class $ReconnectSnapshotCopyWith<$Res> implements $ReconnectResultCopyWith<$Res> {
  factory $ReconnectSnapshotCopyWith(ReconnectSnapshot value, $Res Function(ReconnectSnapshot) _then) = _$ReconnectSnapshotCopyWithImpl;
@useResult
$Res call({
 List<Snapshot> snapshots
});




}
/// @nodoc
class _$ReconnectSnapshotCopyWithImpl<$Res>
    implements $ReconnectSnapshotCopyWith<$Res> {
  _$ReconnectSnapshotCopyWithImpl(this._self, this._then);

  final ReconnectSnapshot _self;
  final $Res Function(ReconnectSnapshot) _then;

/// Create a copy of ReconnectResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshots = null,}) {
  return _then(ReconnectSnapshot(
snapshots: null == snapshots ? _self._snapshots : snapshots // ignore: cast_nullable_to_non_nullable
as List<Snapshot>,
  ));
}


}

RootAction _$RootActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'root/agentsChanged':
          return RootAgentsChanged.fromJson(
            json
          );
                case 'root/activeSessionsChanged':
          return RootActiveSessionsChanged.fromJson(
            json
          );
                case 'root/terminalsChanged':
          return RootTerminalsChanged.fromJson(
            json
          );
                case 'root/configChanged':
          return RootConfigChanged.fromJson(
            json
          );
        
          default:
            return RootUnknownAction.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$RootAction {



  /// Serializes this RootAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootAction);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RootAction()';
}


}

/// @nodoc
class $RootActionCopyWith<$Res>  {
$RootActionCopyWith(RootAction _, $Res Function(RootAction) __);
}


/// Adds pattern-matching-related methods to [RootAction].
extension RootActionPatterns on RootAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RootAgentsChanged value)?  agentsChanged,TResult Function( RootActiveSessionsChanged value)?  activeSessionsChanged,TResult Function( RootTerminalsChanged value)?  terminalsChanged,TResult Function( RootConfigChanged value)?  configChanged,TResult Function( RootUnknownAction value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RootAgentsChanged() when agentsChanged != null:
return agentsChanged(_that);case RootActiveSessionsChanged() when activeSessionsChanged != null:
return activeSessionsChanged(_that);case RootTerminalsChanged() when terminalsChanged != null:
return terminalsChanged(_that);case RootConfigChanged() when configChanged != null:
return configChanged(_that);case RootUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RootAgentsChanged value)  agentsChanged,required TResult Function( RootActiveSessionsChanged value)  activeSessionsChanged,required TResult Function( RootTerminalsChanged value)  terminalsChanged,required TResult Function( RootConfigChanged value)  configChanged,required TResult Function( RootUnknownAction value)  unknown,}){
final _that = this;
switch (_that) {
case RootAgentsChanged():
return agentsChanged(_that);case RootActiveSessionsChanged():
return activeSessionsChanged(_that);case RootTerminalsChanged():
return terminalsChanged(_that);case RootConfigChanged():
return configChanged(_that);case RootUnknownAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RootAgentsChanged value)?  agentsChanged,TResult? Function( RootActiveSessionsChanged value)?  activeSessionsChanged,TResult? Function( RootTerminalsChanged value)?  terminalsChanged,TResult? Function( RootConfigChanged value)?  configChanged,TResult? Function( RootUnknownAction value)?  unknown,}){
final _that = this;
switch (_that) {
case RootAgentsChanged() when agentsChanged != null:
return agentsChanged(_that);case RootActiveSessionsChanged() when activeSessionsChanged != null:
return activeSessionsChanged(_that);case RootTerminalsChanged() when terminalsChanged != null:
return terminalsChanged(_that);case RootConfigChanged() when configChanged != null:
return configChanged(_that);case RootUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<AgentInfo> agents)?  agentsChanged,TResult Function( int activeSessions)?  activeSessionsChanged,TResult Function( List<JsonMap> terminals)?  terminalsChanged,TResult Function( JsonMap config,  bool? replace)?  configChanged,TResult Function( String type)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RootAgentsChanged() when agentsChanged != null:
return agentsChanged(_that.agents);case RootActiveSessionsChanged() when activeSessionsChanged != null:
return activeSessionsChanged(_that.activeSessions);case RootTerminalsChanged() when terminalsChanged != null:
return terminalsChanged(_that.terminals);case RootConfigChanged() when configChanged != null:
return configChanged(_that.config,_that.replace);case RootUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<AgentInfo> agents)  agentsChanged,required TResult Function( int activeSessions)  activeSessionsChanged,required TResult Function( List<JsonMap> terminals)  terminalsChanged,required TResult Function( JsonMap config,  bool? replace)  configChanged,required TResult Function( String type)  unknown,}) {final _that = this;
switch (_that) {
case RootAgentsChanged():
return agentsChanged(_that.agents);case RootActiveSessionsChanged():
return activeSessionsChanged(_that.activeSessions);case RootTerminalsChanged():
return terminalsChanged(_that.terminals);case RootConfigChanged():
return configChanged(_that.config,_that.replace);case RootUnknownAction():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<AgentInfo> agents)?  agentsChanged,TResult? Function( int activeSessions)?  activeSessionsChanged,TResult? Function( List<JsonMap> terminals)?  terminalsChanged,TResult? Function( JsonMap config,  bool? replace)?  configChanged,TResult? Function( String type)?  unknown,}) {final _that = this;
switch (_that) {
case RootAgentsChanged() when agentsChanged != null:
return agentsChanged(_that.agents);case RootActiveSessionsChanged() when activeSessionsChanged != null:
return activeSessionsChanged(_that.activeSessions);case RootTerminalsChanged() when terminalsChanged != null:
return terminalsChanged(_that.terminals);case RootConfigChanged() when configChanged != null:
return configChanged(_that.config,_that.replace);case RootUnknownAction() when unknown != null:
return unknown(_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class RootAgentsChanged implements RootAction {
  const RootAgentsChanged({required  List<AgentInfo> agents,  String? $type}): _agents = agents,$type = $type ?? 'root/agentsChanged';
  factory RootAgentsChanged.fromJson(Map<String, dynamic> json) => _$RootAgentsChangedFromJson(json);

/// The new agent list.
 final  List<AgentInfo> _agents;
/// The new agent list.
 List<AgentInfo> get agents {
  if (_agents is EqualUnmodifiableListView) return _agents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_agents);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootAgentsChangedCopyWith<RootAgentsChanged> get copyWith => _$RootAgentsChangedCopyWithImpl<RootAgentsChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootAgentsChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootAgentsChanged&&const DeepCollectionEquality().equals(other.agents, _agents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_agents));
}

@override
String toString() {
    return 'RootAction.agentsChanged(agents: $agents)';
}


}

/// @nodoc
abstract mixin class $RootAgentsChangedCopyWith<$Res> implements $RootActionCopyWith<$Res> {
  factory $RootAgentsChangedCopyWith(RootAgentsChanged value, $Res Function(RootAgentsChanged) _then) = _$RootAgentsChangedCopyWithImpl;
@useResult
$Res call({
 List<AgentInfo> agents
});




}
/// @nodoc
class _$RootAgentsChangedCopyWithImpl<$Res>
    implements $RootAgentsChangedCopyWith<$Res> {
  _$RootAgentsChangedCopyWithImpl(this._self, this._then);

  final RootAgentsChanged _self;
  final $Res Function(RootAgentsChanged) _then;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? agents = null,}) {
  return _then(RootAgentsChanged(
agents: null == agents ? _self._agents : agents // ignore: cast_nullable_to_non_nullable
as List<AgentInfo>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RootActiveSessionsChanged implements RootAction {
  const RootActiveSessionsChanged({required this.activeSessions,  String? $type}): $type = $type ?? 'root/activeSessionsChanged';
  factory RootActiveSessionsChanged.fromJson(Map<String, dynamic> json) => _$RootActiveSessionsChangedFromJson(json);

/// Number of sessions with a running turn.
 final  int activeSessions;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootActiveSessionsChangedCopyWith<RootActiveSessionsChanged> get copyWith => _$RootActiveSessionsChangedCopyWithImpl<RootActiveSessionsChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootActiveSessionsChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootActiveSessionsChanged&&(identical(other.activeSessions, activeSessions) || other.activeSessions == activeSessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,activeSessions);
}

@override
String toString() {
    return 'RootAction.activeSessionsChanged(activeSessions: $activeSessions)';
}


}

/// @nodoc
abstract mixin class $RootActiveSessionsChangedCopyWith<$Res> implements $RootActionCopyWith<$Res> {
  factory $RootActiveSessionsChangedCopyWith(RootActiveSessionsChanged value, $Res Function(RootActiveSessionsChanged) _then) = _$RootActiveSessionsChangedCopyWithImpl;
@useResult
$Res call({
 int activeSessions
});




}
/// @nodoc
class _$RootActiveSessionsChangedCopyWithImpl<$Res>
    implements $RootActiveSessionsChangedCopyWith<$Res> {
  _$RootActiveSessionsChangedCopyWithImpl(this._self, this._then);

  final RootActiveSessionsChanged _self;
  final $Res Function(RootActiveSessionsChanged) _then;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? activeSessions = null,}) {
  return _then(RootActiveSessionsChanged(
activeSessions: null == activeSessions ? _self.activeSessions : activeSessions // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RootTerminalsChanged implements RootAction {
  const RootTerminalsChanged({required  List<JsonMap> terminals,  String? $type}): _terminals = terminals,$type = $type ?? 'root/terminalsChanged';
  factory RootTerminalsChanged.fromJson(Map<String, dynamic> json) => _$RootTerminalsChangedFromJson(json);

/// The new terminal list (passed through).
 final  List<JsonMap> _terminals;
/// The new terminal list (passed through).
 List<JsonMap> get terminals {
  if (_terminals is EqualUnmodifiableListView) return _terminals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_terminals);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootTerminalsChangedCopyWith<RootTerminalsChanged> get copyWith => _$RootTerminalsChangedCopyWithImpl<RootTerminalsChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootTerminalsChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootTerminalsChanged&&const DeepCollectionEquality().equals(other.terminals, _terminals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_terminals));
}

@override
String toString() {
    return 'RootAction.terminalsChanged(terminals: $terminals)';
}


}

/// @nodoc
abstract mixin class $RootTerminalsChangedCopyWith<$Res> implements $RootActionCopyWith<$Res> {
  factory $RootTerminalsChangedCopyWith(RootTerminalsChanged value, $Res Function(RootTerminalsChanged) _then) = _$RootTerminalsChangedCopyWithImpl;
@useResult
$Res call({
 List<JsonMap> terminals
});




}
/// @nodoc
class _$RootTerminalsChangedCopyWithImpl<$Res>
    implements $RootTerminalsChangedCopyWith<$Res> {
  _$RootTerminalsChangedCopyWithImpl(this._self, this._then);

  final RootTerminalsChanged _self;
  final $Res Function(RootTerminalsChanged) _then;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? terminals = null,}) {
  return _then(RootTerminalsChanged(
terminals: null == terminals ? _self._terminals : terminals // ignore: cast_nullable_to_non_nullable
as List<JsonMap>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RootConfigChanged implements RootAction {
  const RootConfigChanged({required  JsonMap config, this.replace,  String? $type}): _config = config,$type = $type ?? 'root/configChanged';
  factory RootConfigChanged.fromJson(Map<String, dynamic> json) => _$RootConfigChangedFromJson(json);

/// The changed values.
 final  JsonMap _config;
/// The changed values.
 JsonMap get config {
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_config);
}

/// Replace all values instead of merging.
 final  bool? replace;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootConfigChangedCopyWith<RootConfigChanged> get copyWith => _$RootConfigChangedCopyWithImpl<RootConfigChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootConfigChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootConfigChanged&&const DeepCollectionEquality().equals(other.config, _config)&&(identical(other.replace, replace) || other.replace == replace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_config),replace);
}

@override
String toString() {
    return 'RootAction.configChanged(config: $config, replace: $replace)';
}


}

/// @nodoc
abstract mixin class $RootConfigChangedCopyWith<$Res> implements $RootActionCopyWith<$Res> {
  factory $RootConfigChangedCopyWith(RootConfigChanged value, $Res Function(RootConfigChanged) _then) = _$RootConfigChangedCopyWithImpl;
@useResult
$Res call({
 JsonMap config, bool? replace
});




}
/// @nodoc
class _$RootConfigChangedCopyWithImpl<$Res>
    implements $RootConfigChangedCopyWith<$Res> {
  _$RootConfigChangedCopyWithImpl(this._self, this._then);

  final RootConfigChanged _self;
  final $Res Function(RootConfigChanged) _then;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? config = null,Object? replace = freezed,}) {
  return _then(RootConfigChanged(
config: null == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as JsonMap,replace: freezed == replace ? _self.replace : replace // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RootUnknownAction implements RootAction {
  const RootUnknownAction({required this.type});
  factory RootUnknownAction.fromJson(Map<String, dynamic> json) => _$RootUnknownActionFromJson(json);

/// The action's `type`.
 final  String type;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootUnknownActionCopyWith<RootUnknownAction> get copyWith => _$RootUnknownActionCopyWithImpl<RootUnknownAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootUnknownActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootUnknownAction&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'RootAction.unknown(type: $type)';
}


}

/// @nodoc
abstract mixin class $RootUnknownActionCopyWith<$Res> implements $RootActionCopyWith<$Res> {
  factory $RootUnknownActionCopyWith(RootUnknownAction value, $Res Function(RootUnknownAction) _then) = _$RootUnknownActionCopyWithImpl;
@useResult
$Res call({
 String type
});




}
/// @nodoc
class _$RootUnknownActionCopyWithImpl<$Res>
    implements $RootUnknownActionCopyWith<$Res> {
  _$RootUnknownActionCopyWithImpl(this._self, this._then);

  final RootUnknownAction _self;
  final $Res Function(RootUnknownAction) _then;

/// Create a copy of RootAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(RootUnknownAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
