import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

AgentInfo _agent({MultipleChatsCapability? chats}) => AgentInfo(
  provider: 'pi',
  displayName: 'Pi',
  description: 'Pi',
  models: const [],
  capabilities: AgentCapabilities(multipleChats: chats),
);

Turn _turn(TurnState state) => Turn(
  id: 't',
  message: userMessage('Hi'),
  state: state,
  responseParts: const [],
);

void main() {
  test('only agents that advertise multipleChats.fork can fork', () {
    expect(canForkChats(null), isFalse);
    expect(canForkChats(_agent()), isFalse);
    expect(canForkChats(_agent(chats: const MultipleChatsCapability())), false);
    expect(
      canForkChats(
        _agent(chats: const MultipleChatsCapability(sideChat: true)),
      ),
      isFalse,
    );
    expect(
      canForkChats(_agent(chats: const MultipleChatsCapability(fork: true))),
      isTrue,
    );
  });

  test('only completed turns are fork points', () {
    expect(isForkableTurn(_turn(TurnState.complete)), isTrue);
    expect(isForkableTurn(_turn(TurnState.cancelled)), isFalse);
    expect(isForkableTurn(_turn(TurnState.error)), isFalse);
  });
}
