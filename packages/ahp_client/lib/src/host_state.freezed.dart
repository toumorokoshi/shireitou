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
 String? get defaultDirectory;/// Characters that ask for `completions` while a message is typed
/// (`InitializeResult.completionTriggerCharacters`, AHP-044); empty
/// when the host does not offer completions.
 List<String> get completionTriggerCharacters;/// Last error, for display.
 String? get error;/// Subscribed session channels, keyed by the URI they were subscribed
/// with (AHP-024).
 Map<String, ChannelMirror<SessionState>> get sessionChannels;/// Subscribed chat channels, keyed by chat URI (AHP-025).
 Map<String, ChannelMirror<ChatState>> get chatChannels;/// Subscribed terminal channels, keyed by terminal URI (AHP-028).
 Map<String, ChannelMirror<TerminalState>> get terminalChannels;/// Subscribed changeset channels, keyed by the expanded changeset URI
/// (AHP-027).
 Map<String, ChannelMirror<ChangesetState>> get changesetChannels;/// Subscribed canvas channels, keyed by canvas URI (AHP-031, 1.0.0).
 Map<String, ChannelMirror<CanvasState>> get canvasChannels;/// Channels the host could not resume after a reconnect (`missing` in
/// the `reconnect` result, AHP-004), for example disposed sessions. They
/// are no longer subscribed or mirrored. Subscribing again clears the
/// entry.
 Set<String> get missingChannels;
/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostStateCopyWith<HostState> get copyWith => _$HostStateCopyWithImpl<HostState>(this as HostState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HostState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.root, _this.root) || other.root == _this.root)&&const DeepCollectionEquality().equals(other.sessions, _this.sessions)&&(identical(other.serverSeq, _this.serverSeq) || other.serverSeq == _this.serverSeq)&&(identical(other.protocolVersion, _this.protocolVersion) || other.protocolVersion == _this.protocolVersion)&&(identical(other.serverInfo, _this.serverInfo) || other.serverInfo == _this.serverInfo)&&(identical(other.defaultDirectory, _this.defaultDirectory) || other.defaultDirectory == _this.defaultDirectory)&&const DeepCollectionEquality().equals(other.completionTriggerCharacters, _this.completionTriggerCharacters)&&(identical(other.error, _this.error) || other.error == _this.error)&&const DeepCollectionEquality().equals(other.sessionChannels, _this.sessionChannels)&&const DeepCollectionEquality().equals(other.chatChannels, _this.chatChannels)&&const DeepCollectionEquality().equals(other.terminalChannels, _this.terminalChannels)&&const DeepCollectionEquality().equals(other.changesetChannels, _this.changesetChannels)&&const DeepCollectionEquality().equals(other.canvasChannels, _this.canvasChannels)&&const DeepCollectionEquality().equals(other.missingChannels, _this.missingChannels));
}


@override
int get hashCode {
  final _this = this as HostState;
  return Object.hash(runtimeType,_this.status,_this.root,const DeepCollectionEquality().hash(_this.sessions),_this.serverSeq,_this.protocolVersion,_this.serverInfo,_this.defaultDirectory,const DeepCollectionEquality().hash(_this.completionTriggerCharacters),_this.error,const DeepCollectionEquality().hash(_this.sessionChannels),const DeepCollectionEquality().hash(_this.chatChannels),const DeepCollectionEquality().hash(_this.terminalChannels),const DeepCollectionEquality().hash(_this.changesetChannels),const DeepCollectionEquality().hash(_this.canvasChannels),const DeepCollectionEquality().hash(_this.missingChannels));
}

@override
String toString() {
  final _this = this as HostState;
  return 'HostState(status: ${_this.status}, root: ${_this.root}, sessions: ${_this.sessions}, serverSeq: ${_this.serverSeq}, protocolVersion: ${_this.protocolVersion}, serverInfo: ${_this.serverInfo}, defaultDirectory: ${_this.defaultDirectory}, completionTriggerCharacters: ${_this.completionTriggerCharacters}, error: ${_this.error}, sessionChannels: ${_this.sessionChannels}, chatChannels: ${_this.chatChannels}, terminalChannels: ${_this.terminalChannels}, changesetChannels: ${_this.changesetChannels}, canvasChannels: ${_this.canvasChannels}, missingChannels: ${_this.missingChannels})';
}


}

/// @nodoc
abstract mixin class $HostStateCopyWith<$Res>  {
  factory $HostStateCopyWith(HostState value, $Res Function(HostState) _then) = _$HostStateCopyWithImpl;
@useResult
$Res call({
 ConnectionStatus status, RootState? root, SessionCatalogue sessions, int serverSeq, String? protocolVersion, Implementation? serverInfo, String? defaultDirectory, List<String> completionTriggerCharacters, String? error, Map<String, ChannelMirror<SessionState>> sessionChannels, Map<String, ChannelMirror<ChatState>> chatChannels, Map<String, ChannelMirror<TerminalState>> terminalChannels, Map<String, ChannelMirror<ChangesetState>> changesetChannels, Map<String, ChannelMirror<CanvasState>> canvasChannels, Set<String> missingChannels
});




}
/// @nodoc
class _$HostStateCopyWithImpl<$Res>
    implements $HostStateCopyWith<$Res> {
  _$HostStateCopyWithImpl(this._self, this._then);

  final HostState _self;
  final $Res Function(HostState) _then;

/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? root = freezed,Object? sessions = null,Object? serverSeq = null,Object? protocolVersion = freezed,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? completionTriggerCharacters = null,Object? error = freezed,Object? sessionChannels = null,Object? chatChannels = null,Object? terminalChannels = null,Object? changesetChannels = null,Object? canvasChannels = null,Object? missingChannels = null,}) {
  return _then(HostState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,root: freezed == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as RootState?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as SessionCatalogue,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,completionTriggerCharacters: null == completionTriggerCharacters ? _self.completionTriggerCharacters : completionTriggerCharacters // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,sessionChannels: null == sessionChannels ? _self.sessionChannels : sessionChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<SessionState>>,chatChannels: null == chatChannels ? _self.chatChannels : chatChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChatState>>,terminalChannels: null == terminalChannels ? _self.terminalChannels : terminalChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<TerminalState>>,changesetChannels: null == changesetChannels ? _self.changesetChannels : changesetChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChangesetState>>,canvasChannels: null == canvasChannels ? _self.canvasChannels : canvasChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<CanvasState>>,missingChannels: null == missingChannels ? _self.missingChannels : missingChannels // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  List<String> completionTriggerCharacters,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels,  Map<String, ChannelMirror<TerminalState>> terminalChannels,  Map<String, ChannelMirror<ChangesetState>> changesetChannels,  Map<String, ChannelMirror<CanvasState>> canvasChannels,  Set<String> missingChannels)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostState() when $default != null:
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.error,_that.sessionChannels,_that.chatChannels,_that.terminalChannels,_that.changesetChannels,_that.canvasChannels,_that.missingChannels);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  List<String> completionTriggerCharacters,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels,  Map<String, ChannelMirror<TerminalState>> terminalChannels,  Map<String, ChannelMirror<ChangesetState>> changesetChannels,  Map<String, ChannelMirror<CanvasState>> canvasChannels,  Set<String> missingChannels)  $default,) {final _that = this;
switch (_that) {
case _HostState():
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.error,_that.sessionChannels,_that.chatChannels,_that.terminalChannels,_that.changesetChannels,_that.canvasChannels,_that.missingChannels);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ConnectionStatus status,  RootState? root,  SessionCatalogue sessions,  int serverSeq,  String? protocolVersion,  Implementation? serverInfo,  String? defaultDirectory,  List<String> completionTriggerCharacters,  String? error,  Map<String, ChannelMirror<SessionState>> sessionChannels,  Map<String, ChannelMirror<ChatState>> chatChannels,  Map<String, ChannelMirror<TerminalState>> terminalChannels,  Map<String, ChannelMirror<ChangesetState>> changesetChannels,  Map<String, ChannelMirror<CanvasState>> canvasChannels,  Set<String> missingChannels)?  $default,) {final _that = this;
switch (_that) {
case _HostState() when $default != null:
return $default(_that.status,_that.root,_that.sessions,_that.serverSeq,_that.protocolVersion,_that.serverInfo,_that.defaultDirectory,_that.completionTriggerCharacters,_that.error,_that.sessionChannels,_that.chatChannels,_that.terminalChannels,_that.changesetChannels,_that.canvasChannels,_that.missingChannels);case _:
  return null;

}
}

}

/// @nodoc


class _HostState implements HostState {
  const _HostState({this.status = ConnectionStatus.disconnected, this.root,  SessionCatalogue sessions = emptyCatalogue, this.serverSeq = 0, this.protocolVersion, this.serverInfo, this.defaultDirectory,  List<String> completionTriggerCharacters = const <String>[], this.error,  Map<String, ChannelMirror<SessionState>> sessionChannels = const <String, ChannelMirror<SessionState>>{},  Map<String, ChannelMirror<ChatState>> chatChannels = const <String, ChannelMirror<ChatState>>{},  Map<String, ChannelMirror<TerminalState>> terminalChannels = const <String, ChannelMirror<TerminalState>>{},  Map<String, ChannelMirror<ChangesetState>> changesetChannels = const <String, ChannelMirror<ChangesetState>>{},  Map<String, ChannelMirror<CanvasState>> canvasChannels = const <String, ChannelMirror<CanvasState>>{},  Set<String> missingChannels = const <String>{}}): _sessions = sessions,_completionTriggerCharacters = completionTriggerCharacters,_sessionChannels = sessionChannels,_chatChannels = chatChannels,_terminalChannels = terminalChannels,_changesetChannels = changesetChannels,_canvasChannels = canvasChannels,_missingChannels = missingChannels;
  

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
/// Characters that ask for `completions` while a message is typed
/// (`InitializeResult.completionTriggerCharacters`, AHP-044); empty
/// when the host does not offer completions.
 final  List<String> _completionTriggerCharacters;
/// Characters that ask for `completions` while a message is typed
/// (`InitializeResult.completionTriggerCharacters`, AHP-044); empty
/// when the host does not offer completions.
@override@JsonKey() List<String> get completionTriggerCharacters {
  if (_completionTriggerCharacters is EqualUnmodifiableListView) return _completionTriggerCharacters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completionTriggerCharacters);
}

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

/// Subscribed terminal channels, keyed by terminal URI (AHP-028).
 final  Map<String, ChannelMirror<TerminalState>> _terminalChannels;
/// Subscribed terminal channels, keyed by terminal URI (AHP-028).
@override@JsonKey() Map<String, ChannelMirror<TerminalState>> get terminalChannels {
  if (_terminalChannels is EqualUnmodifiableMapView) return _terminalChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_terminalChannels);
}

/// Subscribed changeset channels, keyed by the expanded changeset URI
/// (AHP-027).
 final  Map<String, ChannelMirror<ChangesetState>> _changesetChannels;
/// Subscribed changeset channels, keyed by the expanded changeset URI
/// (AHP-027).
@override@JsonKey() Map<String, ChannelMirror<ChangesetState>> get changesetChannels {
  if (_changesetChannels is EqualUnmodifiableMapView) return _changesetChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_changesetChannels);
}

/// Subscribed canvas channels, keyed by canvas URI (AHP-031, 1.0.0).
 final  Map<String, ChannelMirror<CanvasState>> _canvasChannels;
/// Subscribed canvas channels, keyed by canvas URI (AHP-031, 1.0.0).
@override@JsonKey() Map<String, ChannelMirror<CanvasState>> get canvasChannels {
  if (_canvasChannels is EqualUnmodifiableMapView) return _canvasChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_canvasChannels);
}

/// Channels the host could not resume after a reconnect (`missing` in
/// the `reconnect` result, AHP-004), for example disposed sessions. They
/// are no longer subscribed or mirrored. Subscribing again clears the
/// entry.
 final  Set<String> _missingChannels;
/// Channels the host could not resume after a reconnect (`missing` in
/// the `reconnect` result, AHP-004), for example disposed sessions. They
/// are no longer subscribed or mirrored. Subscribing again clears the
/// entry.
@override@JsonKey() Set<String> get missingChannels {
  if (_missingChannels is EqualUnmodifiableSetView) return _missingChannels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_missingChannels);
}


/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostStateCopyWith<_HostState> get copyWith => __$HostStateCopyWithImpl<_HostState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostState&&(identical(other.status, status) || other.status == status)&&(identical(other.root, root) || other.root == root)&&const DeepCollectionEquality().equals(other.sessions, _sessions)&&(identical(other.serverSeq, serverSeq) || other.serverSeq == serverSeq)&&(identical(other.protocolVersion, protocolVersion) || other.protocolVersion == protocolVersion)&&(identical(other.serverInfo, serverInfo) || other.serverInfo == serverInfo)&&(identical(other.defaultDirectory, defaultDirectory) || other.defaultDirectory == defaultDirectory)&&const DeepCollectionEquality().equals(other.completionTriggerCharacters, _completionTriggerCharacters)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.sessionChannels, _sessionChannels)&&const DeepCollectionEquality().equals(other.chatChannels, _chatChannels)&&const DeepCollectionEquality().equals(other.terminalChannels, _terminalChannels)&&const DeepCollectionEquality().equals(other.changesetChannels, _changesetChannels)&&const DeepCollectionEquality().equals(other.canvasChannels, _canvasChannels)&&const DeepCollectionEquality().equals(other.missingChannels, _missingChannels));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,root,const DeepCollectionEquality().hash(_sessions),serverSeq,protocolVersion,serverInfo,defaultDirectory,const DeepCollectionEquality().hash(_completionTriggerCharacters),error,const DeepCollectionEquality().hash(_sessionChannels),const DeepCollectionEquality().hash(_chatChannels),const DeepCollectionEquality().hash(_terminalChannels),const DeepCollectionEquality().hash(_changesetChannels),const DeepCollectionEquality().hash(_canvasChannels),const DeepCollectionEquality().hash(_missingChannels));
}

@override
String toString() {
    return 'HostState(status: $status, root: $root, sessions: $sessions, serverSeq: $serverSeq, protocolVersion: $protocolVersion, serverInfo: $serverInfo, defaultDirectory: $defaultDirectory, completionTriggerCharacters: $completionTriggerCharacters, error: $error, sessionChannels: $sessionChannels, chatChannels: $chatChannels, terminalChannels: $terminalChannels, changesetChannels: $changesetChannels, canvasChannels: $canvasChannels, missingChannels: $missingChannels)';
}


}

/// @nodoc
abstract mixin class _$HostStateCopyWith<$Res> implements $HostStateCopyWith<$Res> {
  factory _$HostStateCopyWith(_HostState value, $Res Function(_HostState) _then) = __$HostStateCopyWithImpl;
@override @useResult
$Res call({
 ConnectionStatus status, RootState? root, SessionCatalogue sessions, int serverSeq, String? protocolVersion, Implementation? serverInfo, String? defaultDirectory, List<String> completionTriggerCharacters, String? error, Map<String, ChannelMirror<SessionState>> sessionChannels, Map<String, ChannelMirror<ChatState>> chatChannels, Map<String, ChannelMirror<TerminalState>> terminalChannels, Map<String, ChannelMirror<ChangesetState>> changesetChannels, Map<String, ChannelMirror<CanvasState>> canvasChannels, Set<String> missingChannels
});




}
/// @nodoc
class __$HostStateCopyWithImpl<$Res>
    implements _$HostStateCopyWith<$Res> {
  __$HostStateCopyWithImpl(this._self, this._then);

  final _HostState _self;
  final $Res Function(_HostState) _then;

/// Create a copy of HostState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? root = freezed,Object? sessions = null,Object? serverSeq = null,Object? protocolVersion = freezed,Object? serverInfo = freezed,Object? defaultDirectory = freezed,Object? completionTriggerCharacters = null,Object? error = freezed,Object? sessionChannels = null,Object? chatChannels = null,Object? terminalChannels = null,Object? changesetChannels = null,Object? canvasChannels = null,Object? missingChannels = null,}) {
  return _then(_HostState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ConnectionStatus,root: freezed == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as RootState?,sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as SessionCatalogue,serverSeq: null == serverSeq ? _self.serverSeq : serverSeq // ignore: cast_nullable_to_non_nullable
as int,protocolVersion: freezed == protocolVersion ? _self.protocolVersion : protocolVersion // ignore: cast_nullable_to_non_nullable
as String?,serverInfo: freezed == serverInfo ? _self.serverInfo : serverInfo // ignore: cast_nullable_to_non_nullable
as Implementation?,defaultDirectory: freezed == defaultDirectory ? _self.defaultDirectory : defaultDirectory // ignore: cast_nullable_to_non_nullable
as String?,completionTriggerCharacters: null == completionTriggerCharacters ? _self._completionTriggerCharacters : completionTriggerCharacters // ignore: cast_nullable_to_non_nullable
as List<String>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,sessionChannels: null == sessionChannels ? _self._sessionChannels : sessionChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<SessionState>>,chatChannels: null == chatChannels ? _self._chatChannels : chatChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChatState>>,terminalChannels: null == terminalChannels ? _self._terminalChannels : terminalChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<TerminalState>>,changesetChannels: null == changesetChannels ? _self._changesetChannels : changesetChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<ChangesetState>>,canvasChannels: null == canvasChannels ? _self._canvasChannels : canvasChannels // ignore: cast_nullable_to_non_nullable
as Map<String, ChannelMirror<CanvasState>>,missingChannels: null == missingChannels ? _self._missingChannels : missingChannels // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
