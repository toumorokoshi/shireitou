import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

void main() {
  group('completionToken', () {
    test('finds a trigger at the start of the text or after whitespace', () {
      expect(completionToken('/rev', 4, ['/']), (
        start: 0,
        end: 4,
        trigger: '/',
        query: 'rev',
      ));
      expect(completionToken('please @ma', 10, ['/', '@']), (
        start: 7,
        end: 10,
        trigger: '@',
        query: 'ma',
      ));
      expect(completionToken('a\n/', 3, ['/'])?.query, '');
    });

    test('ignores triggers inside a word or other characters', () {
      expect(completionToken('src/main', 8, ['/']), isNull);
      expect(completionToken('hello', 5, ['/']), isNull);
      expect(completionToken('/x ', 3, ['/']), isNull);
      expect(completionToken('', 0, ['/']), isNull);
      expect(completionToken('/x', 5, ['/']), isNull);
    });

    test('ends at the cursor', () {
      expect(completionToken('/review now', 4, ['/'])?.query, 'rev');
    });
  });

  group('slashCommands', () {
    test('lists invocable skills and prompts of containers', () {
      const customizations = <Customization>[
        McpServerCustomization(
          id: 'mcp',
          uri: 'file:///.mcp.json',
          name: 'MCP',
          state: McpServerReadyState(),
        ),
        DirectoryCustomization(
          id: 'skills',
          uri: 'file:///skills',
          name: 'Skills',
          enabled: true,
          contents: ChildCustomizationType.skill,
          writable: false,
          children: [
            SkillCustomization(
              id: 'a',
              uri: 'file:///skills/a',
              name: 'review',
              description: 'Reviews',
            ),
            SkillCustomization(
              id: 'b',
              uri: 'file:///skills/b',
              name: 'deploy',
              disableUserInvocation: true,
            ),
            SkillCustomization(
              id: 'c',
              uri: 'file:///skills/c',
              name: 'off',
              enabled: false,
            ),
            SkillCustomization(
              id: 'd',
              uri: 'file:///skills/d',
              name: 'review',
            ),
          ],
        ),
        PluginCustomization(
          id: 'plugin',
          uri: 'https://example.com/plugin',
          name: 'Plugin',
          children: [
            PromptCustomization(
              id: 'p',
              uri: 'file:///plugin/explain.md',
              name: 'explain',
            ),
            RuleCustomization(
              id: 'r',
              uri: 'file:///plugin/rule.md',
              name: 'rule',
            ),
          ],
        ),
      ];
      expect(slashCommands(customizations), [
        (name: 'review', description: 'Reviews', skillUri: 'file:///skills/a'),
        (name: 'explain', description: null, skillUri: null),
      ]);
      expect(slashCommands(null), isEmpty);
    });
  });
}
