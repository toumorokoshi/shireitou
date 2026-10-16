// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_wire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModelSelection _$ModelSelectionFromJson(Map<String, dynamic> json) =>
    _ModelSelection(
      id: json['id'] as String,
      config: json['config'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ModelSelectionToJson(_ModelSelection instance) =>
    <String, dynamic>{'id': instance.id, 'config': ?instance.config};

_MessageOrigin _$MessageOriginFromJson(Map<String, dynamic> json) =>
    _MessageOrigin(kind: json['kind'] as String);

Map<String, dynamic> _$MessageOriginToJson(_MessageOrigin instance) =>
    <String, dynamic>{'kind': instance.kind};

_Message _$MessageFromJson(Map<String, dynamic> json) => _Message(
  text: json['text'] as String,
  origin: MessageOrigin.fromJson(json['origin'] as Map<String, dynamic>),
  attachments: (json['attachments'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  model: json['model'] == null
      ? null
      : ModelSelection.fromJson(json['model'] as Map<String, dynamic>),
  meta: json['_meta'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$MessageToJson(_Message instance) => <String, dynamic>{
  'text': instance.text,
  'origin': instance.origin.toJson(),
  'attachments': ?instance.attachments,
  'model': ?instance.model?.toJson(),
  '_meta': ?instance.meta,
};

_UsageInfo _$UsageInfoFromJson(Map<String, dynamic> json) => _UsageInfo(
  inputTokens: (json['inputTokens'] as num?)?.toInt(),
  outputTokens: (json['outputTokens'] as num?)?.toInt(),
  model: json['model'] as String?,
  cacheReadTokens: (json['cacheReadTokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$UsageInfoToJson(_UsageInfo instance) =>
    <String, dynamic>{
      'inputTokens': ?instance.inputTokens,
      'outputTokens': ?instance.outputTokens,
      'model': ?instance.model,
      'cacheReadTokens': ?instance.cacheReadTokens,
    };

_ErrorInfo _$ErrorInfoFromJson(Map<String, dynamic> json) => _ErrorInfo(
  errorType: json['errorType'] as String,
  message: json['message'] as String,
  stack: json['stack'] as String?,
);

Map<String, dynamic> _$ErrorInfoToJson(_ErrorInfo instance) =>
    <String, dynamic>{
      'errorType': instance.errorType,
      'message': instance.message,
      'stack': ?instance.stack,
    };

_ConfirmationOption _$ConfirmationOptionFromJson(Map<String, dynamic> json) =>
    _ConfirmationOption(
      id: json['id'] as String,
      label: json['label'] as String,
      kind: json['kind'] as String,
      group: (json['group'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConfirmationOptionToJson(_ConfirmationOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'kind': instance.kind,
      'group': ?instance.group,
    };

_ToolCall _$ToolCallFromJson(Map<String, dynamic> json) => _ToolCall(
  toolCallId: json['toolCallId'] as String,
  toolName: json['toolName'] as String,
  displayName: json['displayName'] as String,
  status: $enumDecode(
    _$ToolCallStatusEnumMap,
    json['status'],
    unknownValue: ToolCallStatus.unknown,
  ),
  intention: json['intention'] as String?,
  contributor: json['contributor'] as Map<String, dynamic>?,
  partialInput: json['partialInput'] as String?,
  invocationMessage: json['invocationMessage'],
  toolInput: json['toolInput'],
  confirmationTitle: json['confirmationTitle'],
  riskAssessment: json['riskAssessment'] as Map<String, dynamic>?,
  edits: json['edits'] as Map<String, dynamic>?,
  editable: json['editable'] as bool?,
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => ConfirmationOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  confirmed: json['confirmed'] as String?,
  selectedOption: json['selectedOption'] == null
      ? null
      : ConfirmationOption.fromJson(
          json['selectedOption'] as Map<String, dynamic>,
        ),
  content: (json['content'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  success: json['success'] as bool?,
  pastTenseMessage: json['pastTenseMessage'],
  structuredContent: json['structuredContent'] as Map<String, dynamic>?,
  error: json['error'] as Map<String, dynamic>?,
  auth: json['auth'] as Map<String, dynamic>?,
  reason: json['reason'] as String?,
  reasonMessage: json['reasonMessage'],
  userSuggestion: json['userSuggestion'] == null
      ? null
      : Message.fromJson(json['userSuggestion'] as Map<String, dynamic>),
  meta: json['_meta'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ToolCallToJson(_ToolCall instance) => <String, dynamic>{
  'toolCallId': instance.toolCallId,
  'toolName': instance.toolName,
  'displayName': instance.displayName,
  'status': _$ToolCallStatusEnumMap[instance.status]!,
  'intention': ?instance.intention,
  'contributor': ?instance.contributor,
  'partialInput': ?instance.partialInput,
  'invocationMessage': ?instance.invocationMessage,
  'toolInput': ?instance.toolInput,
  'confirmationTitle': ?instance.confirmationTitle,
  'riskAssessment': ?instance.riskAssessment,
  'edits': ?instance.edits,
  'editable': ?instance.editable,
  'options': ?instance.options?.map((e) => e.toJson()).toList(),
  'confirmed': ?instance.confirmed,
  'selectedOption': ?instance.selectedOption?.toJson(),
  'content': ?instance.content,
  'success': ?instance.success,
  'pastTenseMessage': ?instance.pastTenseMessage,
  'structuredContent': ?instance.structuredContent,
  'error': ?instance.error,
  'auth': ?instance.auth,
  'reason': ?instance.reason,
  'reasonMessage': ?instance.reasonMessage,
  'userSuggestion': ?instance.userSuggestion?.toJson(),
  '_meta': ?instance.meta,
};

const _$ToolCallStatusEnumMap = {
  ToolCallStatus.streaming: 'streaming',
  ToolCallStatus.pendingConfirmation: 'pending-confirmation',
  ToolCallStatus.running: 'running',
  ToolCallStatus.authRequired: 'auth-required',
  ToolCallStatus.pendingResultConfirmation: 'pending-result-confirmation',
  ToolCallStatus.completed: 'completed',
  ToolCallStatus.cancelled: 'cancelled',
  ToolCallStatus.unknown: 'unknown',
};

_ChatInputOption _$ChatInputOptionFromJson(Map<String, dynamic> json) =>
    _ChatInputOption(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      recommended: json['recommended'] as bool?,
    );

Map<String, dynamic> _$ChatInputOptionToJson(_ChatInputOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'description': ?instance.description,
      'recommended': ?instance.recommended,
    };

_ChatInputQuestion _$ChatInputQuestionFromJson(Map<String, dynamic> json) =>
    _ChatInputQuestion(
      id: json['id'] as String,
      kind: json['kind'] as String,
      message: json['message'] as String,
      title: json['title'] as String?,
      required: json['required'] as bool?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ChatInputOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      allowFreeformInput: json['allowFreeformInput'] as bool?,
      format: json['format'] as String?,
      min: json['min'] as num?,
      max: json['max'] as num?,
      defaultValue: json['defaultValue'],
    );

Map<String, dynamic> _$ChatInputQuestionToJson(_ChatInputQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': instance.kind,
      'message': instance.message,
      'title': ?instance.title,
      'required': ?instance.required,
      'options': ?instance.options?.map((e) => e.toJson()).toList(),
      'allowFreeformInput': ?instance.allowFreeformInput,
      'format': ?instance.format,
      'min': ?instance.min,
      'max': ?instance.max,
      'defaultValue': ?instance.defaultValue,
    };

_ChatInputRequest _$ChatInputRequestFromJson(Map<String, dynamic> json) =>
    _ChatInputRequest(
      id: json['id'] as String,
      message: json['message'] as String?,
      url: json['url'] as String?,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((e) => ChatInputQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      answers: (json['answers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$ChatInputRequestToJson(_ChatInputRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': ?instance.message,
      'url': ?instance.url,
      'questions': ?instance.questions?.map((e) => e.toJson()).toList(),
      'answers': ?instance.answers,
    };

MarkdownPart _$MarkdownPartFromJson(Map<String, dynamic> json) => MarkdownPart(
  id: json['id'] as String,
  content: json['content'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$MarkdownPartToJson(MarkdownPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'kind': instance.$type,
    };

ReasoningPart _$ReasoningPartFromJson(Map<String, dynamic> json) =>
    ReasoningPart(
      id: json['id'] as String,
      content: json['content'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ReasoningPartToJson(ReasoningPart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'kind': instance.$type,
    };

ToolCallPart _$ToolCallPartFromJson(Map<String, dynamic> json) => ToolCallPart(
  toolCall: ToolCall.fromJson(json['toolCall'] as Map<String, dynamic>),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ToolCallPartToJson(ToolCallPart instance) =>
    <String, dynamic>{
      'toolCall': instance.toolCall.toJson(),
      'kind': instance.$type,
    };

InputRequestPart _$InputRequestPartFromJson(Map<String, dynamic> json) =>
    InputRequestPart(
      request: ChatInputRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      response: json['response'] as String?,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$InputRequestPartToJson(InputRequestPart instance) =>
    <String, dynamic>{
      'request': instance.request.toJson(),
      'response': ?instance.response,
      'kind': instance.$type,
    };

ErrorPart _$ErrorPartFromJson(Map<String, dynamic> json) => ErrorPart(
  error: ErrorInfo.fromJson(json['error'] as Map<String, dynamic>),
  resumable: json['resumable'] as bool?,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ErrorPartToJson(ErrorPart instance) => <String, dynamic>{
  'error': instance.error.toJson(),
  'resumable': ?instance.resumable,
  'kind': instance.$type,
};

SystemNotificationPart _$SystemNotificationPartFromJson(
  Map<String, dynamic> json,
) => SystemNotificationPart(
  content: json['content'],
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SystemNotificationPartToJson(
  SystemNotificationPart instance,
) => <String, dynamic>{'content': ?instance.content, 'kind': instance.$type};

ContentRefPart _$ContentRefPartFromJson(Map<String, dynamic> json) =>
    ContentRefPart(
      uri: json['uri'] as String,
      contentType: json['contentType'] as String?,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$ContentRefPartToJson(ContentRefPart instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'contentType': ?instance.contentType,
      'kind': instance.$type,
    };

UnknownPart _$UnknownPartFromJson(Map<String, dynamic> json) =>
    UnknownPart(kind: json['kind'] as String);

Map<String, dynamic> _$UnknownPartToJson(UnknownPart instance) =>
    <String, dynamic>{'kind': instance.kind};

_Turn _$TurnFromJson(Map<String, dynamic> json) => _Turn(
  id: json['id'] as String,
  message: Message.fromJson(json['message'] as Map<String, dynamic>),
  responseParts: (json['responseParts'] as List<dynamic>)
      .map((e) => ResponsePart.fromJson(e as Map<String, dynamic>))
      .toList(),
  state: $enumDecode(_$TurnStateEnumMap, json['state']),
  startedAt: json['startedAt'] as String?,
  duration: (json['duration'] as num?)?.toInt(),
  usage: json['usage'] == null
      ? null
      : UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TurnToJson(_Turn instance) => <String, dynamic>{
  'id': instance.id,
  'message': instance.message.toJson(),
  'responseParts': instance.responseParts.map((e) => e.toJson()).toList(),
  'state': _$TurnStateEnumMap[instance.state]!,
  'startedAt': ?instance.startedAt,
  'duration': ?instance.duration,
  'usage': ?instance.usage?.toJson(),
};

const _$TurnStateEnumMap = {
  TurnState.complete: 'complete',
  TurnState.cancelled: 'cancelled',
  TurnState.error: 'error',
};

_ActiveTurn _$ActiveTurnFromJson(Map<String, dynamic> json) => _ActiveTurn(
  id: json['id'] as String,
  startedAt: json['startedAt'] as String,
  message: Message.fromJson(json['message'] as Map<String, dynamic>),
  responseParts: (json['responseParts'] as List<dynamic>)
      .map((e) => ResponsePart.fromJson(e as Map<String, dynamic>))
      .toList(),
  usage: json['usage'] == null
      ? null
      : UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ActiveTurnToJson(_ActiveTurn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt,
      'message': instance.message.toJson(),
      'responseParts': instance.responseParts.map((e) => e.toJson()).toList(),
      'usage': ?instance.usage?.toJson(),
    };

_PendingMessage _$PendingMessageFromJson(Map<String, dynamic> json) =>
    _PendingMessage(
      id: json['id'] as String,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PendingMessageToJson(_PendingMessage instance) =>
    <String, dynamic>{'id': instance.id, 'message': instance.message.toJson()};

_ChatState _$ChatStateFromJson(Map<String, dynamic> json) => _ChatState(
  resource: json['resource'] as String,
  title: json['title'] as String,
  status: const SessionStatusConverter().fromJson(
    (json['status'] as num).toInt(),
  ),
  modifiedAt: json['modifiedAt'] as String,
  turns:
      (json['turns'] as List<dynamic>?)
          ?.map((e) => Turn.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Turn>[],
  activity: json['activity'] as String?,
  activeTurn: json['activeTurn'] == null
      ? null
      : ActiveTurn.fromJson(json['activeTurn'] as Map<String, dynamic>),
  turnsNextCursor: json['turnsNextCursor'] as String?,
  steeringMessage: json['steeringMessage'] == null
      ? null
      : PendingMessage.fromJson(
          json['steeringMessage'] as Map<String, dynamic>,
        ),
  queuedMessages: (json['queuedMessages'] as List<dynamic>?)
      ?.map((e) => PendingMessage.fromJson(e as Map<String, dynamic>))
      .toList(),
  workingDirectories: (json['workingDirectories'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  meta: json['_meta'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatStateToJson(
  _ChatState instance,
) => <String, dynamic>{
  'resource': instance.resource,
  'title': instance.title,
  'status': const SessionStatusConverter().toJson(instance.status),
  'modifiedAt': instance.modifiedAt,
  'turns': instance.turns.map((e) => e.toJson()).toList(),
  'activity': ?instance.activity,
  'activeTurn': ?instance.activeTurn?.toJson(),
  'turnsNextCursor': ?instance.turnsNextCursor,
  'steeringMessage': ?instance.steeringMessage?.toJson(),
  'queuedMessages': ?instance.queuedMessages?.map((e) => e.toJson()).toList(),
  'workingDirectories': ?instance.workingDirectories,
  '_meta': ?instance.meta,
};

ChatTurnStarted _$ChatTurnStartedFromJson(Map<String, dynamic> json) =>
    ChatTurnStarted(
      turnId: json['turnId'] as String,
      startedAt: json['startedAt'] as String,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
      queuedMessageId: json['queuedMessageId'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTurnStartedToJson(ChatTurnStarted instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'startedAt': instance.startedAt,
      'message': instance.message.toJson(),
      'queuedMessageId': ?instance.queuedMessageId,
      'type': instance.$type,
    };

ChatDelta _$ChatDeltaFromJson(Map<String, dynamic> json) => ChatDelta(
  turnId: json['turnId'] as String,
  partId: json['partId'] as String,
  content: json['content'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatDeltaToJson(ChatDelta instance) => <String, dynamic>{
  'turnId': instance.turnId,
  'partId': instance.partId,
  'content': instance.content,
  'type': instance.$type,
};

ChatReasoning _$ChatReasoningFromJson(Map<String, dynamic> json) =>
    ChatReasoning(
      turnId: json['turnId'] as String,
      partId: json['partId'] as String,
      content: json['content'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatReasoningToJson(ChatReasoning instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'partId': instance.partId,
      'content': instance.content,
      'type': instance.$type,
    };

ChatResponsePart _$ChatResponsePartFromJson(Map<String, dynamic> json) =>
    ChatResponsePart(
      turnId: json['turnId'] as String,
      part: ResponsePart.fromJson(json['part'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatResponsePartToJson(ChatResponsePart instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'part': instance.part.toJson(),
      'type': instance.$type,
    };

ChatToolCallStart _$ChatToolCallStartFromJson(Map<String, dynamic> json) =>
    ChatToolCallStart(
      turnId: json['turnId'] as String,
      toolCallId: json['toolCallId'] as String,
      toolName: json['toolName'] as String,
      displayName: json['displayName'] as String,
      intention: json['intention'] as String?,
      contributor: json['contributor'] as Map<String, dynamic>?,
      meta: json['_meta'] as Map<String, dynamic>?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatToolCallStartToJson(ChatToolCallStart instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'toolCallId': instance.toolCallId,
      'toolName': instance.toolName,
      'displayName': instance.displayName,
      'intention': ?instance.intention,
      'contributor': ?instance.contributor,
      '_meta': ?instance.meta,
      'type': instance.$type,
    };

ChatToolCallDelta _$ChatToolCallDeltaFromJson(Map<String, dynamic> json) =>
    ChatToolCallDelta(
      turnId: json['turnId'] as String,
      toolCallId: json['toolCallId'] as String,
      content: json['content'] as String?,
      invocationMessage: json['invocationMessage'],
      meta: json['_meta'] as Map<String, dynamic>?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatToolCallDeltaToJson(ChatToolCallDelta instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'toolCallId': instance.toolCallId,
      'content': ?instance.content,
      'invocationMessage': ?instance.invocationMessage,
      '_meta': ?instance.meta,
      'type': instance.$type,
    };

ChatToolCallReady _$ChatToolCallReadyFromJson(Map<String, dynamic> json) =>
    ChatToolCallReady(
      turnId: json['turnId'] as String,
      toolCallId: json['toolCallId'] as String,
      invocationMessage: json['invocationMessage'] as Object,
      toolInput: json['toolInput'],
      intention: json['intention'] as String?,
      contributor: json['contributor'] as Map<String, dynamic>?,
      confirmationTitle: json['confirmationTitle'],
      riskAssessment: json['riskAssessment'] as Map<String, dynamic>?,
      edits: json['edits'] as Map<String, dynamic>?,
      editable: json['editable'] as bool?,
      confirmed: json['confirmed'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ConfirmationOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: json['_meta'] as Map<String, dynamic>?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatToolCallReadyToJson(ChatToolCallReady instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'toolCallId': instance.toolCallId,
      'invocationMessage': instance.invocationMessage,
      'toolInput': ?instance.toolInput,
      'intention': ?instance.intention,
      'contributor': ?instance.contributor,
      'confirmationTitle': ?instance.confirmationTitle,
      'riskAssessment': ?instance.riskAssessment,
      'edits': ?instance.edits,
      'editable': ?instance.editable,
      'confirmed': ?instance.confirmed,
      'options': ?instance.options?.map((e) => e.toJson()).toList(),
      '_meta': ?instance.meta,
      'type': instance.$type,
    };

ChatToolCallConfirmed _$ChatToolCallConfirmedFromJson(
  Map<String, dynamic> json,
) => ChatToolCallConfirmed(
  turnId: json['turnId'] as String,
  toolCallId: json['toolCallId'] as String,
  approved: json['approved'] as bool,
  confirmed: json['confirmed'] as String?,
  reason: json['reason'] as String?,
  editedToolInput: json['editedToolInput'] as String?,
  selectedOptionId: json['selectedOptionId'] as String?,
  reasonMessage: json['reasonMessage'],
  userSuggestion: json['userSuggestion'] == null
      ? null
      : Message.fromJson(json['userSuggestion'] as Map<String, dynamic>),
  meta: json['_meta'] as Map<String, dynamic>?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatToolCallConfirmedToJson(
  ChatToolCallConfirmed instance,
) => <String, dynamic>{
  'turnId': instance.turnId,
  'toolCallId': instance.toolCallId,
  'approved': instance.approved,
  'confirmed': ?instance.confirmed,
  'reason': ?instance.reason,
  'editedToolInput': ?instance.editedToolInput,
  'selectedOptionId': ?instance.selectedOptionId,
  'reasonMessage': ?instance.reasonMessage,
  'userSuggestion': ?instance.userSuggestion?.toJson(),
  '_meta': ?instance.meta,
  'type': instance.$type,
};

ChatToolCallComplete _$ChatToolCallCompleteFromJson(
  Map<String, dynamic> json,
) => ChatToolCallComplete(
  turnId: json['turnId'] as String,
  toolCallId: json['toolCallId'] as String,
  result: json['result'] as Map<String, dynamic>,
  requiresResultConfirmation: json['requiresResultConfirmation'] as bool?,
  meta: json['_meta'] as Map<String, dynamic>?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatToolCallCompleteToJson(
  ChatToolCallComplete instance,
) => <String, dynamic>{
  'turnId': instance.turnId,
  'toolCallId': instance.toolCallId,
  'result': instance.result,
  'requiresResultConfirmation': ?instance.requiresResultConfirmation,
  '_meta': ?instance.meta,
  'type': instance.$type,
};

ChatToolCallResultConfirmed _$ChatToolCallResultConfirmedFromJson(
  Map<String, dynamic> json,
) => ChatToolCallResultConfirmed(
  turnId: json['turnId'] as String,
  toolCallId: json['toolCallId'] as String,
  approved: json['approved'] as bool,
  meta: json['_meta'] as Map<String, dynamic>?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatToolCallResultConfirmedToJson(
  ChatToolCallResultConfirmed instance,
) => <String, dynamic>{
  'turnId': instance.turnId,
  'toolCallId': instance.toolCallId,
  'approved': instance.approved,
  '_meta': ?instance.meta,
  'type': instance.$type,
};

ChatToolCallContentChanged _$ChatToolCallContentChangedFromJson(
  Map<String, dynamic> json,
) => ChatToolCallContentChanged(
  turnId: json['turnId'] as String,
  toolCallId: json['toolCallId'] as String,
  content: (json['content'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  meta: json['_meta'] as Map<String, dynamic>?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatToolCallContentChangedToJson(
  ChatToolCallContentChanged instance,
) => <String, dynamic>{
  'turnId': instance.turnId,
  'toolCallId': instance.toolCallId,
  'content': instance.content,
  '_meta': ?instance.meta,
  'type': instance.$type,
};

ChatTurnComplete _$ChatTurnCompleteFromJson(Map<String, dynamic> json) =>
    ChatTurnComplete(
      turnId: json['turnId'] as String,
      duration: (json['duration'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTurnCompleteToJson(ChatTurnComplete instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'duration': instance.duration,
      'type': instance.$type,
    };

ChatTurnCancelled _$ChatTurnCancelledFromJson(Map<String, dynamic> json) =>
    ChatTurnCancelled(
      turnId: json['turnId'] as String,
      duration: (json['duration'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTurnCancelledToJson(ChatTurnCancelled instance) =>
    <String, dynamic>{
      'turnId': instance.turnId,
      'duration': instance.duration,
      'type': instance.$type,
    };

ChatError _$ChatErrorFromJson(Map<String, dynamic> json) => ChatError(
  turnId: json['turnId'] as String,
  duration: (json['duration'] as num).toInt(),
  part: ResponsePart.fromJson(json['part'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatErrorToJson(ChatError instance) => <String, dynamic>{
  'turnId': instance.turnId,
  'duration': instance.duration,
  'part': instance.part.toJson(),
  'type': instance.$type,
};

ChatTurnResume _$ChatTurnResumeFromJson(Map<String, dynamic> json) =>
    ChatTurnResume(
      turnId: json['turnId'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTurnResumeToJson(ChatTurnResume instance) =>
    <String, dynamic>{'turnId': instance.turnId, 'type': instance.$type};

ChatActivityChanged _$ChatActivityChangedFromJson(Map<String, dynamic> json) =>
    ChatActivityChanged(
      activity: json['activity'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatActivityChangedToJson(
  ChatActivityChanged instance,
) => <String, dynamic>{'activity': ?instance.activity, 'type': instance.$type};

ChatUsage _$ChatUsageFromJson(Map<String, dynamic> json) => ChatUsage(
  turnId: json['turnId'] as String,
  usage: UsageInfo.fromJson(json['usage'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatUsageToJson(ChatUsage instance) => <String, dynamic>{
  'turnId': instance.turnId,
  'usage': instance.usage.toJson(),
  'type': instance.$type,
};

ChatTruncated _$ChatTruncatedFromJson(Map<String, dynamic> json) =>
    ChatTruncated(
      turnId: json['turnId'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTruncatedToJson(ChatTruncated instance) =>
    <String, dynamic>{'turnId': ?instance.turnId, 'type': instance.$type};

ChatTurnsLoaded _$ChatTurnsLoadedFromJson(Map<String, dynamic> json) =>
    ChatTurnsLoaded(
      turns: (json['turns'] as List<dynamic>)
          .map((e) => Turn.fromJson(e as Map<String, dynamic>))
          .toList(),
      turnsNextCursor: json['turnsNextCursor'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatTurnsLoadedToJson(ChatTurnsLoaded instance) =>
    <String, dynamic>{
      'turns': instance.turns.map((e) => e.toJson()).toList(),
      'turnsNextCursor': ?instance.turnsNextCursor,
      'type': instance.$type,
    };

ChatPendingMessageSet _$ChatPendingMessageSetFromJson(
  Map<String, dynamic> json,
) => ChatPendingMessageSet(
  kind: json['kind'] as String,
  id: json['id'] as String,
  message: Message.fromJson(json['message'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatPendingMessageSetToJson(
  ChatPendingMessageSet instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'id': instance.id,
  'message': instance.message.toJson(),
  'type': instance.$type,
};

ChatPendingMessageRemoved _$ChatPendingMessageRemovedFromJson(
  Map<String, dynamic> json,
) => ChatPendingMessageRemoved(
  kind: json['kind'] as String,
  id: json['id'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatPendingMessageRemovedToJson(
  ChatPendingMessageRemoved instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'id': instance.id,
  'type': instance.$type,
};

ChatIsReadChanged _$ChatIsReadChangedFromJson(Map<String, dynamic> json) =>
    ChatIsReadChanged(
      isRead: json['isRead'] as bool,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatIsReadChangedToJson(ChatIsReadChanged instance) =>
    <String, dynamic>{'isRead': instance.isRead, 'type': instance.$type};

ChatIsArchivedChanged _$ChatIsArchivedChangedFromJson(
  Map<String, dynamic> json,
) => ChatIsArchivedChanged(
  isArchived: json['isArchived'] as bool,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatIsArchivedChangedToJson(
  ChatIsArchivedChanged instance,
) => <String, dynamic>{
  'isArchived': instance.isArchived,
  'type': instance.$type,
};

ChatInputRequested _$ChatInputRequestedFromJson(Map<String, dynamic> json) =>
    ChatInputRequested(
      request: ChatInputRequest.fromJson(
        json['request'] as Map<String, dynamic>,
      ),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatInputRequestedToJson(ChatInputRequested instance) =>
    <String, dynamic>{
      'request': instance.request.toJson(),
      'type': instance.$type,
    };

ChatInputAnswerChanged _$ChatInputAnswerChangedFromJson(
  Map<String, dynamic> json,
) => ChatInputAnswerChanged(
  requestId: json['requestId'] as String,
  questionId: json['questionId'] as String,
  answer: json['answer'] as Map<String, dynamic>?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$ChatInputAnswerChangedToJson(
  ChatInputAnswerChanged instance,
) => <String, dynamic>{
  'requestId': instance.requestId,
  'questionId': instance.questionId,
  'answer': ?instance.answer,
  'type': instance.$type,
};

ChatInputCompleted _$ChatInputCompletedFromJson(Map<String, dynamic> json) =>
    ChatInputCompleted(
      requestId: json['requestId'] as String,
      response: json['response'] as String,
      answers: (json['answers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Map<String, dynamic>),
      ),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ChatInputCompletedToJson(ChatInputCompleted instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'response': instance.response,
      'answers': ?instance.answers,
      'type': instance.$type,
    };

ChatUnknownAction _$ChatUnknownActionFromJson(Map<String, dynamic> json) =>
    ChatUnknownAction(type: json['type'] as String);

Map<String, dynamic> _$ChatUnknownActionToJson(ChatUnknownAction instance) =>
    <String, dynamic>{'type': instance.type};
