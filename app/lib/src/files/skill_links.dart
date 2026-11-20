/// Skill references in turns and replies: indexing a session's skills
/// and matching `/skill` and `/skill:name` tokens in markdown and plain text.
library;

import 'dart:math' as math;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'file_paths.dart';

/// A skill that a link can open: its [name], its source [uri] (a `file:`
/// URI or URL), and the 1-based [line] and [endLine] of its declaration,
/// if any.
typedef SkillTarget = ({String name, String uri, int? line, int? endLine});

/// A matched link span in plain text: `[start, end)` and its [href].
typedef TextLinkMatch = ({int start, int end, String href});

/// The link target prefix the app gives skill references it finds in prose,
/// code spans, and user messages, so tapping opens the skill's file or URL
/// and rich copy keeps the text rather than a link.
const skillHrefPrefix = 'shireitou-skill:';

/// The href of a link to [skill].
String skillHref(SkillTarget skill) {
  final uri = skill.uri;
  final line = skill.line;
  if (line == null || uri.contains('#')) return '$skillHrefPrefix$uri';
  final end = skill.endLine;
  final fragment = end != null && end > line ? '#L$line-L$end' : '#L$line';
  return '$skillHrefPrefix$uri$fragment';
}

/// The underlying URI of a [skillHref], or null when [href] is not one.
String? skillTargetOfHref(String href) {
  final trimmed = href.trim();
  return trimmed.startsWith(skillHrefPrefix)
      ? trimmed.substring(skillHrefPrefix.length)
      : null;
}

/// The skills in [customizations] (enabled children of plugins and
/// directories), keyed by lower-cased skill name.
Map<String, SkillTarget> skillTargetsOf(List<Customization>? customizations) {
  final targets = <String, SkillTarget>{};
  for (final customization in customizations ?? const <Customization>[]) {
    final children = switch (customization) {
      PluginCustomization(:final children) ||
      DirectoryCustomization(:final children) => children ?? const [],
      _ => const <ChildCustomization>[],
    };
    for (final child in children) {
      if (child
          case SkillCustomization(
            :final name,
            :final uri,
            :final enabled,
            :final range,
          )
          when enabled != false && uri.isNotEmpty) {
        final key = name.toLowerCase();
        targets.putIfAbsent(key, () {
          final startLine = range == null ? null : range.start.line + 1;
          final endLine = range == null ? null : range.end.line + 1;
          return (
            name: name,
            uri: uri,
            line: startLine,
            endLine: endLine != null && startLine != null && endLine > startLine
                ? endLine
                : null,
          );
        });
      }
    }
  }
  return targets;
}

/// Skill targets carried on a user message's [attachments], keyed by
/// lower-cased skill name.
Map<String, SkillTarget> attachmentSkillTargets(
  List<MessageAttachment>? attachments,
) {
  final targets = <String, SkillTarget>{};
  for (final attachment in attachments ?? const <MessageAttachment>[]) {
    if (attachment case SimpleMessageAttachment(
      :final label,
      :final displayKind,
      :final meta,
    )) {
      final uri = meta?['uri'];
      if (uri is! String || uri.isEmpty) continue;
      final metaName = meta?['name'];
      final isSkill =
          displayKind == 'skill' || metaName is String || label.startsWith('/');
      if (!isSkill) continue;
      final name = metaName is String && metaName.isNotEmpty
          ? metaName
          : label.replaceFirst(RegExp(r'^/(?:skill:)?'), '');
      if (name.isEmpty) continue;
      targets.putIfAbsent(
        name.toLowerCase(),
        () => (name: name, uri: uri, line: null, endLine: null),
      );
    }
  }
  return targets;
}

/// A `/name` or `/skill:name` token: not inside a word, URL (`://`), or path,
/// and not ending in a sentence period.
final skillTokenPattern = RegExp(
  r'(?<![\w/.:~@+\-\\])'
  r'/([A-Za-z0-9](?:[A-Za-z0-9_:-]*[A-Za-z0-9_-])?(?:\.[A-Za-z0-9_-]+)*)'
  r'(?![\w/@+\-])',
);

/// The [SkillTarget] matching [token] (the part after `/`, with an optional
/// `skill:` prefix), or null when [skills] has no matching skill.
SkillTarget? lookupSkillTarget(String token, Map<String, SkillTarget> skills) {
  if (skills.isEmpty) return null;
  final key = token.trim().toLowerCase();
  if (skills[key] case final direct?) return direct;
  if (key.startsWith('skill:')) {
    return skills[key.substring('skill:'.length)];
  }
  return null;
}

/// [text] (such as a code span) as a [SkillTarget] when its whole content
/// is a `/name` or `/skill:name` for a skill in [skills], else null.
SkillTarget? parseSkillReference(String text, Map<String, SkillTarget> skills) {
  if (skills.isEmpty) return null;
  final trimmed = text.trim();
  final match = skillTokenPattern.matchAsPrefix(trimmed);
  if (match == null || match.end != trimmed.length) return null;
  return lookupSkillTarget(match[1]!, skills);
}

int? _offsetAt(String text, AhpTextPosition position) {
  if (position.line < 0 || position.character < 0) return null;
  var line = 0;
  var i = 0;
  while (line < position.line && i < text.length) {
    if (text.codeUnitAt(i) == 0x0a) line++;
    i++;
  }
  if (line != position.line) return null;
  return math.min(i + position.character, text.length);
}

/// The skill references in [text] from [skills] and [attachments], in order,
/// without overlaps.
List<TextLinkMatch> findSkillReferences(
  String text,
  Map<String, SkillTarget> skills, {
  List<MessageAttachment>? attachments,
}) {
  final allSkills = {...skills, ...attachmentSkillTargets(attachments)};
  final matches = <TextLinkMatch>[];

  for (final attachment in attachments ?? const <MessageAttachment>[]) {
    if (attachment case SimpleMessageAttachment(
      :final label,
      :final displayKind,
      :final meta,
      :final range?,
    )) {
      final uri = meta?['uri'];
      if (uri is! String || uri.isEmpty) continue;
      final metaName = meta?['name'];
      final isSkill =
          displayKind == 'skill' || metaName is String || label.startsWith('/');
      if (!isSkill) continue;
      final start = _offsetAt(text, range.start);
      final end = _offsetAt(text, range.end);
      if (start == null || end == null || start >= end) continue;
      final name = metaName is String && metaName.isNotEmpty
          ? metaName
          : label.replaceFirst(RegExp(r'^/(?:skill:)?'), '');
      matches.add((
        start: start,
        end: end,
        href: skillHref((name: name, uri: uri, line: null, endLine: null)),
      ));
    }
  }

  if (allSkills.isNotEmpty) {
    for (final m in skillTokenPattern.allMatches(text)) {
      if (lookupSkillTarget(m[1]!, allSkills) case final target?) {
        final overlaps = matches.any(
          (existing) => m.start < existing.end && m.end > existing.start,
        );
        if (!overlaps) {
          matches.add((start: m.start, end: m.end, href: skillHref(target)));
        }
      }
    }
  }

  matches.sort((a, b) => a.start.compareTo(b.start));
  return matches;
}

/// Merges [skillMatches] and [fileMatches] into a sorted, non-overlapping
/// list of link spans, preferring [skillMatches] when two spans overlap.
List<TextLinkMatch> mergeTextLinkMatches(
  List<TextLinkMatch> skillMatches,
  List<FileMatch> fileMatches,
  String text,
) {
  final merged = <TextLinkMatch>[...skillMatches];
  for (final file in fileMatches) {
    final overlaps = merged.any(
      (existing) => file.start < existing.end && file.end > existing.start,
    );
    if (!overlaps) {
      merged.add((
        start: file.start,
        end: file.end,
        href: filePathHref(text.substring(file.start, file.end)),
      ));
    }
  }
  merged.sort((a, b) => a.start.compareTo(b.start));
  return merged;
}

/// Gives the widgets below it the session's known skills so `/skill`
/// references in turns, replies, and plain text become clickable links.
class SkillLinkScope extends InheritedWidget {
  /// Creates a [SkillLinkScope] with [skills].
  const SkillLinkScope({super.key, required this.skills, required super.child});

  /// The session's skills, keyed by lower-cased name.
  final Map<String, SkillTarget> skills;

  /// The nearest scope's [skills], or an empty map.
  static Map<String, SkillTarget> maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkillLinkScope>()?.skills ??
      const {};

  @override
  bool updateShouldNotify(SkillLinkScope oldWidget) =>
      !mapEquals(skills, oldWidget.skills);
}
