import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

const _terminal = TerminalState(
  title: 'bash',
  content: [],
  lifecycle: TerminalRunningLifecycleState(),
  claim: TerminalSessionClaim(session: 'ahp-session:/s', chat: 'ahp-chat:/c'),
);

TerminalState _reduce(TerminalState state, List<TerminalAction> actions) =>
    actions.fold(state, reduceTerminal);

void main() {
  group('reduceTerminal', () {
    test('data without a command goes to one unclassified part', () {
      final state = _reduce(_terminal, const [
        TerminalDataAction(data: 'hello '),
        TerminalDataAction(data: 'world'),
      ]);
      expect(state.content, const [
        TerminalUnclassifiedPart(value: 'hello world'),
      ]);
    });

    test('commands collect their output until they finish', () {
      final state = _reduce(_terminal, const [
        TerminalDataAction(data: 'banner\n'),
        TerminalCommandExecutedAction(
          commandId: 'c1',
          commandLine: 'npm test',
          timestamp: 1,
        ),
        TerminalDataAction(data: 'ok\n'),
        TerminalCommandFinishedAction(
          commandId: 'c1',
          exitCode: 0,
          durationMs: 40,
        ),
        TerminalDataAction(data: 'prompt'),
      ]);
      expect(state.supportsCommandDetection, isTrue);
      expect(state.content, const [
        TerminalUnclassifiedPart(value: 'banner\n'),
        TerminalCommandPart(
          commandId: 'c1',
          commandLine: 'npm test',
          output: 'ok\n',
          timestamp: 1,
          isComplete: true,
          exitCode: 0,
          durationMs: 40,
        ),
        TerminalUnclassifiedPart(value: 'prompt'),
      ]);
      expect(terminalTranscript(state), 'banner\n\$ npm test\nok\nprompt');
    });

    test('exit, clear, resize, title, cwd, claim and input', () {
      final state = _reduce(_terminal, const [
        TerminalDataAction(data: 'x'),
        TerminalInputAction(data: 'ignored'),
        TerminalResizedAction(cols: 80, rows: 24),
        TerminalTitleChangedAction(title: 'tests'),
        TerminalCwdChangedAction(cwd: 'file:///w'),
        TerminalClaimedAction(claim: TerminalClientClaim(clientId: 'me')),
        TerminalClearedAction(),
        TerminalExitedAction(exitCode: 2),
      ]);
      expect(state.content, isEmpty);
      expect((state.cols, state.rows), (80, 24));
      expect(state.title, 'tests');
      expect(state.cwd, 'file:///w');
      expect(state.claim, const TerminalClientClaim(clientId: 'me'));
      expect(state.lifecycle, const TerminalExitedLifecycleState(exitCode: 2));
    });

    test('unknown actions are no-ops', () {
      expect(
        reduceTerminalJson(_terminal, {'type': 'terminal/newThing'}),
        same(_terminal),
      );
    });
  });

  group('changeset templates', () {
    Changeset changeset(String template) =>
        Changeset(label: 'x', uriTemplate: template, changeKind: 'session');

    test('fixed templates are their own URI', () {
      final c = changeset('ahp-changeset:/s/session');
      expect(changesetScopeOf(c), ChangesetScope.fixed);
      expect(expandChangesetUri(c), 'ahp-changeset:/s/session');
    });

    test('turn templates need a turn ID, which is percent-encoded', () {
      final c = changeset('ahp-changeset:/s/turn/{turnId}');
      expect(changesetScopeOf(c), ChangesetScope.turn);
      expect(expandChangesetUri(c), isNull);
      expect(
        expandChangesetUri(c, turnId: 'a b/c'),
        'ahp-changeset:/s/turn/a%20b%2Fc',
      );
    });

    test('compare templates need both turns; unknown variables are empty', () {
      final c = changeset('x:/{originalTurnId}..{modifiedTurnId}{?other}');
      expect(changesetScopeOf(c), ChangesetScope.compareTurns);
      expect(expandChangesetUri(c, originalTurnId: 'a'), isNull);
      expect(
        expandChangesetUri(c, originalTurnId: 'a', modifiedTurnId: 'b'),
        'x:/a..b',
      );
    });

    test('file change kinds, counts and review progress', () {
      const before = FileEditSide(
        uri: 'file:///a',
        content: ContentRef(uri: 'c:/1'),
      );
      const after = FileEditSide(
        uri: 'file:///b',
        content: ContentRef(uri: 'c:/2'),
      );
      expect(
        fileChangeKindOf(const FileEdit(after: after)),
        FileChangeKind.created,
      );
      expect(
        fileChangeKindOf(const FileEdit(before: before)),
        FileChangeKind.deleted,
      );
      expect(
        fileChangeKindOf(const FileEdit(before: before, after: after)),
        FileChangeKind.renamed,
      );
      expect(
        fileChangeKindOf(const FileEdit(before: before, after: before)),
        FileChangeKind.modified,
      );
      const files = [
        ChangesetFile(
          id: 'a',
          edit: FileEdit(
            after: after,
            diff: FileEditDiffStats(added: 3, removed: 1),
          ),
          reviewed: true,
        ),
        ChangesetFile(
          id: 'b',
          edit: FileEdit(before: before, diff: FileEditDiffStats(removed: 4)),
        ),
      ];
      expect(changesetLineCounts(files), (added: 3, removed: 5));
      expect(reviewedCount(files), 1);
      expect(fileEditUri(files.last.edit), 'file:///a');
    });
  });

  group('HostState mirrors terminal, changeset and canvas channels', () {
    const terminalUri = 'ahp-terminal:/t';
    const changesetUri = 'ahp-changeset:/s/session';
    const canvasUri = 'ahp-canvas:/v';
    HostState subscribed() =>
        [
          (terminalUri, _terminal.toJson(), ChannelKind.terminal),
          (
            changesetUri,
            const ChangesetState(
              status: ChangesetStatus.ready,
              files: [],
            ).toJson(),
            ChannelKind.changeset,
          ),
          (
            canvasUri,
            const CanvasState(
              instanceId: 'i',
              extensionId: 'e',
              canvasId: 'c',
            ).toJson(),
            ChannelKind.canvas,
          ),
        ].fold(
          const HostState(protocolVersion: '1.0.0'),
          (state, s) => applySnapshot(
            state,
            Snapshot(resource: s.$1, state: s.$2, fromSeq: 1),
            s.$3,
          ),
        );

    test('snapshots and actions reach each kind', () {
      var state = subscribed();
      expect(channelKindOf(state, terminalUri), ChannelKind.terminal);
      expect(channelKindOf(state, changesetUri), ChannelKind.changeset);
      expect(channelKindOf(state, canvasUri), ChannelKind.canvas);
      for (final (i, (channel, action)) in [
        (terminalUri, const TerminalDataAction(data: 'out').toJson()),
        (
          changesetUri,
          const ChangesetStatusChangedAction(status: ChangesetStatus.computing)
              .toJson(),
        ),
        (
          canvasUri,
          const CanvasStateChangedAction(
            canvas: CanvasState(
              instanceId: 'i',
              extensionId: 'e',
              canvasId: 'c',
              title: 'Preview',
            ),
          ).toJson(),
        ),
      ].indexed) {
        state = applyEnvelope(
          state,
          ActionEnvelope(channel: channel, action: action, serverSeq: i + 2),
          clientId: 'me',
        );
      }
      expect(
        terminalTranscript(state.terminalChannels[terminalUri]!.state),
        'out',
      );
      expect(
        state.changesetChannels[changesetUri]!.state.status,
        ChangesetStatus.computing,
      );
      expect(state.canvasChannels[canvasUri]!.state.title, 'Preview');
      expect(state.serverSeq, 4);
    });

    test('review is written ahead and rolled back on rejection', () {
      final withFile = applyEnvelope(
        subscribed(),
        const ActionEnvelope(
          channel: changesetUri,
          action: {
            'type': 'changeset/fileSet',
            'file': {'id': 'a', 'edit': <String, Object?>{}},
          },
          serverSeq: 2,
        ),
        clientId: 'me',
      );
      final review = const ChangesetFilesReviewChangedAction(
        files: ['a'],
        reviewed: true,
      ).toJson();
      final pending = applyDispatchedAction(withFile, changesetUri, (
        clientSeq: 1,
        action: review,
      ));
      expect(
        pending.changesetChannels[changesetUri]!.state.files.single.reviewed,
        isTrue,
      );
      expect(pendingActionsOf(pending).keys, [changesetUri]);
      final rejected = applyEnvelope(
        pending,
        ActionEnvelope(
          channel: changesetUri,
          action: review,
          serverSeq: 3,
          origin: const ActionOrigin(clientId: 'me', clientSeq: 1),
          rejectionReason: 'no',
        ),
        clientId: 'me',
      );
      expect(
        rejected.changesetChannels[changesetUri]!.state.files.single.reviewed,
        isNull,
      );
    });

    test('removeChannel and unresumedChannels cover every kind', () {
      final state = subscribed();
      expect(unresumedChannels(state, const []).toSet(), {
        terminalUri,
        changesetUri,
        canvasUri,
      });
      final removed = [
        terminalUri,
        changesetUri,
        canvasUri,
      ].fold(state, removeChannel);
      expect(removed.terminalChannels, isEmpty);
      expect(removed.changesetChannels, isEmpty);
      expect(removed.canvasChannels, isEmpty);
    });
  });
}
