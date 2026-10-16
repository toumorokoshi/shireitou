import 'package:ahp_client/ahp_client.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:test/test.dart';

void main() {
  test('compareProtocolVersions orders by major, minor, patch', () {
    expect(compareProtocolVersions('1.0.0', '0.9.0'), greaterThan(0));
    expect(compareProtocolVersions('0.9.0', '0.10.0'), lessThan(0));
    expect(compareProtocolVersions('0.9.1', '0.9.0'), greaterThan(0));
    expect(compareProtocolVersions('1.0.0', '1.0.0'), 0);
    expect(compareProtocolVersions('1.0', '1.0.0'), 0);
  });

  test('the offered versions are the target and its fallback', () {
    expect(offeredProtocolVersions.first, targetProtocolVersion);
    expect(offeredProtocolVersions, contains('0.9.0'));
  });

  group('isActionKnownToVersion', () {
    test('0.9.0 lacks every action added in 1.0.0', () {
      for (final type in actionsAddedIn100) {
        expect(isActionKnownToVersion(type, '0.9.0'), isFalse, reason: type);
        expect(isActionKnownToVersion(type, '1.0.0'), isTrue, reason: type);
        expect(isActionKnownToVersion(type, '1.2.0'), isTrue, reason: type);
      }
      expect(actionsAddedIn100, hasLength(10));
    });

    test('older actions are known to 0.9.0', () {
      for (final type in [
        'chat/turnStarted',
        'chat/turnResume',
        'session/isArchivedChanged',
        'root/agentsChanged',
      ]) {
        expect(isActionKnownToVersion(type, '0.9.0'), isTrue, reason: type);
      }
    });

    test('an unnegotiated version knows everything', () {
      expect(isActionKnownToVersion('chat/isReadChanged', null), isTrue);
    });
  });

  test('0.9.0 lacks every feature; 1.0.0 none', () {
    expect(unavailableFeatures('0.9.0'), ProtocolFeature.values);
    expect(unavailableFeatures('1.0.0'), isEmpty);
    expect(unavailableFeatures(null), isEmpty);
    expect(supportsFeature('0.9.0', ProtocolFeature.chatArchive), isFalse);
    expect(supportsFeature('1.0.0', ProtocolFeature.chatArchive), isTrue);
  });

  test('UnsupportedActionError names the action and versions', () {
    final error = UnsupportedActionError('chat/isReadChanged', '0.9.0');
    expect(error, isA<StateError>());
    expect(error.message, contains('chat/isReadChanged needs protocol 1.0.0'));
    expect(error.message, contains('0.9.0'));
  });

  test('isLivenessFailure: only unanswered pings are failures', () {
    expect(isLivenessFailure(RpcException.methodNotFound('ping')), isFalse);
    expect(isLivenessFailure(Exception('timeout')), isTrue);
    expect(isLivenessFailure(StateError('closed')), isTrue);
  });
}
