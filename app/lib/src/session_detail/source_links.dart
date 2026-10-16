/// Pull request and branch links from a session's `_meta` (AV-105).
///
/// AHP has no field for them. Hosts that know them use `_meta`
/// conventions, which this reads:
///
/// - `copilot.githubReferences`: a list of GitHub references; the entry
///   with `referenceType: "pr"` and `"headBranch"` in its `relations` is
///   the pull request of the session's branch (the Copilot convention,
///   which VS Code's agent host also publishes in session state and
///   summaries).
/// - `git`: VS Code's git state (`branchName`, `githubOwner`,
///   `githubRepo`), from which a branch link on GitHub is built.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

/// A pull request a host associates with the session's branch.
@immutable
class PullRequestLink {
  /// Creates a [PullRequestLink].
  const PullRequestLink({
    required this.url,
    this.number,
    this.title,
    this.state,
    this.repository,
  });

  /// The pull request's web URL.
  final String url;

  /// Its number.
  final int? number;

  /// Its title (may be empty).
  final String? title;

  /// `open`, `closed`, `merged` or `draft`.
  final String? state;

  /// `owner/repo`.
  final String? repository;

  /// "PR #12 · merged".
  String get label => [
    if (number != null) 'PR #$number' else 'Pull request',
    ?state,
  ].join(' · ');

  @override
  bool operator ==(Object other) =>
      other is PullRequestLink &&
      other.url == url &&
      other.number == number &&
      other.title == title &&
      other.state == state &&
      other.repository == repository;

  @override
  int get hashCode => Object.hash(url, number, title, state, repository);
}

/// The session's branch, and its page on GitHub when the host reports the
/// repository.
@immutable
class BranchLink {
  /// Creates a [BranchLink].
  const BranchLink(this.name, {this.url});

  /// The branch name.
  final String name;

  /// The branch's web page, if known.
  final String? url;

  @override
  bool operator ==(Object other) =>
      other is BranchLink && other.name == name && other.url == url;

  @override
  int get hashCode => Object.hash(name, url);
}

/// What a session links out to.
typedef SourceLinks = ({PullRequestLink? pullRequest, BranchLink? branch});

const _githubReferencesKey = 'copilot.githubReferences';

final _pullUrl = RegExp(
  r'^https?://[^/?#@\s]+/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)/pull/([1-9][0-9]*)$',
);

/// The head-branch pull request in [meta]'s `copilot.githubReferences`,
/// or null. Entries whose URL is not a pull request URL are skipped.
PullRequestLink? pullRequestOf(JsonMap? meta) {
  final entries = meta?[_githubReferencesKey];
  if (entries is! List) return null;
  for (final entry in entries) {
    if (entry is! Map ||
        entry['referenceType'] != 'pr' ||
        entry['url'] is! String ||
        entry['relations'] is! List ||
        !(entry['relations'] as List).contains('headBranch')) {
      continue;
    }
    final url = entry['url'] as String;
    final match = _pullUrl.firstMatch(url);
    if (match == null) continue;
    final state = entry['state'];
    return PullRequestLink(
      url: url,
      number: int.parse(match.group(3)!),
      title: switch (entry['title']) {
        final String t when t.isNotEmpty => t,
        _ => null,
      },
      state: switch (state) {
        'open' || 'closed' || 'merged' || 'draft' => state as String,
        _ => null,
      },
      repository: '${match.group(1)}/${match.group(2)}',
    );
  }
  return null;
}

/// The branch in [meta]'s `git` state, with a GitHub link when the host
/// names the repository (`githubOwner`/`githubRepo`).
BranchLink? branchOf(JsonMap? meta) {
  final git = meta?['git'];
  if (git is! Map) return null;
  final name = git['branchName'];
  if (name is! String || name.isEmpty) return null;
  final owner = git['githubOwner'];
  final repo = git['githubRepo'];
  return BranchLink(
    name,
    url:
        owner is String && owner.isNotEmpty && repo is String && repo.isNotEmpty
        ? 'https://github.com/$owner/$repo/tree/'
              '${name.split('/').map(Uri.encodeComponent).join('/')}'
        : null,
  );
}

/// The links of a session from its state's `_meta` ([session]) or, when
/// that has none, its catalogue entry's ([summary]).
SourceLinks sourceLinksOf({JsonMap? session, JsonMap? summary}) => (
  pullRequest: pullRequestOf(session) ?? pullRequestOf(summary),
  branch: branchOf(session) ?? branchOf(summary),
);
