// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionState _$SessionStateFromJson(Map<String, dynamic> json) =>
    _SessionState(
      provider: json['provider'] as String,
      title: json['title'] as String,
      status: const SessionStatusConverter().fromJson(
        (json['status'] as num).toInt(),
      ),
      lifecycle: json['lifecycle'] as String,
      chats:
          (json['chats'] as List<dynamic>?)
              ?.map(
                (e) => SessionChatSummary.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <SessionChatSummary>[],
      activeClients:
          (json['activeClients'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const <JsonMap>[],
      creationError: json['creationError'] == null
          ? null
          : ErrorInfo.fromJson(json['creationError'] as Map<String, dynamic>),
      activity: json['activity'] as String?,
      project: json['project'] == null
          ? null
          : ProjectInfo.fromJson(json['project'] as Map<String, dynamic>),
      workingDirectories: (json['workingDirectories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      defaultChat: json['defaultChat'] as String?,
      config: json['config'] as Map<String, dynamic>?,
      inputNeeded: (json['inputNeeded'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      meta: json['_meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionStateToJson(_SessionState instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'title': instance.title,
      'status': const SessionStatusConverter().toJson(instance.status),
      'lifecycle': instance.lifecycle,
      'chats': instance.chats.map((e) => e.toJson()).toList(),
      'activeClients': instance.activeClients,
      'creationError': ?instance.creationError?.toJson(),
      'activity': ?instance.activity,
      'project': ?instance.project?.toJson(),
      'workingDirectories': ?instance.workingDirectories,
      'defaultChat': ?instance.defaultChat,
      'config': ?instance.config,
      'inputNeeded': ?instance.inputNeeded,
      '_meta': ?instance.meta,
    };

SessionReady _$SessionReadyFromJson(Map<String, dynamic> json) =>
    SessionReady($type: json['type'] as String?);

Map<String, dynamic> _$SessionReadyToJson(SessionReady instance) =>
    <String, dynamic>{'type': instance.$type};

SessionCreationFailed _$SessionCreationFailedFromJson(
  Map<String, dynamic> json,
) => SessionCreationFailed(
  error: ErrorInfo.fromJson(json['error'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionCreationFailedToJson(
  SessionCreationFailed instance,
) => <String, dynamic>{
  'error': instance.error.toJson(),
  'type': instance.$type,
};

SessionChatAdded _$SessionChatAddedFromJson(Map<String, dynamic> json) =>
    SessionChatAdded(
      summary: SessionChatSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$SessionChatAddedToJson(SessionChatAdded instance) =>
    <String, dynamic>{
      'summary': instance.summary.toJson(),
      'type': instance.$type,
    };

SessionChatRemoved _$SessionChatRemovedFromJson(Map<String, dynamic> json) =>
    SessionChatRemoved(
      chat: json['chat'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$SessionChatRemovedToJson(SessionChatRemoved instance) =>
    <String, dynamic>{'chat': instance.chat, 'type': instance.$type};

SessionChatUpdated _$SessionChatUpdatedFromJson(Map<String, dynamic> json) =>
    SessionChatUpdated(
      chat: json['chat'] as String,
      changes: json['changes'] as Map<String, dynamic>,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$SessionChatUpdatedToJson(SessionChatUpdated instance) =>
    <String, dynamic>{
      'chat': instance.chat,
      'changes': instance.changes,
      'type': instance.$type,
    };

SessionDefaultChatChanged _$SessionDefaultChatChangedFromJson(
  Map<String, dynamic> json,
) => SessionDefaultChatChanged(
  defaultChat: json['defaultChat'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionDefaultChatChangedToJson(
  SessionDefaultChatChanged instance,
) => <String, dynamic>{
  'defaultChat': ?instance.defaultChat,
  'type': instance.$type,
};

SessionTitleChanged _$SessionTitleChangedFromJson(Map<String, dynamic> json) =>
    SessionTitleChanged(
      title: json['title'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$SessionTitleChangedToJson(
  SessionTitleChanged instance,
) => <String, dynamic>{'title': instance.title, 'type': instance.$type};

SessionIsReadChanged _$SessionIsReadChangedFromJson(
  Map<String, dynamic> json,
) => SessionIsReadChanged(
  isRead: json['isRead'] as bool,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionIsReadChangedToJson(
  SessionIsReadChanged instance,
) => <String, dynamic>{'isRead': instance.isRead, 'type': instance.$type};

SessionIsArchivedChanged _$SessionIsArchivedChangedFromJson(
  Map<String, dynamic> json,
) => SessionIsArchivedChanged(
  isArchived: json['isArchived'] as bool,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionIsArchivedChangedToJson(
  SessionIsArchivedChanged instance,
) => <String, dynamic>{
  'isArchived': instance.isArchived,
  'type': instance.$type,
};

SessionActivityChanged _$SessionActivityChangedFromJson(
  Map<String, dynamic> json,
) => SessionActivityChanged(
  activity: json['activity'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionActivityChangedToJson(
  SessionActivityChanged instance,
) => <String, dynamic>{'activity': ?instance.activity, 'type': instance.$type};

SessionConfigChanged _$SessionConfigChangedFromJson(
  Map<String, dynamic> json,
) => SessionConfigChanged(
  config: json['config'] as Map<String, dynamic>,
  replace: json['replace'] as bool?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$SessionConfigChangedToJson(
  SessionConfigChanged instance,
) => <String, dynamic>{
  'config': instance.config,
  'replace': ?instance.replace,
  'type': instance.$type,
};

SessionUnknownAction _$SessionUnknownActionFromJson(
  Map<String, dynamic> json,
) => SessionUnknownAction(type: json['type'] as String);

Map<String, dynamic> _$SessionUnknownActionToJson(
  SessionUnknownAction instance,
) => <String, dynamic>{'type': instance.type};
