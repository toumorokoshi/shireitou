/// The names agents are shown by.
library;

import 'package:ahp_client/ahp_client.dart';

/// The name to show for the agent [provider] ("Pi"): its
/// `AgentInfo.displayName` among [agents], else [provider] itself ("pi")
/// when the host has not listed it (yet) or gave it no display name.
String agentDisplayName(String provider, Iterable<AgentInfo> agents) =>
    switch (agents.where((a) => a.provider == provider).firstOrNull) {
      AgentInfo(:final displayName) when displayName.isNotEmpty => displayName,
      _ => provider,
    };
