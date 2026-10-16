import 'package:ahp_client/ahp_client.dart';

/// Builds a [SessionSummary] for tests.
SessionSummary session(
  String id, {
  String? directory,
  String? project,
  String modifiedAt = '2026-10-01T00:00:00Z',
  int status = 33,
  String? title,
}) => SessionSummary(
  resource: 'pi:/$id',
  provider: 'pi',
  title: title ?? 'session $id',
  status: SessionStatus(status),
  createdAt: '2026-10-01T00:00:00Z',
  modifiedAt: modifiedAt,
  workingDirectories: directory == null ? null : [directory],
  project: project == null
      ? null
      : ProjectInfo(uri: project, displayName: project),
);
