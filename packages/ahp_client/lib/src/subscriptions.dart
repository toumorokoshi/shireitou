/// Pure reference counting for channel subscriptions (AHP-020).
library;

/// Channel URI to the number of local observers.
typedef SubscriptionCounts = Map<String, int>;

/// The result of changing a reference count.
typedef SubscriptionChange = ({SubscriptionCounts counts, bool sendToHost});

/// Adds an observer of [channel]. `sendToHost` is true for the first one,
/// when `subscribe` must be sent.
SubscriptionChange acquireSubscription(
  SubscriptionCounts counts,
  String channel,
) {
  final count = counts[channel] ?? 0;
  return (
    counts: Map.unmodifiable({...counts, channel: count + 1}),
    sendToHost: count == 0,
  );
}

/// Removes an observer of [channel]. `sendToHost` is true for the last one,
/// when `unsubscribe` must be sent. Releasing an unknown channel is a no-op.
SubscriptionChange releaseSubscription(
  SubscriptionCounts counts,
  String channel,
) {
  final count = counts[channel] ?? 0;
  if (count == 0) return (counts: counts, sendToHost: false);
  final next = {...counts};
  if (count == 1) {
    next.remove(channel);
  } else {
    next[channel] = count - 1;
  }
  return (counts: Map.unmodifiable(next), sendToHost: count == 1);
}
