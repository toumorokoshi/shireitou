/// Pure logic for the remembered hosts list (AV-010).
library;

import 'dart:convert';

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';

/// How many hosts are remembered; the least recently used are dropped.
const maxSavedHosts = 20;

/// A remembered host: an optional display [name], its [url] (which may carry
/// the token as `?tkn=`), and a separate connection [token] (may be empty).
@immutable
class SavedHost {
  /// Creates a saved host.
  const SavedHost({required this.url, this.token = '', this.name = ''});

  /// Reads a host written by [toJson]; null if [json] is malformed.
  static SavedHost? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    final token = json['token'];
    final name = json['name'];
    return SavedHost(
      url: url,
      token: token is String ? token : '',
      name: name is String ? name : '',
    );
  }

  /// Display name; empty means "use the URL".
  final String name;

  /// The URL as entered.
  final String url;

  /// The connection token entered separately from the URL.
  final String token;

  /// Identifies the host regardless of its (rotating) token.
  String get key => hostKey(url);

  /// A label that never shows the token: [name], else the URL without `tkn`.
  String get label => name.isNotEmpty ? name : key;

  /// JSON for secure storage.
  Map<String, String> toJson() => {'name': name, 'url': url, 'token': token};

  @override
  bool operator ==(Object other) =>
      other is SavedHost &&
      other.name == name &&
      other.url == url &&
      other.token == token;

  @override
  int get hashCode => Object.hash(name, url, token);

  @override
  String toString() => 'SavedHost($label)';
}

/// [url] without its `tkn` query parameter, so a host whose token rotated
/// (pi makes a new one per run) is still the same host.
String hostKey(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return url.trim();
  final query = {...uri.queryParameters}..remove(tokenQueryParameter);
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    queryParameters: query.isEmpty ? null : query,
  ).toString();
}

/// Puts [host] first in [hosts], replacing the entry with the same [key]
/// (keeping its name when [host] has none) and keeping at most [max].
List<SavedHost> rememberHost(
  List<SavedHost> hosts,
  SavedHost host, {
  int max = maxSavedHosts,
}) {
  final previous = hosts.where((h) => h.key == host.key).firstOrNull;
  final merged = host.name.isEmpty && previous != null
      ? SavedHost(url: host.url, token: host.token, name: previous.name)
      : host;
  return [merged, ...hosts.where((h) => h.key != host.key)].take(max).toList();
}

/// [hosts] without the host whose [SavedHost.key] is [key].
List<SavedHost> forgetHost(List<SavedHost> hosts, String key) =>
    hosts.where((h) => h.key != key).toList();

/// Encodes [hosts] for storage.
String encodeHosts(List<SavedHost> hosts) =>
    jsonEncode([for (final h in hosts) h.toJson()]);

/// Decodes [encoded]; malformed input or entries are skipped.
List<SavedHost> decodeHosts(String? encoded) {
  if (encoded == null || encoded.isEmpty) return const [];
  try {
    final list = jsonDecode(encoded);
    if (list is! List) return const [];
    return [for (final item in list) ?SavedHost.fromJson(item)];
  } on FormatException {
    return const [];
  }
}
