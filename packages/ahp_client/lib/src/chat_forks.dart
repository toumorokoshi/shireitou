/// Pure rules for forking a chat from one of its turns (`createChat` with
/// a `ForkChatSource`, AHP-045).
library;

import 'wire.dart';

/// Whether [agent] lets clients fork its chats
/// (`capabilities.multipleChats.fork`). Clients MUST NOT send a fork
/// source otherwise.
bool canForkChats(AgentInfo? agent) =>
    agent?.capabilities?.multipleChats?.fork ?? false;

/// Whether [turn] can be a fork point: forks target completed turns, not
/// cancelled or failed ones.
bool isForkableTurn(Turn turn) => turn.state == TurnState.complete;
