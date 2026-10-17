import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/ssh/ssh_agent_codec.dart';
import 'package:shireitou/src/ssh/ssh_settings.dart';
import 'package:shireitou/src/ssh/ssh_terminal.dart';

import 'fixtures.dart';

void main() {
  group('SshSettings', () {
    const settings = SshSettings(
      host: 'build.example.com',
      port: 2222,
      user: 'me',
      auth: SshAuthMethod.privateKey,
      privateKey: 'KEY',
      passphrase: 'pass',
    );

    test('round-trips through JSON', () {
      expect(
        SshSettings.fromJson(jsonDecode(jsonEncode(settings.toJson()))),
        settings,
      );
    });

    test('reads malformed JSON as null or defaults', () {
      expect(SshSettings.fromJson('nope'), isNull);
      expect(SshSettings.fromJson({'host': ''}), isNull);
      expect(
        SshSettings.fromJson({'host': 'h', 'port': 99999, 'auth': 'magic'}),
        const SshSettings(host: 'h'),
      );
    });

    test('labels the user, host and a port other than 22', () {
      expect(settings.label, 'me@build.example.com:2222');
      expect(const SshSettings(host: 'h').label, 'h');
      expect(settings.target, 'build.example.com:2222');
    });

    test('defaults the host to the AHP host URL host', () {
      expect(
        defaultSshSettings('ws://10.0.0.5:63877?tkn=secret'),
        const SshSettings(host: '10.0.0.5'),
      );
      expect(
        defaultSshSettings('wss://agents.example.com/ahp').host,
        'agents.example.com',
      );
    });

    test('names what is missing', () {
      expect(sshSettingsProblem(settings), isNull);
      expect(sshSettingsProblem(const SshSettings(host: '')), contains('host'));
      expect(
        sshSettingsProblem(const SshSettings(host: 'h', port: 0, user: 'u')),
        contains('port'),
      );
      expect(
        sshSettingsProblem(const SshSettings(host: 'h')),
        contains('user'),
      );
      expect(
        sshSettingsProblem(
          const SshSettings(
            host: 'h',
            user: 'u',
            auth: SshAuthMethod.privateKey,
          ),
        ),
        contains('private key'),
      );
      expect(
        sshSettingsProblem(
          const SshSettings(host: 'h', user: 'u', auth: SshAuthMethod.agent),
        ),
        isNull,
      );
    });

    test('never shows secrets in toString', () {
      expect('$settings', isNot(contains('KEY')));
      expect('$settings', isNot(contains('pass')));
    });
  });

  group('host keys', () {
    const key = (type: 'ssh-ed25519', fingerprint: 'SHA256:abc');
    const other = (type: 'ssh-ed25519', fingerprint: 'SHA256:xyz');

    test('trusts on first use, accepts the same key, refuses a change', () {
      expect(decideHostKey(null, key), HostKeyDecision.trustNew);
      expect(decideHostKey(key, key), HostKeyDecision.matches);
      expect(decideHostKey(key, other), HostKeyDecision.changed);
      expect(
        decideHostKey(key, (type: 'ssh-rsa', fingerprint: 'SHA256:abc')),
        HostKeyDecision.changed,
      );
    });

    test('explains a changed key with both fingerprints', () {
      final message = changedHostKeyMessage('h:22', key, other);
      expect(message, contains('has changed'));
      expect(message, contains('SHA256:abc'));
      expect(message, contains('SHA256:xyz'));
      expect(message, contains('Forget host key'));
    });

    test('round-trip through storage, dropping malformed entries', () {
      final hosts = {'h:22': key};
      expect(decodeKnownHosts(encodeKnownHosts(hosts)), hosts);
      expect(decodeKnownHosts('{"h:22":{"type":1},"x":2}'), isEmpty);
      expect(decodeKnownHosts('not json'), isEmpty);
      expect(decodeKnownHosts(null), isEmpty);
    });
  });

  group('commands', () {
    test('quote paths for the shell', () {
      expect(shellQuote('/src/app'), "'/src/app'");
      expect(shellQuote("it's here"), r"'it'\''s here'");
      expect(changeDirectoryCommand('/a b'), "cd '/a b' && clear\n");
    });

    test("take a session's folder as a path", () {
      expect(
        sessionDirectory(session('1', directory: 'file:///src/my%20app/')),
        '/src/my app',
      );
      expect(sessionDirectory(session('1', project: 'file:///p')), '/p');
      expect(sessionDirectory(session('1')), isNull);
      expect(
        sessionDirectory(session('1', directory: 'vscode-remote://x/y')),
        isNull,
      );
      expect(sessionDirectory(null), isNull);
    });

    test('send typed characters with Ctrl', () {
      expect(withControl('c'), '\x03');
      expect(withControl('C'), '\x03');
      expect(withControl('['), '\x1b');
      expect(withControl(' '), '\x00');
      expect(withControl('?'), '\x7f');
      expect(withControl('1'), '1');
      expect(withControl('\x1b[A'), '\x1b[A');
    });
  });

  group('SSH agent messages', () {
    Uint8List string(List<int> bytes) => Uint8List.fromList([
      ...[0, 0, 0, bytes.length],
      ...bytes,
    ]);
    final blob = string(utf8.encode('ssh-ed25519'));

    test('frame and unframe', () {
      final framed = frameAgentMessage(requestIdentitiesMessage());
      expect(framed, [0, 0, 0, 1, agentRequestIdentities]);
      expect(readAgentFrame(Uint8List.sublistView(framed, 0, 4)), isNull);
      final (payload, length) = readAgentFrame(
        Uint8List.fromList([...framed, 9]),
      )!;
      expect(payload, [agentRequestIdentities]);
      expect(length, 5);
    });

    test('parse the identities answer', () {
      final answer = Uint8List.fromList([
        agentIdentitiesAnswer,
        ...[0, 0, 0, 1],
        ...string(blob),
        ...string(utf8.encode('me@laptop')),
      ]);
      final [identity] = parseIdentitiesAnswer(answer);
      expect(identity.blob, blob);
      expect(identity.comment, 'me@laptop');
      expect(agentKeyType(identity.blob), 'ssh-ed25519');
      expect(
        () => parseIdentitiesAnswer(Uint8List.fromList([5])),
        throwsFormatException,
      );
      expect(
        () => parseIdentitiesAnswer(
          Uint8List.fromList([agentIdentitiesAnswer, 0, 0, 0, 1]),
        ),
        throwsFormatException,
      );
    });

    test('build sign requests and read the signature', () {
      final data = Uint8List.fromList([1, 2]);
      expect(signRequestMessage(blob, data, agentRsaSha2_256), [
        agentSignRequest,
        ...string(blob),
        ...string(data),
        ...[0, 0, 0, agentRsaSha2_256],
      ]);
      expect(
        parseSignResponse(
          Uint8List.fromList([
            agentSignResponse,
            ...string([7, 8]),
          ]),
        ),
        [7, 8],
      );
      expect(
        () => parseSignResponse(Uint8List.fromList([5])),
        throwsA(isA<FormatException>()),
      );
    });

    test('sign RSA keys with rsa-sha2-256', () {
      expect(agentSignatureAlgorithm('ssh-rsa'), (
        'rsa-sha2-256',
        agentRsaSha2_256,
      ));
      expect(agentSignatureAlgorithm('ssh-ed25519'), ('ssh-ed25519', 0));
    });
  });
}
