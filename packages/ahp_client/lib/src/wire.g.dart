// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Implementation _$ImplementationFromJson(Map<String, dynamic> json) =>
    _Implementation(
      name: json['name'] as String,
      version: json['version'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$ImplementationToJson(_Implementation instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': ?instance.version,
      'title': ?instance.title,
    };

_ProjectInfo _$ProjectInfoFromJson(Map<String, dynamic> json) => _ProjectInfo(
  uri: json['uri'] as String,
  displayName: json['displayName'] as String,
);

Map<String, dynamic> _$ProjectInfoToJson(_ProjectInfo instance) =>
    <String, dynamic>{'uri': instance.uri, 'displayName': instance.displayName};

_ChangesSummary _$ChangesSummaryFromJson(Map<String, dynamic> json) =>
    _ChangesSummary(
      additions: (json['additions'] as num?)?.toInt(),
      deletions: (json['deletions'] as num?)?.toInt(),
      files: (json['files'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChangesSummaryToJson(_ChangesSummary instance) =>
    <String, dynamic>{
      'additions': ?instance.additions,
      'deletions': ?instance.deletions,
      'files': ?instance.files,
    };

_SessionChatSummary _$SessionChatSummaryFromJson(Map<String, dynamic> json) =>
    _SessionChatSummary(
      resource: json['resource'] as String,
      title: json['title'] as String,
      interactivity: json['interactivity'] as String?,
      status: _$JsonConverterFromJson<int, SessionStatus>(
        json['status'],
        const SessionStatusConverter().fromJson,
      ),
    );

Map<String, dynamic> _$SessionChatSummaryToJson(_SessionChatSummary instance) =>
    <String, dynamic>{
      'resource': instance.resource,
      'title': instance.title,
      'interactivity': ?instance.interactivity,
      'status': ?_$JsonConverterToJson<int, SessionStatus>(
        instance.status,
        const SessionStatusConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_SessionSummary _$SessionSummaryFromJson(Map<String, dynamic> json) =>
    _SessionSummary(
      resource: json['resource'] as String,
      provider: json['provider'] as String,
      title: json['title'] as String,
      status: const SessionStatusConverter().fromJson(
        (json['status'] as num).toInt(),
      ),
      createdAt: json['createdAt'] as String,
      modifiedAt: json['modifiedAt'] as String,
      activity: json['activity'] as String?,
      project: json['project'] == null
          ? null
          : ProjectInfo.fromJson(json['project'] as Map<String, dynamic>),
      workingDirectories: (json['workingDirectories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      changes: json['changes'] == null
          ? null
          : ChangesSummary.fromJson(json['changes'] as Map<String, dynamic>),
      chats: (json['chats'] as List<dynamic>?)
          ?.map((e) => SessionChatSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultChat: json['defaultChat'] as String?,
      meta: json['_meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionSummaryToJson(_SessionSummary instance) =>
    <String, dynamic>{
      'resource': instance.resource,
      'provider': instance.provider,
      'title': instance.title,
      'status': const SessionStatusConverter().toJson(instance.status),
      'createdAt': instance.createdAt,
      'modifiedAt': instance.modifiedAt,
      'activity': ?instance.activity,
      'project': ?instance.project?.toJson(),
      'workingDirectories': ?instance.workingDirectories,
      'changes': ?instance.changes?.toJson(),
      'chats': ?instance.chats?.map((e) => e.toJson()).toList(),
      'defaultChat': ?instance.defaultChat,
      '_meta': ?instance.meta,
    };

_SessionModelInfo _$SessionModelInfoFromJson(Map<String, dynamic> json) =>
    _SessionModelInfo(
      id: json['id'] as String,
      provider: json['provider'] as String,
      name: json['name'] as String,
      maxContextWindow: (json['maxContextWindow'] as num?)?.toInt(),
      supportsVision: json['supportsVision'] as bool?,
      policyState: json['policyState'] as String?,
      configSchema: json['configSchema'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SessionModelInfoToJson(_SessionModelInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': instance.provider,
      'name': instance.name,
      'maxContextWindow': ?instance.maxContextWindow,
      'supportsVision': ?instance.supportsVision,
      'policyState': ?instance.policyState,
      'configSchema': ?instance.configSchema,
    };

_AgentInfo _$AgentInfoFromJson(Map<String, dynamic> json) => _AgentInfo(
  provider: json['provider'] as String,
  displayName: json['displayName'] as String,
  description: json['description'] as String,
  models:
      (json['models'] as List<dynamic>?)
          ?.map((e) => SessionModelInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <SessionModelInfo>[],
  protectedResources: (json['protectedResources'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  capabilities: json['capabilities'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AgentInfoToJson(_AgentInfo instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'displayName': instance.displayName,
      'description': instance.description,
      'models': instance.models.map((e) => e.toJson()).toList(),
      'protectedResources': ?instance.protectedResources,
      'capabilities': ?instance.capabilities,
    };

_RootConfigState _$RootConfigStateFromJson(Map<String, dynamic> json) =>
    _RootConfigState(
      schema: json['schema'] as Map<String, dynamic>,
      values: json['values'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$RootConfigStateToJson(_RootConfigState instance) =>
    <String, dynamic>{'schema': instance.schema, 'values': instance.values};

_RootState _$RootStateFromJson(Map<String, dynamic> json) => _RootState(
  agents:
      (json['agents'] as List<dynamic>?)
          ?.map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <AgentInfo>[],
  activeSessions: (json['activeSessions'] as num?)?.toInt(),
  terminals: (json['terminals'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  config: json['config'] == null
      ? null
      : RootConfigState.fromJson(json['config'] as Map<String, dynamic>),
  meta: json['_meta'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$RootStateToJson(_RootState instance) =>
    <String, dynamic>{
      'agents': instance.agents.map((e) => e.toJson()).toList(),
      'activeSessions': ?instance.activeSessions,
      'terminals': ?instance.terminals,
      'config': ?instance.config?.toJson(),
      '_meta': ?instance.meta,
    };

_Snapshot _$SnapshotFromJson(Map<String, dynamic> json) => _Snapshot(
  resource: json['resource'] as String,
  state: json['state'] as Map<String, dynamic>,
  fromSeq: (json['fromSeq'] as num).toInt(),
);

Map<String, dynamic> _$SnapshotToJson(_Snapshot instance) => <String, dynamic>{
  'resource': instance.resource,
  'state': instance.state,
  'fromSeq': instance.fromSeq,
};

_InitializeResult _$InitializeResultFromJson(Map<String, dynamic> json) =>
    _InitializeResult(
      protocolVersion: json['protocolVersion'] as String,
      serverSeq: (json['serverSeq'] as num).toInt(),
      snapshots:
          (json['snapshots'] as List<dynamic>?)
              ?.map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Snapshot>[],
      serverInfo: json['serverInfo'] == null
          ? null
          : Implementation.fromJson(json['serverInfo'] as Map<String, dynamic>),
      defaultDirectory: json['defaultDirectory'] as String?,
      completionTriggerCharacters:
          (json['completionTriggerCharacters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      terminalCommandPrefix: json['terminalCommandPrefix'] as String?,
      meta: json['_meta'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$InitializeResultToJson(_InitializeResult instance) =>
    <String, dynamic>{
      'protocolVersion': instance.protocolVersion,
      'serverSeq': instance.serverSeq,
      'snapshots': instance.snapshots.map((e) => e.toJson()).toList(),
      'serverInfo': ?instance.serverInfo?.toJson(),
      'defaultDirectory': ?instance.defaultDirectory,
      'completionTriggerCharacters': ?instance.completionTriggerCharacters,
      'terminalCommandPrefix': ?instance.terminalCommandPrefix,
      '_meta': ?instance.meta,
    };

_ListSessionsResult _$ListSessionsResultFromJson(Map<String, dynamic> json) =>
    _ListSessionsResult(
      items: (json['items'] as List<dynamic>)
          .map((e) => SessionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$ListSessionsResultToJson(_ListSessionsResult instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'nextCursor': ?instance.nextCursor,
    };

_ActionOrigin _$ActionOriginFromJson(Map<String, dynamic> json) =>
    _ActionOrigin(
      clientId: json['clientId'] as String,
      clientSeq: (json['clientSeq'] as num).toInt(),
    );

Map<String, dynamic> _$ActionOriginToJson(_ActionOrigin instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientSeq': instance.clientSeq,
    };

_ActionEnvelope _$ActionEnvelopeFromJson(Map<String, dynamic> json) =>
    _ActionEnvelope(
      channel: json['channel'] as String,
      action: json['action'] as Map<String, dynamic>,
      serverSeq: (json['serverSeq'] as num).toInt(),
      origin: json['origin'] == null
          ? null
          : ActionOrigin.fromJson(json['origin'] as Map<String, dynamic>),
      rejectionReason: json['rejectionReason'] as String?,
    );

Map<String, dynamic> _$ActionEnvelopeToJson(_ActionEnvelope instance) =>
    <String, dynamic>{
      'channel': instance.channel,
      'action': instance.action,
      'serverSeq': instance.serverSeq,
      'origin': ?instance.origin?.toJson(),
      'rejectionReason': ?instance.rejectionReason,
    };

ReconnectReplay _$ReconnectReplayFromJson(Map<String, dynamic> json) =>
    ReconnectReplay(
      actions: (json['actions'] as List<dynamic>)
          .map((e) => ActionEnvelope.fromJson(e as Map<String, dynamic>))
          .toList(),
      missing:
          (json['missing'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ReconnectReplayToJson(ReconnectReplay instance) =>
    <String, dynamic>{
      'actions': instance.actions.map((e) => e.toJson()).toList(),
      'missing': instance.missing,
      'type': instance.$type,
    };

ReconnectSnapshot _$ReconnectSnapshotFromJson(Map<String, dynamic> json) =>
    ReconnectSnapshot(
      snapshots: (json['snapshots'] as List<dynamic>)
          .map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ReconnectSnapshotToJson(ReconnectSnapshot instance) =>
    <String, dynamic>{
      'snapshots': instance.snapshots.map((e) => e.toJson()).toList(),
      'type': instance.$type,
    };

RootAgentsChanged _$RootAgentsChangedFromJson(Map<String, dynamic> json) =>
    RootAgentsChanged(
      agents: (json['agents'] as List<dynamic>)
          .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$RootAgentsChangedToJson(RootAgentsChanged instance) =>
    <String, dynamic>{
      'agents': instance.agents.map((e) => e.toJson()).toList(),
      'type': instance.$type,
    };

RootActiveSessionsChanged _$RootActiveSessionsChangedFromJson(
  Map<String, dynamic> json,
) => RootActiveSessionsChanged(
  activeSessions: (json['activeSessions'] as num).toInt(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$RootActiveSessionsChangedToJson(
  RootActiveSessionsChanged instance,
) => <String, dynamic>{
  'activeSessions': instance.activeSessions,
  'type': instance.$type,
};

RootTerminalsChanged _$RootTerminalsChangedFromJson(
  Map<String, dynamic> json,
) => RootTerminalsChanged(
  terminals: (json['terminals'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$RootTerminalsChangedToJson(
  RootTerminalsChanged instance,
) => <String, dynamic>{'terminals': instance.terminals, 'type': instance.$type};

RootConfigChanged _$RootConfigChangedFromJson(Map<String, dynamic> json) =>
    RootConfigChanged(
      config: json['config'] as Map<String, dynamic>,
      replace: json['replace'] as bool?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$RootConfigChangedToJson(RootConfigChanged instance) =>
    <String, dynamic>{
      'config': instance.config,
      'replace': ?instance.replace,
      'type': instance.$type,
    };

RootUnknownAction _$RootUnknownActionFromJson(Map<String, dynamic> json) =>
    RootUnknownAction(type: json['type'] as String);

Map<String, dynamic> _$RootUnknownActionToJson(RootUnknownAction instance) =>
    <String, dynamic>{'type': instance.type};
