/// Tells the user when hosts cannot be read from or saved to secure
/// storage, for example because the Linux keyring is locked (AV-010).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hosts/host_store.dart';

/// A banner with the storage problem and a Retry button; nothing when
/// storage works.
class HostStorageBanner extends ConsumerWidget {
  /// Creates a [HostStorageBanner].
  const HostStorageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(hostStorageProblemProvider);
    if (problem == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MaterialBanner(
        backgroundColor: scheme.errorContainer,
        leading: Icon(Icons.lock_outline, color: scheme.onErrorContainer),
        content: Text(
          problem,
          style: TextStyle(color: scheme.onErrorContainer),
        ),
        actions: [
          TextButton(
            onPressed: () => ref.read(savedHostsProvider.notifier).retry(),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () =>
                ref.read(hostStorageProblemProvider.notifier).report(null),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
