/// Tests for clickable skill links in user turns, agent responses, and
/// plain text.
library;

import 'package:ahp_client/ahp_client.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/files/file_path_text.dart';
import 'package:shireitou/src/files/file_paths.dart';
import 'package:shireitou/src/files/open_file_store.dart';
import 'package:shireitou/src/files/skill_links.dart';
import 'package:shireitou/src/session_detail/link_menu.dart';
import 'package:shireitou/src/session_detail/timeline_parts.dart';

const _reviewUri = 'file:///home/me/.agents/skills/review/SKILL.md';
const _deployUri = 'file:///work/.agents/skills/deploy/SKILL.md';
const _webSkillUri = 'https://example.com/skills/docs';

const _customizations = <Customization>[
  DirectoryCustomization(
    id: 'dir-1',
    uri: 'file:///home/me/.agents/skills',
    name: 'skills',
    enabled: true,
    contents: ChildCustomizationType.skill,
    writable: false,
    children: [
      SkillCustomization(
        id: 'skill-review',
        uri: _reviewUri,
        name: 'review',
        description: 'Review code changes',
      ),
      SkillCustomization(
        id: 'skill-hidden',
        uri: 'file:///home/me/.agents/skills/hidden/SKILL.md',
        name: 'hidden',
        disableUserInvocation: true,
      ),
      SkillCustomization(
        id: 'skill-disabled',
        uri: 'file:///home/me/.agents/skills/disabled/SKILL.md',
        name: 'disabled',
        enabled: false,
      ),
    ],
  ),
  PluginCustomization(
    id: 'plugin-1',
    uri: 'https://example.com/plugin',
    name: 'plugin',
    children: [
      SkillCustomization(
        id: 'skill-deploy',
        uri: _deployUri,
        name: 'deploy',
        range: AhpTextRange(
          start: AhpTextPosition(line: 9, character: 0),
          end: AhpTextPosition(line: 14, character: 0),
        ),
      ),
      SkillCustomization(id: 'skill-docs', uri: _webSkillUri, name: 'docs'),
    ],
  ),
];

void main() {
  group('skillTargetsOf and findSkillReferences', () {
    test('extracts enabled skills including model-only ones and lines', () {
      final skills = skillTargetsOf(_customizations);

      expect(skills.keys, containsAll(['review', 'hidden', 'deploy', 'docs']));
      expect(skills.containsKey('disabled'), isFalse);
      expect(skills['review'], (
        name: 'review',
        uri: _reviewUri,
        line: null,
        endLine: null,
      ));
      expect(skills['deploy'], (
        name: 'deploy',
        uri: _deployUri,
        line: 10,
        endLine: 15,
      ));
    });

    test('matches /name and /skill:name in prose and skips URLs/paths', () {
      final skills = skillTargetsOf(_customizations);
      const text =
          'Run /review or /skill:deploy. '
          'Ignore /unknown, src/review, and https://example.com/review.';

      final matches = findSkillReferences(text, skills);

      expect(
        [for (final m in matches) text.substring(m.start, m.end)],
        ['/review', '/skill:deploy'],
      );
      expect(matches[0].href, '$skillHrefPrefix$_reviewUri');
      expect(matches[1].href, '$skillHrefPrefix$_deployUri#L10-L15');
    });

    test('uses skill attachments including explicit ranges', () {
      const text = 'Use /custom to format';
      final attachments = <MessageAttachment>[
        const SimpleMessageAttachment(
          label: '/custom',
          displayKind: 'skill',
          meta: {'uri': _reviewUri, 'name': 'custom'},
          range: AhpTextRange(
            start: AhpTextPosition(line: 0, character: 4),
            end: AhpTextPosition(line: 0, character: 11),
          ),
        ),
      ];

      final matches = findSkillReferences(
        text,
        const {},
        attachments: attachments,
      );

      expect(matches, [
        (start: 4, end: 11, href: '$skillHrefPrefix$_reviewUri'),
      ]);
    });

    test('linkText and followLink unwrap skill hrefs', () {
      final skills = skillTargetsOf(_customizations);
      final deployHref = skillHref(skills['deploy']!);
      final docsHref = skillHref(skills['docs']!);

      expect(
        linkText(deployHref),
        '/work/.agents/skills/deploy/SKILL.md:10-15',
      );
      expect(linkText(docsHref), _webSkillUri);

      final opened = <FileReference>[];
      followLink(deployHref, openFile: opened.add);
      expect(opened, [
        (path: '/work/.agents/skills/deploy/SKILL.md', line: 10, endLine: 15),
      ]);
    });
  });

  group('widget skill links', () {
    Widget wrap(
      Widget child, {
      required List<FileReference> opened,
      Map<String, SkillTarget>? skills,
    }) => MaterialApp(
      home: Scaffold(
        body: FileLinkScope(
          onOpen: opened.add,
          child: SkillLinkScope(
            skills: skills ?? skillTargetsOf(_customizations),
            child: child,
          ),
        ),
      ),
    );

    testWidgets('MarkdownText links /skill in prose and code spans', (
      tester,
    ) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        wrap(
          const MarkdownText(
            'Try /review or `/skill:deploy` and [link](https://example.com/review).',
          ),
          opened: opened,
        ),
      );

      await tester.tapOnText(find.textRange.ofSubstring('/review'));
      await tester.tapOnText(find.textRange.ofSubstring('/skill:deploy'));

      expect(opened, [
        (
          path: '/home/me/.agents/skills/review/SKILL.md',
          line: null,
          endLine: null,
        ),
        (path: '/work/.agents/skills/deploy/SKILL.md', line: 10, endLine: 15),
      ]);
    });

    testWidgets('right-clicking a skill link in MarkdownText shows dialog', (
      tester,
    ) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        wrap(const MarkdownText('See /review.'), opened: opened),
      );

      final box = tester.renderObject<RenderBox>(find.byType(RichText).first);
      final at = box.localToGlobal(const Offset(80, 8));
      await tester.tapAt(
        at,
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(find.text('File'), findsOneWidget);
      expect(find.text('Copy path'), findsOneWidget);
      await tester.tap(find.text('Open file'));
      await tester.pumpAndSettle();

      expect(opened, [
        (
          path: '/home/me/.agents/skills/review/SKILL.md',
          line: null,
          endLine: null,
        ),
      ]);
    });

    testWidgets(
      'UserMessageBubble links scope skills, attachments, and files',
      (tester) async {
        final opened = <FileReference>[];
        const message = Message(
          text: 'Run /review and /skill:custom on lib/main.dart',
          origin: MessageOrigin(kind: MessageKind.user),
          attachments: [
            SimpleMessageAttachment(
              label: '/skill:custom',
              displayKind: 'skill',
              meta: {'uri': _deployUri, 'name': 'custom'},
            ),
          ],
        );
        await tester.pumpWidget(
          wrap(const UserMessageBubble(message: message), opened: opened),
        );

        await tester.tapOnText(find.textRange.ofSubstring('/review'));
        await tester.tapOnText(find.textRange.ofSubstring('/skill:custom'));
        await tester.tapOnText(find.textRange.ofSubstring('lib/main.dart'));

        expect(opened, [
          (
            path: '/home/me/.agents/skills/review/SKILL.md',
            line: null,
            endLine: null,
          ),
          (
            path: '/work/.agents/skills/deploy/SKILL.md',
            line: null,
            endLine: null,
          ),
          (path: 'lib/main.dart', line: null, endLine: null),
        ]);
      },
    );

    testWidgets('FilePathText and ReasoningBlock link skills and files', (
      tester,
    ) async {
      final opened = <FileReference>[];
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              FilePathText('Applied /review to src/app.dart'),
              ReasoningBlock(content: 'Checking /skill:deploy next.'),
            ],
          ),
          opened: opened,
        ),
      );

      await tester.tapOnText(find.textRange.ofSubstring('/review'));
      await tester.tapOnText(find.textRange.ofSubstring('src/app.dart'));
      await tester.tap(find.text('Thinking'));
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('/skill:deploy'));

      expect(opened, [
        (
          path: '/home/me/.agents/skills/review/SKILL.md',
          line: null,
          endLine: null,
        ),
        (path: 'src/app.dart', line: null, endLine: null),
        (path: '/work/.agents/skills/deploy/SKILL.md', line: 10, endLine: 15),
      ]);
    });
  });
}
