/// The host's last full `completions` answer per chat, so the popup can
/// show it at once while the host answers again (AV-044).
library;

import 'package:ahp_client/ahp_client.dart';

/// Where in a chat's message a word is completed. Hosts answer
/// differently at the start of a message (pi offers its prompts there
/// and only its skills later), and [commands] changes when the session's
/// customizations do, which retires older answers.
String completionCacheKey({
  required String chat,
  required CompletionToken token,
  List<SlashCommand> commands = const [],
}) => [
  chat,
  token.trigger,
  if (token.start == 0) 'start' else 'later',
  for (final command in commands) command.name,
].join('\u0000');

/// The host's answers for a bare trigger (such as `/` with nothing typed
/// after it), which list every item, by [completionCacheKey]. Holds at most
/// [capacity] answers, dropping the least recently used.
class CompletionCache {
  /// Creates an empty [CompletionCache].
  CompletionCache({this.capacity = 64});

  /// The most answers kept.
  final int capacity;

  final _answers = <String, List<CompletionItem>>{};

  /// The answer kept for [key], if any.
  List<CompletionItem>? operator [](String key) {
    final answer = _answers.remove(key);
    if (answer != null) _answers[key] = answer;
    return answer;
  }

  /// Keeps [items], the host's answer for [token], under [key] when the
  /// answer lists every item (nothing typed after the trigger) and is not
  /// empty.
  void remember(String key, CompletionToken token, List<CompletionItem> items) {
    if (token.query.isNotEmpty || items.isEmpty) return;
    _answers
      ..remove(key)
      ..[key] = items;
    while (_answers.length > capacity) {
      _answers.remove(_answers.keys.first);
    }
  }
}
