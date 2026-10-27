/// Tests for reading the file viewer's files over `ssh` (AV-106, AV-016):
/// the command, the error message, and when `fileTextProvider` uses
/// `ssh` or the host's `resourceRead`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/files/ssh_file_read.dart';
import 'package:shireitou/src/hosts/saved_hosts.dart';
import 'package:shireitou/src/terminal/ssh_command.dart';

import 'fake_connection.dart';

const _remote = SavedHost(url: 'ws://10.0.0.5:63877?tkn=x', name: 'remote');
const _uri = 'file:///src/app/it%27s.dart';

void main() {
  test('sshReadFileArguments cats the quoted path in batch mode', () {
    expect(sshReadFileArguments('10.0.0.5', "/src/it's.dart"), [
      '-o',
      'BatchMode=yes',
      '-o',
      'ConnectTimeout=10',
      '--',
      '10.0.0.5',
      r"cat -- '/src/it'\''s.dart'",
    ]);
  });

  test('sshErrorMessage keeps the last line of stderr, else the code', () {
    expect(
      sshErrorMessage('warning\ncat: /a: No such file or directory\n\n', 1),
      'cat: /a: No such file or directory',
    );
    expect(sshErrorMessage('  \n', 255), 'ssh exited with code 255');
  });

  test('filePathOfUri decodes file URIs only', () {
    expect(filePathOfUri(_uri), "/src/app/it's.dart");
    expect(filePathOfUri('ahp-content:/1'), isNull);
  });

  group('fileTextProvider', () {
    late List<(String, String)> reads;
    late FakeHostConnection connection;

    ProviderContainer container({
      bool supported = true,
      Object? sshFailure,
      SavedHost host = _remote,
    }) {
      final c = ProviderContainer(
        overrides: [
          ...hostOverrides(connections: {host: connection}),
          sshFileReadSupportedProvider.overrideWithValue(supported),
          sshFileReaderProvider.overrideWithValue((
            sshHost,
            path, {
            required maxBytes,
          }) async {
            reads.add((sshHost, path));
            if (sshFailure != null) throw sshFailure;
            return Uint8List.fromList(utf8.encode('over ssh'));
          }),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      reads = [];
      connection = FakeHostConnection(
        const HostState(status: ConnectionStatus.connected),
        host: _remote.key,
      );
    });

    Future<String> read(ProviderContainer c) {
      final provider = fileTextProvider((host: _remote.key, uri: _uri));
      final sub = c.listen(provider.future, (_, _) {});
      addTearDown(sub.close);
      return sub.read();
    }

    test('reads over ssh from the host the terminal uses', () async {
      expect(await read(container()), 'over ssh');
      expect(reads, [('10.0.0.5', "/src/app/it's.dart")]);
    });

    test('uses resourceRead where ssh cannot run', () async {
      connection.contents[_uri] = 'from host';
      expect(await read(container(supported: false)), 'from host');
      expect(reads, isEmpty);
    });

    test('falls back to resourceRead when ssh fails', () async {
      connection.contents[_uri] = 'from host';
      final c = container(sshFailure: const SshReadException('denied'));
      expect(await read(c), 'from host');
      expect(reads, hasLength(1));
    });

    test("reports ssh's error when both fail", () async {
      final c = container(
        sshFailure: const SshReadException('cat: no such file'),
      );
      await expectLater(
        read(c),
        throwsA(
          isA<SshReadException>().having(
            (e) => e.message,
            'message',
            'cat: no such file',
          ),
        ),
      );
    });
  });
}
