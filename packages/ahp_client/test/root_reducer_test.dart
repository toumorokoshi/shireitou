import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  const agent = AgentInfo(
    provider: 'pi',
    displayName: 'Pi',
    description: '',
    models: [],
  );

  group('reduceRoot', () {
    test('root/agentsChanged replaces agents', () {
      final next = reduceRoot(
        const RootState(agents: []),
        RootAction.fromJson(const {
          'type': 'root/agentsChanged',
          'agents': [
            {'provider': 'pi', 'displayName': 'Pi', 'description': ''},
          ],
        }),
      );
      expect(next.agents, [agent]);
    });

    test('root/activeSessionsChanged updates the count', () {
      final next = reduceRoot(
        const RootState(agents: [], activeSessions: 0),
        const RootActiveSessionsChangedAction(activeSessions: 2),
      );
      expect(next.activeSessions, 2);
    });

    test('root/configChanged merges, or replaces with replace: true', () {
      const state = RootState(
        agents: [],
        config: RootConfigState(
          schema: ConfigSchema(properties: {}),
          values: {'a': 1, 'b': 2},
        ),
      );
      final merged = reduceRoot(
        state,
        const RootConfigChangedAction(config: {'b': 3}),
      );
      expect(merged.config!.values, {'a': 1, 'b': 3});
      final replaced = reduceRoot(
        state,
        const RootConfigChangedAction(config: {'b': 3}, replace: true),
      );
      expect(replaced.config!.values, {'b': 3});
    });

    test('root/configChanged without config is a no-op', () {
      const state = RootState(agents: []);
      expect(
        reduceRoot(state, const RootConfigChangedAction(config: {'a': 1})),
        same(state),
      );
    });

    test('unknown actions are ignored', () {
      const state = RootState(agents: [agent]);
      final action = RootAction.fromJson(const {'type': 'x-host/custom'});
      expect(action, isA<RootActionUnknown>());
      expect(reduceRoot(state, action), same(state));
    });
  });
}
