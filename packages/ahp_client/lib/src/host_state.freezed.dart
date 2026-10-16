// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'host_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HostState {

/// Connection status.
 ConnectionStatus get status;/// Root channel state; null until the root snapshot arrives.
 RootState? get root;/// Session catalogue keyed by session URI.
 SessionCatalogue get sessions;/// Highest `serverSeq` seen, used by `reconnect`.
 int get serverSeq;/// Negotiated protocol version.
 String? get protocolVersion;/// Host name and version.
 Implementation? get serverInfo;/// Default working directory URI for new sessions.
 String? get defaultDirectory;/// Last error, for display.
 String? get error;/// Subscribed session channels, keyed by the URI they were subscribed
/// with (AHP-024).
 Map<String, ChannelMirror<SessionState>> get sessionChannels;/// Subscribed chat channels, keyed by chat URI (AHP-025).
 Map<String, ChannelMirror<ChatState>> get chatChannels;
/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostStateCopyWith<HostState> get copyWith => _$HostStateCopyWithImpl<HostState>(this as HostState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HostState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.sessions, _this.sessions)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq)&&(identical(other.protocolVersion, _this.protocolVersion) || other.protocolVersion == _this.protocolVersion)&&(identical(other.serverInfo, _this.serverInfo) || other.serverInfo == _this.serverInfo)&&(identical(other.defaultDirectory, _this.defaultDirectory) || other.defaultDirectory == _this.defaultDirectory)&&(identical(other.error, _this.error) || other.error == _this.error)&&const DeepCollectionEquality().equals(other.sessionChannels, _this.sessionChannels)&&const DeepCollectionEquality().equals(other.chatChannels, _this.chatChannels));
}


@override
int get hashCode {
  final _this = this as HostState;
  return Object.hash(runtimeType,_this.status,_this.root,const DeepCollectionEquality().hash(_this.sessions),_this.serverSeq,_this.protocolVersion,_this.serverInfo,_this.defaultDirectory,_this.error,const DeepCollectionEquality().hash(_this.sessionChannels),const DeepCollectionEquality().hash(_this.chatChannels));
}

@override
String toString() {
  final _this = this as HostState;
  return 'HostState(status: ${_this.status}, root: ${_this.root}, sessions: ${_this.sessions}, serverSeq: ${_this.serverSeq}, protocolVersion: ${_this.protocolVersion}, serverInfo: ${_this.serverInfo}, defaultDirectory: ${_this.defaultDirectory}, error: ${_this.error}, sessionChannels: ${_this.sessionChannels}, chatChannels: ${_this.chatChannels})';
}


}

/// @nodoc
abstract mixin class $HostStateCopyWith<$Res>  {
  factory $HostStateCopyWith(HostState value, $Res Function(HostState) _then) = _$HostStateCopyWithImpl;
@useResult
$Res call({
 ConnectionStatus status, RootState? root, SessionCatalogue sessions, int serverSeq, String? protocolVersion, Implementation? serverInfo, String? defaultDirectory, String? error, Map<String, ChannelMirror<SessionState>> sessionChannels, Map<String, ChannelMirror<ChatState>> chatChannels
});


$RootStateCopyWith<$Res>? get root;$ImplementationCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class _$HostStateCopyWithImpl<$Res>
    implements $HostStateCopyWith<$Res> {
  _$HostStateCopyWithImpl(this._self, this._then);

  final HostState _self;
  final $Res Function(HostState) _then;

/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? root = freezed,Object? sessions = null,Object? serverSeq = null,Object? protocolVersion = freezed,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? error = freezed,Object? sessionChannels = null,Object? chatChannels = null,}) {
  return _then(HostState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,root: freezed == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as RootState?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as SessionCatalogue,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,sessionChannels: null == sessionChannels ? _self.sessionChannels : sessionChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<SessionState>>,chatChannels: null == chatChannels ? _self.chatChannels : chatChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChatState>>,
  ));
}
/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RootStateCopyWith<$Res>? get root {
    if (_self.root == null) {
    return null;
  }

  return $RootStateCopyWith<$Res>(_self.root!, (value) {
    return _then(_self.copyWith(root: value));
  });
}/// Create a copy of HostState
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


/// Adds pattern-matching-related methods to [HostState].
extension HostStatePatterns on HostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostState value)  $default,){
final _that = this;
switch (_that) {
case _HostState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostState value)?  $default,){
final _that = this;
switch (_that) {
case _HostState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostState() when $default != null:
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.error,_that.sessionChannels,_that.chatChannels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels)  $default,) {final _that = this;
switch (_that) {
case _HostState():
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.error,_that.sessionChannels,_that.chatChannels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels)?  $default,) {final _that = this;
switch (_that) {
case _HostState() when $default != null:
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.error,_that.sessionChannels,_that.chatChannels);case _:
  return null;

}
}

}

/// @nodoc


class _HostState implements HostState {
  const _HostState({this.status = ConnectionStatus.disconnected, this.root,  SessionCatalogue sessions = emptyCatalogue, this.serverSeq = 0, this.protocolVersion, this.serverInfo, this.defaultDirectory, this.error,  Map<String, ChannelMirror<SessionState>> sessionChannels = const <String, ChannelMirror<SessionState>>{},  Map<String, ChannelMirror<ChatState>> chatChannels = const <String, ChannelMirror<ChatState>>{}}): _sessions = sessions,_sessionChannels = sessionChannels,_chatChannels = chatChannels;
  

/// Connection status.
@override@JsonKey() final  ConnectionStatus status;
/// Root channel state; null until the root snapshot arrives.
@override final  RootState? root;
/// Session catalogue keyed by session URI.
 final  SessionCatalogue _sessions;
/// Session catalogue keyed by session URI.
@override@JsonKey() SessionCatalogue get sessions {
  if (_sessions is EqualUnmodifiableMapView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessions);
}

/// Highest `serverSeq` seen, used by `reconnect`.
@override@JsonKey() final  int serverSeq;
/// Negotiated protocol version.
@override final  String? protocolVersion;
/// Host name and version.
@override final  Implementation? serverInfo;
/// Default working directory URI for new sessions.
@override final  String? defaultDirectory;
/// Last error, for display.
@override final  String? error;
/// Subscribed session channels, keyed by the URI they were subscribed
/// with (AHP-024).
 final  Map<String, ChannelMirror<SessionState>> _sessionChannels;
/// Subscribed session channels, keyed by the URI they were subscribed
/// with (AHP-024).
@override@JsonKey() Map<String, ChannelMirror<SessionState>> get sessionChannels {
  if (_sessionChannels is EqualUnmodifiableMapView) return _sessionChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionChannels);
}

/// Subscribed chat channels, keyed by chat URI (AHP-025).
 final  Map<String, ChannelMirror<ChatState>> _chatChannels;
/// Subscribed chat channels, keyed by chat URI (AHP-025).
@override@JsonKey() Map<String, ChannelMirror<ChatState>> get chatChannels {
  if (_chatChannels is EqualUnmodifiableMapView) return _chatChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_chatChannels);
}


/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostStateCopyWith<_HostState> get copyWith => __$HostStateCopyWithImpl<_HostState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostState&&(identical(other.status, status) || other.status == status)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.sessions, _sessions)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.serverInfo, serverInfo) || other.serverInfo == serverInfo)&&(identical(other.defaultDirectory, defaultDirectory) || other.defaultDirectory == defaultDirectory)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.sessionChannels, _sessionChannels)&&const DeepCollectionEquality().equals(other.chatChannels, _chatChannels));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,root,const DeepCollectionEquality().hash(_sessions),serverSeq,protocolVersion,serverInfo,defaultDirectory,error,const DeepCollectionEquality().hash(_sessionChannels),const DeepCollectionEquality().hash(_chatChannels));
}

@override
String toString() {
    return 'HostState(status: $status, root: $root, sessions: $sessions, serverSeq: $serverSeq, protocolVersion: $protocolVersion, serverInfo: $serverInfo, defaultDirectory: $defaultDirectory, error: $error, sessionChannels: $sessionChannels, chatChannels: $chatChannels)';
}


}

/// @nodoc
abstract mixin class _$HostStateCopyWith<$Res> implements $HostStateCopyWith<$Res> {
  factory _$HostStateCopyWith(_HostState value, $Res Function(_HostState) _then) = __$HostStateCopyWithImpl;
@override @useResult
$Res call({
 ConnectionStatus status, RootState? root, SessionCatalogue sessions, int serverSeq, String? protocolVersion, Implementation? serverInfo, String? defaultDirectory, String? error, Map<String, ChannelMirror<SessionState>> sessionChannels, Map<String, ChannelMirror<ChatState>> chatChannels
});


@override $RootStateCopyWith<$Res>? get root;@override $ImplementationCopyWith<$Res>? get serverInfo;

}
/// @nodoc
class __$HostStateCopyWithImpl<$Res>
    implements _$HostStateCopyWith<$Res> {
  __$HostStateCopyWithImpl(this._self, this._then);

  final _HostState _self;
  final $Res Function(_HostState) _then;

/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? root = freezed,Object? sessions = null,Object? serverSeq = null,Object? protocolVersion = freezed,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? error = freezed,Object? sessionChannels = null,Object? chatChannels = null,}) {
  return _then(_HostState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,root: freezed == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as RootState?,sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as SessionCatalogue,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,sessionChannels: null == sessionChannels ? _self._sessionChannels : sessionChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<SessionState>>,chatChannels: null == chatChannels ? _self._chatChannels : chatChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChatState>>,
  ));
}

/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RootStateCopyWith<$Res>? get root {
    if (_self.root == null) {
    return null;
  }

  return $RootStateCopyWith<$Res>(_self.root!, (value) {
    return _then(_self.copyWith(root: value));
  });
}/// Create a copy of HostState
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

// dart format on
