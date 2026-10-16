// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_wire.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionState {

/// Agent provider ID.
 String get provider;/// Session title.
 String get title;/// Session status bitset. pi keeps the live status on the default chat
/// and the catalogue summary instead.
@SessionStatusConverter() SessionStatus get status;/// `creating`, `ready` or `failed`.
 String get lifecycle;/// Ordered chat catalogue.
 List<SessionChatSummary> get chats;/// Clients that contribute tools (passed through).
 List<JsonMap> get activeClients;/// Why creation failed (`failed` only).
 ErrorInfo? get creationError;/// What the session is doing.
 String? get activity;/// Server-owned project.
 ProjectInfo? get project;/// Working directory URIs; the first is the primary one.
 List<String>? get workingDirectories;/// Chat that receives input when none is selected.
 String? get defaultChat;/// Session config schema and values (passed through).
 JsonMap? get config;/// Session-level input requests (passed through).
 List<JsonMap>? get inputNeeded;/// Server-defined metadata.
@JsonKey(name: '_meta') JsonMap? get meta;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);

  /// Serializes this SessionState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.provider, _this.provider) || other.provider == _this.provider)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.lifecycle, _this.lifecycle) || other.lifecycle == _this.lifecycle)&&const DeepCollectionEquality().equals(other.chats, _this.chats)&&const DeepCollectionEquality().equals(other.activeClients, _this.activeClients)&&(identical(other.creationError, _this.creationError) || other.creationError == _this.creationError)&&(identical(other.activity, _this.activity) || other.activity == _this.activity)&&(identical(other.project, _this.project) || other.project == _this.project)&&const DeepCollectionEquality().equals(other.workingDirectories, _this.workingDirectories)&&(identical(other.defaultChat, _this.defaultChat) || other.defaultChat == _this.defaultChat)&&const DeepCollectionEquality().equals(other.config, _this.config)&&const DeepCollectionEquality().equals(other.inputNeeded, _this.inputNeeded)&&const DeepCollectionEquality().equals(other.meta, _this.meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionState;
  return Object.hash(runtimeType,_this.provider,_this.title,_this.status,_this.lifecycle,const DeepCollectionEquality().hash(_this.chats),const DeepCollectionEquality().hash(_this.activeClients),_this.creationError,_this.activity,_this.project,const DeepCollectionEquality().hash(_this.workingDirectories),_this.defaultChat,const DeepCollectionEquality().hash(_this.config),const DeepCollectionEquality().hash(_this.inputNeeded),const DeepCollectionEquality().hash(_this.meta));
}

@override
String toString() {
  final _this = this as SessionState;
  return 'SessionState(provider: ${_this.provider}, title: ${_this.title}, status: ${_this.status}, lifecycle: ${_this.lifecycle}, chats: ${_this.chats}, activeClients: ${_this.activeClients}, creationError: ${_this.creationError}, activity: ${_this.activity}, project: ${_this.project}, workingDirectories: ${_this.workingDirectories}, defaultChat: ${_this.defaultChat}, config: ${_this.config}, inputNeeded: ${_this.inputNeeded}, meta: ${_this.meta})';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 String provider, String title,@SessionStatusConverter() SessionStatus status, String lifecycle, List<SessionChatSummary> chats, List<JsonMap> activeClients, ErrorInfo? creationError, String? activity, ProjectInfo? project, List<String>? workingDirectories, String? defaultChat, JsonMap? config, List<JsonMap>? inputNeeded,@JsonKey(name: '_meta') JsonMap? meta
});


$ErrorInfoCopyWith<$Res>? get creationError;$ProjectInfoCopyWith<$Res>? get project;

}
/// @nodoc
class _$SessionStateCopyWithImpl<$Res>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._self, this._then);

  final SessionState _self;
  final $Res Function(SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provider = null,Object? title = null,Object? status = null,Object? lifecycle = null,Object? chats = null,Object? activeClients = null,Object? creationError = freezed,Object? activity = freezed,Object? project = freezed,Object? workingDirectories = freezed,Object? defaultChat = freezed,Object? config = freezed,Object? inputNeeded = freezed,Object? meta = freezed,}) {
  return _then(SessionState(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as String,chats: null == chats ? _self.chats : chats // ignore: cast_nullable_to_non_nullable
as List<SessionChatSummary>,activeClients: null == activeClients ? _self.activeClients : activeClients // ignore: cast_nullable_to_non_nullable
as List<JsonMap>,creationError: freezed == creationError ? _self.creationError : creationError // ignore: cast_nullable_to_non_nullable
as ErrorInfo?,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectInfo?,workingDirectories: freezed == workingDirectories ? _self.workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,defaultChat: freezed == defaultChat ? _self.defaultChat : defaultChat // ignore: cast_nullable_to_non_nullable
as String?,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as JsonMap?,inputNeeded: freezed == inputNeeded ? _self.inputNeeded : inputNeeded // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorInfoCopyWith<$Res>? get creationError {
    if (_self.creationError == null) {
    return null;
  }

  return $ErrorInfoCopyWith<$Res>(_self.creationError!, (value) {
    return _then(_self.copyWith(creationError: value));
  });
}/// Create a copy of SessionState
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
}
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionState value)  $default,){
final _that = this;
switch (_that) {
case _SessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String lifecycle,  List<SessionChatSummary> chats,  List<JsonMap> activeClients,  ErrorInfo? creationError,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  String? defaultChat,  JsonMap? config,  List<JsonMap>? inputNeeded, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.provider,_that.title,_that.status,_that.lifecycle,_that.chats,_that.activeClients,_that.creationError,_that.activity,_that.project,_that.workingDirectories,_that.defaultChat,_that.config,_that.inputNeeded,_that.meta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String lifecycle,  List<SessionChatSummary> chats,  List<JsonMap> activeClients,  ErrorInfo? creationError,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  String? defaultChat,  JsonMap? config,  List<JsonMap>? inputNeeded, @JsonKey(name: '_meta')  JsonMap? meta)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.provider,_that.title,_that.status,_that.lifecycle,_that.chats,_that.activeClients,_that.creationError,_that.activity,_that.project,_that.workingDirectories,_that.defaultChat,_that.config,_that.inputNeeded,_that.meta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String provider,  String title, @SessionStatusConverter()  SessionStatus status,  String lifecycle,  List<SessionChatSummary> chats,  List<JsonMap> activeClients,  ErrorInfo? creationError,  String? activity,  ProjectInfo? project,  List<String>? workingDirectories,  String? defaultChat,  JsonMap? config,  List<JsonMap>? inputNeeded, @JsonKey(name: '_meta')  JsonMap? meta)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.provider,_that.title,_that.status,_that.lifecycle,_that.chats,_that.activeClients,_that.creationError,_that.activity,_that.project,_that.workingDirectories,_that.defaultChat,_that.config,_that.inputNeeded,_that.meta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionState implements SessionState {
  const _SessionState({required this.provider, required this.title, @SessionStatusConverter() required this.status, required this.lifecycle,  List<SessionChatSummary> chats = const <SessionChatSummary>[],  List<JsonMap> activeClients = const <JsonMap>[], this.creationError, this.activity, this.project,  List<String>? workingDirectories, this.defaultChat,  JsonMap? config,  List<JsonMap>? inputNeeded, @JsonKey(name: '_meta')  JsonMap? meta}): _chats = chats,_activeClients = activeClients,_workingDirectories = workingDirectories,_config = config,_inputNeeded = inputNeeded,_meta = meta;
  factory _SessionState.fromJson(Map<String, dynamic> json) => _$SessionStateFromJson(json);

/// Agent provider ID.
@override final  String provider;
/// Session title.
@override final  String title;
/// Session status bitset. pi keeps the live status on the default chat
/// and the catalogue summary instead.
@override@SessionStatusConverter() final  SessionStatus status;
/// `creating`, `ready` or `failed`.
@override final  String lifecycle;
/// Ordered chat catalogue.
 final  List<SessionChatSummary> _chats;
/// Ordered chat catalogue.
@override@JsonKey() List<SessionChatSummary> get chats {
  if (_chats is EqualUnmodifiableListView) return _chats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_chats);
}

/// Clients that contribute tools (passed through).
 final  List<JsonMap> _activeClients;
/// Clients that contribute tools (passed through).
@override@JsonKey() List<JsonMap> get activeClients {
  if (_activeClients is EqualUnmodifiableListView) return _activeClients;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeClients);
}

/// Why creation failed (`failed` only).
@override final  ErrorInfo? creationError;
/// What the session is doing.
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

/// Chat that receives input when none is selected.
@override final  String? defaultChat;
/// Session config schema and values (passed through).
 final  JsonMap? _config;
/// Session config schema and values (passed through).
@override JsonMap? get config {
  final value = _config;
  if (value == null) return null;
  if (_config is EqualUnmodifiableMapView) return _config;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Session-level input requests (passed through).
 final  List<JsonMap>? _inputNeeded;
/// Session-level input requests (passed through).
@override List<JsonMap>? get inputNeeded {
  final value = _inputNeeded;
  if (value == null) return null;
  if (_inputNeeded is EqualUnmodifiableListView) return _inputNeeded;
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


/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.lifecycle, lifecycle) || other.lifecycle == lifecycle)&&const DeepCollectionEquality().equals(other.chats, _chats)&&const DeepCollectionEquality().equals(other.activeClients, _activeClients)&&(identical(other.creationError, creationError) || other.creationError == creationError)&&(identical(other.activity, activity) || other.activity == activity)&&(identical(other.project, project) || other.project == project)&&const DeepCollectionEquality().equals(other.workingDirectories, _workingDirectories)&&(identical(other.defaultChat, defaultChat) || other.defaultChat == defaultChat)&&const DeepCollectionEquality().equals(other.config, _config)&&const DeepCollectionEquality().equals(other.inputNeeded, _inputNeeded)&&const DeepCollectionEquality().equals(other.meta, _meta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,provider,title,status,lifecycle,const DeepCollectionEquality().hash(_chats),const DeepCollectionEquality().hash(_activeClients),creationError,activity,project,const DeepCollectionEquality().hash(_workingDirectories),defaultChat,const DeepCollectionEquality().hash(_config),const DeepCollectionEquality().hash(_inputNeeded),const DeepCollectionEquality().hash(_meta));
}

@override
String toString() {
    return 'SessionState(provider: $provider, title: $title, status: $status, lifecycle: $lifecycle, chats: $chats, activeClients: $activeClients, creationError: $creationError, activity: $activity, project: $project, workingDirectories: $workingDirectories, defaultChat: $defaultChat, config: $config, inputNeeded: $inputNeeded, meta: $meta)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 String provider, String title,@SessionStatusConverter() SessionStatus status, String lifecycle, List<SessionChatSummary> chats, List<JsonMap> activeClients, ErrorInfo? creationError, String? activity, ProjectInfo? project, List<String>? workingDirectories, String? defaultChat, JsonMap? config, List<JsonMap>? inputNeeded,@JsonKey(name: '_meta') JsonMap? meta
});


@override $ErrorInfoCopyWith<$Res>? get creationError;@override $ProjectInfoCopyWith<$Res>? get project;

}
/// @nodoc
class __$SessionStateCopyWithImpl<$Res>
    implements _$SessionStateCopyWith<$Res> {
  __$SessionStateCopyWithImpl(this._self, this._then);

  final _SessionState _self;
  final $Res Function(_SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provider = null,Object? title = null,Object? status = null,Object? lifecycle = null,Object? chats = null,Object? activeClients = null,Object? creationError = freezed,Object? activity = freezed,Object? project = freezed,Object? workingDirectories = freezed,Object? defaultChat = freezed,Object? config = freezed,Object? inputNeeded = freezed,Object? meta = freezed,}) {
  return _then(_SessionState(
provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,lifecycle: null == lifecycle ? _self.lifecycle : lifecycle // ignore: cast_nullable_to_non_nullable
as String,chats: null == chats ? _self._chats : chats // ignore: cast_nullable_to_non_nullable
as List<SessionChatSummary>,activeClients: null == activeClients ? _self._activeClients : activeClients // ignore: cast_nullable_to_non_nullable
as List<JsonMap>,creationError: freezed == creationError ? _self.creationError : creationError // ignore: cast_nullable_to_non_nullable
as ErrorInfo?,activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,project: freezed == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as ProjectInfo?,workingDirectories: freezed == workingDirectories ? _self._workingDirectories : workingDirectories // ignore: cast_nullable_to_non_nullable
as List<String>?,defaultChat: freezed == defaultChat ? _self.defaultChat : defaultChat // ignore: cast_nullable_to_non_nullable
as String?,config: freezed == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as JsonMap?,inputNeeded: freezed == inputNeeded ? _self._inputNeeded : inputNeeded // ignore: cast_nullable_to_non_nullable
as List<JsonMap>?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as JsonMap?,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorInfoCopyWith<$Res>? get creationError {
    if (_self.creationError == null) {
    return null;
  }

  return $ErrorInfoCopyWith<$Res>(_self.creationError!, (value) {
    return _then(_self.copyWith(creationError: value));
  });
}/// Create a copy of SessionState
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
}
}

SessionAction _$SessionActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'session/ready':
          return SessionReady.fromJson(
            json
          );
                case 'session/creationFailed':
          return SessionCreationFailed.fromJson(
            json
          );
                case 'session/chatAdded':
          return SessionChatAdded.fromJson(
            json
          );
                case 'session/chatRemoved':
          return SessionChatRemoved.fromJson(
            json
          );
                case 'session/chatUpdated':
          return SessionChatUpdated.fromJson(
            json
          );
                case 'session/defaultChatChanged':
          return SessionDefaultChatChanged.fromJson(
            json
          );
                case 'session/titleChanged':
          return SessionTitleChanged.fromJson(
            json
          );
                case 'session/isReadChanged':
          return SessionIsReadChanged.fromJson(
            json
          );
                case 'session/isArchivedChanged':
          return SessionIsArchivedChanged.fromJson(
            json
          );
                case 'session/activityChanged':
          return SessionActivityChanged.fromJson(
            json
          );
                case 'session/configChanged':
          return SessionConfigChanged.fromJson(
            json
          );
        
          default:
            return SessionUnknownAction.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$SessionAction {



  /// Serializes this SessionAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionAction);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionAction()';
}


}

/// @nodoc
class $SessionActionCopyWith<$Res>  {
$SessionActionCopyWith(SessionAction _, $Res Function(SessionAction) __);
}


/// Adds pattern-matching-related methods to [SessionAction].
extension SessionActionPatterns on SessionAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionReady value)?  ready,TResult Function( SessionCreationFailed value)?  creationFailed,TResult Function( SessionChatAdded value)?  chatAdded,TResult Function( SessionChatRemoved value)?  chatRemoved,TResult Function( SessionChatUpdated value)?  chatUpdated,TResult Function( SessionDefaultChatChanged value)?  defaultChatChanged,TResult Function( SessionTitleChanged value)?  titleChanged,TResult Function( SessionIsReadChanged value)?  isReadChanged,TResult Function( SessionIsArchivedChanged value)?  isArchivedChanged,TResult Function( SessionActivityChanged value)?  activityChanged,TResult Function( SessionConfigChanged value)?  configChanged,TResult Function( SessionUnknownAction value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionReady() when ready != null:
return ready(_that);case SessionCreationFailed() when creationFailed != null:
return creationFailed(_that);case SessionChatAdded() when chatAdded != null:
return chatAdded(_that);case SessionChatRemoved() when chatRemoved != null:
return chatRemoved(_that);case SessionChatUpdated() when chatUpdated != null:
return chatUpdated(_that);case SessionDefaultChatChanged() when defaultChatChanged != null:
return defaultChatChanged(_that);case SessionTitleChanged() when titleChanged != null:
return titleChanged(_that);case SessionIsReadChanged() when isReadChanged != null:
return isReadChanged(_that);case SessionIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that);case SessionActivityChanged() when activityChanged != null:
return activityChanged(_that);case SessionConfigChanged() when configChanged != null:
return configChanged(_that);case SessionUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionReady value)  ready,required TResult Function( SessionCreationFailed value)  creationFailed,required TResult Function( SessionChatAdded value)  chatAdded,required TResult Function( SessionChatRemoved value)  chatRemoved,required TResult Function( SessionChatUpdated value)  chatUpdated,required TResult Function( SessionDefaultChatChanged value)  defaultChatChanged,required TResult Function( SessionTitleChanged value)  titleChanged,required TResult Function( SessionIsReadChanged value)  isReadChanged,required TResult Function( SessionIsArchivedChanged value)  isArchivedChanged,required TResult Function( SessionActivityChanged value)  activityChanged,required TResult Function( SessionConfigChanged value)  configChanged,required TResult Function( SessionUnknownAction value)  unknown,}){
final _that = this;
switch (_that) {
case SessionReady():
return ready(_that);case SessionCreationFailed():
return creationFailed(_that);case SessionChatAdded():
return chatAdded(_that);case SessionChatRemoved():
return chatRemoved(_that);case SessionChatUpdated():
return chatUpdated(_that);case SessionDefaultChatChanged():
return defaultChatChanged(_that);case SessionTitleChanged():
return titleChanged(_that);case SessionIsReadChanged():
return isReadChanged(_that);case SessionIsArchivedChanged():
return isArchivedChanged(_that);case SessionActivityChanged():
return activityChanged(_that);case SessionConfigChanged():
return configChanged(_that);case SessionUnknownAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionReady value)?  ready,TResult? Function( SessionCreationFailed value)?  creationFailed,TResult? Function( SessionChatAdded value)?  chatAdded,TResult? Function( SessionChatRemoved value)?  chatRemoved,TResult? Function( SessionChatUpdated value)?  chatUpdated,TResult? Function( SessionDefaultChatChanged value)?  defaultChatChanged,TResult? Function( SessionTitleChanged value)?  titleChanged,TResult? Function( SessionIsReadChanged value)?  isReadChanged,TResult? Function( SessionIsArchivedChanged value)?  isArchivedChanged,TResult? Function( SessionActivityChanged value)?  activityChanged,TResult? Function( SessionConfigChanged value)?  configChanged,TResult? Function( SessionUnknownAction value)?  unknown,}){
final _that = this;
switch (_that) {
case SessionReady() when ready != null:
return ready(_that);case SessionCreationFailed() when creationFailed != null:
return creationFailed(_that);case SessionChatAdded() when chatAdded != null:
return chatAdded(_that);case SessionChatRemoved() when chatRemoved != null:
return chatRemoved(_that);case SessionChatUpdated() when chatUpdated != null:
return chatUpdated(_that);case SessionDefaultChatChanged() when defaultChatChanged != null:
return defaultChatChanged(_that);case SessionTitleChanged() when titleChanged != null:
return titleChanged(_that);case SessionIsReadChanged() when isReadChanged != null:
return isReadChanged(_that);case SessionIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that);case SessionActivityChanged() when activityChanged != null:
return activityChanged(_that);case SessionConfigChanged() when configChanged != null:
return configChanged(_that);case SessionUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ready,TResult Function( ErrorInfo error)?  creationFailed,TResult Function( SessionChatSummary summary)?  chatAdded,TResult Function( String chat)?  chatRemoved,TResult Function( String chat,  JsonMap changes)?  chatUpdated,TResult Function( String? defaultChat)?  defaultChatChanged,TResult Function( String title)?  titleChanged,TResult Function( bool isRead)?  isReadChanged,TResult Function( bool isArchived)?  isArchivedChanged,TResult Function( String? activity)?  activityChanged,TResult Function( JsonMap config,  bool? replace)?  configChanged,TResult Function( String type)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionReady() when ready != null:
return ready();case SessionCreationFailed() when creationFailed != null:
return creationFailed(_that.error);case SessionChatAdded() when chatAdded != null:
return chatAdded(_that.summary);case SessionChatRemoved() when chatRemoved != null:
return chatRemoved(_that.chat);case SessionChatUpdated() when chatUpdated != null:
return chatUpdated(_that.chat,_that.changes);case SessionDefaultChatChanged() when defaultChatChanged != null:
return defaultChatChanged(_that.defaultChat);case SessionTitleChanged() when titleChanged != null:
return titleChanged(_that.title);case SessionIsReadChanged() when isReadChanged != null:
return isReadChanged(_that.isRead);case SessionIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that.isArchived);case SessionActivityChanged() when activityChanged != null:
return activityChanged(_that.activity);case SessionConfigChanged() when configChanged != null:
return configChanged(_that.config,_that.replace);case SessionUnknownAction() when unknown != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ready,required TResult Function( ErrorInfo error)  creationFailed,required TResult Function( SessionChatSummary summary)  chatAdded,required TResult Function( String chat)  chatRemoved,required TResult Function( String chat,  JsonMap changes)  chatUpdated,required TResult Function( String? defaultChat)  defaultChatChanged,required TResult Function( String title)  titleChanged,required TResult Function( bool isRead)  isReadChanged,required TResult Function( bool isArchived)  isArchivedChanged,required TResult Function( String? activity)  activityChanged,required TResult Function( JsonMap config,  bool? replace)  configChanged,required TResult Function( String type)  unknown,}) {final _that = this;
switch (_that) {
case SessionReady():
return ready();case SessionCreationFailed():
return creationFailed(_that.error);case SessionChatAdded():
return chatAdded(_that.summary);case SessionChatRemoved():
return chatRemoved(_that.chat);case SessionChatUpdated():
return chatUpdated(_that.chat,_that.changes);case SessionDefaultChatChanged():
return defaultChatChanged(_that.defaultChat);case SessionTitleChanged():
return titleChanged(_that.title);case SessionIsReadChanged():
return isReadChanged(_that.isRead);case SessionIsArchivedChanged():
return isArchivedChanged(_that.isArchived);case SessionActivityChanged():
return activityChanged(_that.activity);case SessionConfigChanged():
return configChanged(_that.config,_that.replace);case SessionUnknownAction():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ready,TResult? Function( ErrorInfo error)?  creationFailed,TResult? Function( SessionChatSummary summary)?  chatAdded,TResult? Function( String chat)?  chatRemoved,TResult? Function( String chat,  JsonMap changes)?  chatUpdated,TResult? Function( String? defaultChat)?  defaultChatChanged,TResult? Function( String title)?  titleChanged,TResult? Function( bool isRead)?  isReadChanged,TResult? Function( bool isArchived)?  isArchivedChanged,TResult? Function( String? activity)?  activityChanged,TResult? Function( JsonMap config,  bool? replace)?  configChanged,TResult? Function( String type)?  unknown,}) {final _that = this;
switch (_that) {
case SessionReady() when ready != null:
return ready();case SessionCreationFailed() when creationFailed != null:
return creationFailed(_that.error);case SessionChatAdded() when chatAdded != null:
return chatAdded(_that.summary);case SessionChatRemoved() when chatRemoved != null:
return chatRemoved(_that.chat);case SessionChatUpdated() when chatUpdated != null:
return chatUpdated(_that.chat,_that.changes);case SessionDefaultChatChanged() when defaultChatChanged != null:
return defaultChatChanged(_that.defaultChat);case SessionTitleChanged() when titleChanged != null:
return titleChanged(_that.title);case SessionIsReadChanged() when isReadChanged != null:
return isReadChanged(_that.isRead);case SessionIsArchivedChanged() when isArchivedChanged != null:
return isArchivedChanged(_that.isArchived);case SessionActivityChanged() when activityChanged != null:
return activityChanged(_that.activity);case SessionConfigChanged() when configChanged != null:
return configChanged(_that.config,_that.replace);case SessionUnknownAction() when unknown != null:
return unknown(_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SessionReady implements SessionAction {
  const SessionReady({ String? $type}): $type = $type ?? 'session/ready';
  factory SessionReady.fromJson(Map<String, dynamic> json) => _$SessionReadyFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$SessionReadyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionReady);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionAction.ready()';
}


}




/// @nodoc
@JsonSerializable()

class SessionCreationFailed implements SessionAction {
  const SessionCreationFailed({required this.error,  String? $type}): $type = $type ?? 'session/creationFailed';
  factory SessionCreationFailed.fromJson(Map<String, dynamic> json) => _$SessionCreationFailedFromJson(json);

/// The error.
 final  ErrorInfo error;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCreationFailedCopyWith<SessionCreationFailed> get copyWith => _$SessionCreationFailedCopyWithImpl<SessionCreationFailed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionCreationFailedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionCreationFailed&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,error);
}

@override
String toString() {
    return 'SessionAction.creationFailed(error: $error)';
}


}

/// @nodoc
abstract mixin class $SessionCreationFailedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionCreationFailedCopyWith(SessionCreationFailed value, $Res Function(SessionCreationFailed) _then) = _$SessionCreationFailedCopyWithImpl;
@useResult
$Res call({
 ErrorInfo error
});


$ErrorInfoCopyWith<$Res> get error;

}
/// @nodoc
class _$SessionCreationFailedCopyWithImpl<$Res>
    implements $SessionCreationFailedCopyWith<$Res> {
  _$SessionCreationFailedCopyWithImpl(this._self, this._then);

  final SessionCreationFailed _self;
  final $Res Function(SessionCreationFailed) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(SessionCreationFailed(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ErrorInfo,
  ));
}

/// Create a copy of SessionAction
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

class SessionChatAdded implements SessionAction {
  const SessionChatAdded({required this.summary,  String? $type}): $type = $type ?? 'session/chatAdded';
  factory SessionChatAdded.fromJson(Map<String, dynamic> json) => _$SessionChatAddedFromJson(json);

/// The chat.
 final  SessionChatSummary summary;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionChatAddedCopyWith<SessionChatAdded> get copyWith => _$SessionChatAddedCopyWithImpl<SessionChatAdded>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionChatAddedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionChatAdded&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,summary);
}

@override
String toString() {
    return 'SessionAction.chatAdded(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $SessionChatAddedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionChatAddedCopyWith(SessionChatAdded value, $Res Function(SessionChatAdded) _then) = _$SessionChatAddedCopyWithImpl;
@useResult
$Res call({
 SessionChatSummary summary
});


$SessionChatSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$SessionChatAddedCopyWithImpl<$Res>
    implements $SessionChatAddedCopyWith<$Res> {
  _$SessionChatAddedCopyWithImpl(this._self, this._then);

  final SessionChatAdded _self;
  final $Res Function(SessionChatAdded) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(SessionChatAdded(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as SessionChatSummary,
  ));
}

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionChatSummaryCopyWith<$Res> get summary {
  
  return $SessionChatSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class SessionChatRemoved implements SessionAction {
  const SessionChatRemoved({required this.chat,  String? $type}): $type = $type ?? 'session/chatRemoved';
  factory SessionChatRemoved.fromJson(Map<String, dynamic> json) => _$SessionChatRemovedFromJson(json);

/// Chat URI.
 final  String chat;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionChatRemovedCopyWith<SessionChatRemoved> get copyWith => _$SessionChatRemovedCopyWithImpl<SessionChatRemoved>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionChatRemovedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionChatRemoved&&(identical(other.chat, chat) || other.chat == chat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chat);
}

@override
String toString() {
    return 'SessionAction.chatRemoved(chat: $chat)';
}


}

/// @nodoc
abstract mixin class $SessionChatRemovedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionChatRemovedCopyWith(SessionChatRemoved value, $Res Function(SessionChatRemoved) _then) = _$SessionChatRemovedCopyWithImpl;
@useResult
$Res call({
 String chat
});




}
/// @nodoc
class _$SessionChatRemovedCopyWithImpl<$Res>
    implements $SessionChatRemovedCopyWith<$Res> {
  _$SessionChatRemovedCopyWithImpl(this._self, this._then);

  final SessionChatRemoved _self;
  final $Res Function(SessionChatRemoved) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chat = null,}) {
  return _then(SessionChatRemoved(
chat: null == chat ? _self.chat : chat // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionChatUpdated implements SessionAction {
  const SessionChatUpdated({required this.chat, required  JsonMap changes,  String? $type}): _changes = changes,$type = $type ?? 'session/chatUpdated';
  factory SessionChatUpdated.fromJson(Map<String, dynamic> json) => _$SessionChatUpdatedFromJson(json);

/// Chat URI.
 final  String chat;
/// Changed fields.
 final  JsonMap _changes;
/// Changed fields.
 JsonMap get changes {
  if (_changes is EqualUnmodifiableMapView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_changes);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionChatUpdatedCopyWith<SessionChatUpdated> get copyWith => _$SessionChatUpdatedCopyWithImpl<SessionChatUpdated>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionChatUpdatedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionChatUpdated&&(identical(other.chat, chat) || other.chat == chat)&&const DeepCollectionEquality().equals(other.changes, _changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,chat,const DeepCollectionEquality().hash(_changes));
}

@override
String toString() {
    return 'SessionAction.chatUpdated(chat: $chat, changes: $changes)';
}


}

/// @nodoc
abstract mixin class $SessionChatUpdatedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionChatUpdatedCopyWith(SessionChatUpdated value, $Res Function(SessionChatUpdated) _then) = _$SessionChatUpdatedCopyWithImpl;
@useResult
$Res call({
 String chat, JsonMap changes
});




}
/// @nodoc
class _$SessionChatUpdatedCopyWithImpl<$Res>
    implements $SessionChatUpdatedCopyWith<$Res> {
  _$SessionChatUpdatedCopyWithImpl(this._self, this._then);

  final SessionChatUpdated _self;
  final $Res Function(SessionChatUpdated) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? chat = null,Object? changes = null,}) {
  return _then(SessionChatUpdated(
chat: null == chat ? _self.chat : chat // ignore: cast_nullable_to_non_nullable
as String,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as JsonMap,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionDefaultChatChanged implements SessionAction {
  const SessionDefaultChatChanged({this.defaultChat,  String? $type}): $type = $type ?? 'session/defaultChatChanged';
  factory SessionDefaultChatChanged.fromJson(Map<String, dynamic> json) => _$SessionDefaultChatChangedFromJson(json);

/// The new default chat.
 final  String? defaultChat;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDefaultChatChangedCopyWith<SessionDefaultChatChanged> get copyWith => _$SessionDefaultChatChangedCopyWithImpl<SessionDefaultChatChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionDefaultChatChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDefaultChatChanged&&(identical(other.defaultChat, defaultChat) || other.defaultChat == defaultChat));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,defaultChat);
}

@override
String toString() {
    return 'SessionAction.defaultChatChanged(defaultChat: $defaultChat)';
}


}

/// @nodoc
abstract mixin class $SessionDefaultChatChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionDefaultChatChangedCopyWith(SessionDefaultChatChanged value, $Res Function(SessionDefaultChatChanged) _then) = _$SessionDefaultChatChangedCopyWithImpl;
@useResult
$Res call({
 String? defaultChat
});




}
/// @nodoc
class _$SessionDefaultChatChangedCopyWithImpl<$Res>
    implements $SessionDefaultChatChangedCopyWith<$Res> {
  _$SessionDefaultChatChangedCopyWithImpl(this._self, this._then);

  final SessionDefaultChatChanged _self;
  final $Res Function(SessionDefaultChatChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? defaultChat = freezed,}) {
  return _then(SessionDefaultChatChanged(
defaultChat: freezed == defaultChat ? _self.defaultChat : defaultChat // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionTitleChanged implements SessionAction {
  const SessionTitleChanged({required this.title,  String? $type}): $type = $type ?? 'session/titleChanged';
  factory SessionTitleChanged.fromJson(Map<String, dynamic> json) => _$SessionTitleChangedFromJson(json);

/// The new title.
 final  String title;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionTitleChangedCopyWith<SessionTitleChanged> get copyWith => _$SessionTitleChangedCopyWithImpl<SessionTitleChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionTitleChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionTitleChanged&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title);
}

@override
String toString() {
    return 'SessionAction.titleChanged(title: $title)';
}


}

/// @nodoc
abstract mixin class $SessionTitleChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionTitleChangedCopyWith(SessionTitleChanged value, $Res Function(SessionTitleChanged) _then) = _$SessionTitleChangedCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class _$SessionTitleChangedCopyWithImpl<$Res>
    implements $SessionTitleChangedCopyWith<$Res> {
  _$SessionTitleChangedCopyWithImpl(this._self, this._then);

  final SessionTitleChanged _self;
  final $Res Function(SessionTitleChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(SessionTitleChanged(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionIsReadChanged implements SessionAction {
  const SessionIsReadChanged({required this.isRead,  String? $type}): $type = $type ?? 'session/isReadChanged';
  factory SessionIsReadChanged.fromJson(Map<String, dynamic> json) => _$SessionIsReadChangedFromJson(json);

/// Whether the session is read.
 final  bool isRead;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionIsReadChangedCopyWith<SessionIsReadChanged> get copyWith => _$SessionIsReadChangedCopyWithImpl<SessionIsReadChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionIsReadChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionIsReadChanged&&(identical(other.isRead, isRead) || other.isRead == isRead));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isRead);
}

@override
String toString() {
    return 'SessionAction.isReadChanged(isRead: $isRead)';
}


}

/// @nodoc
abstract mixin class $SessionIsReadChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionIsReadChangedCopyWith(SessionIsReadChanged value, $Res Function(SessionIsReadChanged) _then) = _$SessionIsReadChangedCopyWithImpl;
@useResult
$Res call({
 bool isRead
});




}
/// @nodoc
class _$SessionIsReadChangedCopyWithImpl<$Res>
    implements $SessionIsReadChangedCopyWith<$Res> {
  _$SessionIsReadChangedCopyWithImpl(this._self, this._then);

  final SessionIsReadChanged _self;
  final $Res Function(SessionIsReadChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isRead = null,}) {
  return _then(SessionIsReadChanged(
isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionIsArchivedChanged implements SessionAction {
  const SessionIsArchivedChanged({required this.isArchived,  String? $type}): $type = $type ?? 'session/isArchivedChanged';
  factory SessionIsArchivedChanged.fromJson(Map<String, dynamic> json) => _$SessionIsArchivedChangedFromJson(json);

/// Whether the session is archived.
 final  bool isArchived;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionIsArchivedChangedCopyWith<SessionIsArchivedChanged> get copyWith => _$SessionIsArchivedChangedCopyWithImpl<SessionIsArchivedChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionIsArchivedChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionIsArchivedChanged&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,isArchived);
}

@override
String toString() {
    return 'SessionAction.isArchivedChanged(isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $SessionIsArchivedChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionIsArchivedChangedCopyWith(SessionIsArchivedChanged value, $Res Function(SessionIsArchivedChanged) _then) = _$SessionIsArchivedChangedCopyWithImpl;
@useResult
$Res call({
 bool isArchived
});




}
/// @nodoc
class _$SessionIsArchivedChangedCopyWithImpl<$Res>
    implements $SessionIsArchivedChangedCopyWith<$Res> {
  _$SessionIsArchivedChangedCopyWithImpl(this._self, this._then);

  final SessionIsArchivedChanged _self;
  final $Res Function(SessionIsArchivedChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isArchived = null,}) {
  return _then(SessionIsArchivedChanged(
isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionActivityChanged implements SessionAction {
  const SessionActivityChanged({this.activity,  String? $type}): $type = $type ?? 'session/activityChanged';
  factory SessionActivityChanged.fromJson(Map<String, dynamic> json) => _$SessionActivityChangedFromJson(json);

/// New activity, or null when idle.
 final  String? activity;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionActivityChangedCopyWith<SessionActivityChanged> get copyWith => _$SessionActivityChangedCopyWithImpl<SessionActivityChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionActivityChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionActivityChanged&&(identical(other.activity, activity) || other.activity == activity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,activity);
}

@override
String toString() {
    return 'SessionAction.activityChanged(activity: $activity)';
}


}

/// @nodoc
abstract mixin class $SessionActivityChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionActivityChangedCopyWith(SessionActivityChanged value, $Res Function(SessionActivityChanged) _then) = _$SessionActivityChangedCopyWithImpl;
@useResult
$Res call({
 String? activity
});




}
/// @nodoc
class _$SessionActivityChangedCopyWithImpl<$Res>
    implements $SessionActivityChangedCopyWith<$Res> {
  _$SessionActivityChangedCopyWithImpl(this._self, this._then);

  final SessionActivityChanged _self;
  final $Res Function(SessionActivityChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? activity = freezed,}) {
  return _then(SessionActivityChanged(
activity: freezed == activity ? _self.activity : activity // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionConfigChanged implements SessionAction {
  const SessionConfigChanged({required  JsonMap config, this.replace,  String? $type}): _config = config,$type = $type ?? 'session/configChanged';
  factory SessionConfigChanged.fromJson(Map<String, dynamic> json) => _$SessionConfigChangedFromJson(json);

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


/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionConfigChangedCopyWith<SessionConfigChanged> get copyWith => _$SessionConfigChangedCopyWithImpl<SessionConfigChanged>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionConfigChangedToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionConfigChanged&&const DeepCollectionEquality().equals(other.config, _config)&&(identical(other.replace, replace) || other.replace == replace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_config),replace);
}

@override
String toString() {
    return 'SessionAction.configChanged(config: $config, replace: $replace)';
}


}

/// @nodoc
abstract mixin class $SessionConfigChangedCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionConfigChangedCopyWith(SessionConfigChanged value, $Res Function(SessionConfigChanged) _then) = _$SessionConfigChangedCopyWithImpl;
@useResult
$Res call({
 JsonMap config, bool? replace
});




}
/// @nodoc
class _$SessionConfigChangedCopyWithImpl<$Res>
    implements $SessionConfigChangedCopyWith<$Res> {
  _$SessionConfigChangedCopyWithImpl(this._self, this._then);

  final SessionConfigChanged _self;
  final $Res Function(SessionConfigChanged) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? config = null,Object? replace = freezed,}) {
  return _then(SessionConfigChanged(
config: null == config ? _self._config : config // ignore: cast_nullable_to_non_nullable
as JsonMap,replace: freezed == replace ? _self.replace : replace // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SessionUnknownAction implements SessionAction {
  const SessionUnknownAction({required this.type});
  factory SessionUnknownAction.fromJson(Map<String, dynamic> json) => _$SessionUnknownActionFromJson(json);

/// The action's `type`.
 final  String type;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionUnknownActionCopyWith<SessionUnknownAction> get copyWith => _$SessionUnknownActionCopyWithImpl<SessionUnknownAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionUnknownActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionUnknownAction&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type);
}

@override
String toString() {
    return 'SessionAction.unknown(type: $type)';
}


}

/// @nodoc
abstract mixin class $SessionUnknownActionCopyWith<$Res> implements $SessionActionCopyWith<$Res> {
  factory $SessionUnknownActionCopyWith(SessionUnknownAction value, $Res Function(SessionUnknownAction) _then) = _$SessionUnknownActionCopyWithImpl;
@useResult
$Res call({
 String type
});




}
/// @nodoc
class _$SessionUnknownActionCopyWithImpl<$Res>
    implements $SessionUnknownActionCopyWith<$Res> {
  _$SessionUnknownActionCopyWithImpl(this._self, this._then);

  final SessionUnknownAction _self;
  final $Res Function(SessionUnknownAction) _then;

/// Create a copy of SessionAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(SessionUnknownAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
