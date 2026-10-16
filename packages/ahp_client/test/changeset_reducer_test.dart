import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

ChangesetState _reduce(ChangesetState state, JsonMap action) =>
    reduceChangesetJson(state, action);

JsonMap _file(String id, {bool? reviewed}) => {
  'id': id,
  'edit': {
    'after': {
      'uri': 'file:///$id',
      'content': {'uri': 'ahp-content:/$id'},
    },
  },
  'reviewed': ?reviewed,
};

void main() {
  final state = ChangesetState.fromJson({
    'status': 'ready',
    'files': [_file('a'), _file('b')],
    'operations': [
      {
        'id': 'commit',
        'label': 'Commit',
        'scopes': ['changeset'],
        'status': 'idle',
      },
    ],
  });

  test('status errors are kept only while the status is error', () {
    final failed = _reduce(state, {
      'type': 'changeset/statusChanged',
      'status': 'error',
      'error': {'errorType': 'git', 'message': 'no repo'},
    });
    expect(failed.error?.message, 'no repo');
    final recovered = _reduce(failed, {
      'type': 'changeset/statusChanged',
      'status': 'ready',
      'error': {'errorType': 'git', 'message': 'stale'},
    });
    expect(recovered.status, ChangesetStatus.ready);
    expect(recovered.error, isNull);
  });

  test('files are upserted in place, removed, reviewed and cleared', () {
    var next = _reduce(state, {
      'type': 'changeset/fileSet',
      'file': _file('c'),
    });
    next = _reduce(next, {
      'type': 'changeset/fileSet',
      'file': _file('a', reviewed: true),
    });
    expect(next.files.map((f) => f.id), ['a', 'b', 'c']);
    expect(next.files.first.reviewed, isTrue);
    next = _reduce(next, {'type': 'changeset/fileRemoved', 'fileId': 'b'});
    expect(next.files.map((f) => f.id), ['a', 'c']);
    expect(
      _reduce(next, {'type': 'changeset/fileRemoved', 'fileId': 'b'}),
      same(next),
    );
    final reviewed = _reduce(next, {
      'type': 'changeset/filesReviewChanged',
      'files': ['a', 'c'],
      'reviewed': true,
    });
    expect(reviewed.files.every((f) => f.reviewed == true), isTrue);
    expect(
      _reduce(reviewed, {
        'type': 'changeset/filesReviewChanged',
        'files': ['a'],
        'reviewed': true,
      }),
      same(reviewed),
    );
    final cleared = _reduce(reviewed, {'type': 'changeset/cleared'});
    expect(cleared.files, isEmpty);
    expect(_reduce(cleared, {'type': 'changeset/cleared'}), same(cleared));
  });

  test('content and operations are replaced; operation status changes', () {
    final content = _reduce(state, {
      'type': 'changeset/contentChanged',
      'files': [_file('z')],
    });
    expect(content.files.single.id, 'z');
    expect(content.operations, hasLength(1));
    final running = _reduce(state, {
      'type': 'changeset/operationStatusChanged',
      'operationId': 'commit',
      'status': 'error',
      'error': {'errorType': 'git', 'message': 'conflict'},
    });
    expect(running.operations!.single.error?.message, 'conflict');
    final idle = _reduce(running, {
      'type': 'changeset/operationStatusChanged',
      'operationId': 'commit',
      'status': 'idle',
    });
    expect(idle.operations!.single.error, isNull);
    expect(
      _reduce(state, {
        'type': 'changeset/operationStatusChanged',
        'operationId': 'x',
        'status': 'idle',
      }),
      same(state),
    );
    expect(
      _reduce(state, {'type': 'changeset/operationsChanged'}).operations,
      isNull,
    );
    expect(_reduce(state, {'type': 'changeset/x-future'}), same(state));
  });

  test('canvas/stateChanged replaces the canvas state', () {
    final canvas = CanvasState.fromJson({
      'instanceId': 'i',
      'extensionId': 'e',
      'canvasId': 'c',
    });
    final next = reduceCanvasJson(canvas, {
      'type': 'canvas/stateChanged',
      'canvas': {...canvas.toJson(), 'title': 'Board'},
    });
    expect(next.title, 'Board');
    expect(reduceCanvasJson(canvas, {'type': 'canvas/x'}), same(canvas));
  });
}
