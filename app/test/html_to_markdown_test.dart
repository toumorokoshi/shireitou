/// Tests for converting rich text HTML (Google Docs, web pages, rich text
/// editors) into Markdown.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/clipboard/html_to_markdown.dart';

void main() {
  group('htmlToMarkdown', () {
    test('returns empty string for empty or whitespace-only HTML', () {
      expect(htmlToMarkdown(''), '');
      expect(htmlToMarkdown('   \n\t  '), '');
    });

    test('preserves plain text without HTML formatting', () {
      expect(htmlToMarkdown('Hello world'), 'Hello world');
      expect(
        htmlToMarkdown('<p>Paragraph 1</p><p>Paragraph 2</p>'),
        'Paragraph 1\n\nParagraph 2',
      );
    });

    test(
      'converts basic inline formatting (bold, italic, strikethrough, code)',
      () {
        expect(htmlToMarkdown('<b>bold</b>'), '**bold**');
        expect(htmlToMarkdown('<strong>strong</strong>'), '**strong**');
        expect(htmlToMarkdown('<i>italic</i>'), '*italic*');
        expect(htmlToMarkdown('<em>emphasis</em>'), '*emphasis*');
        expect(htmlToMarkdown('<s>strikethrough</s>'), '~~strikethrough~~');
        expect(htmlToMarkdown('<del>deleted</del>'), '~~deleted~~');
        expect(htmlToMarkdown('<code>code()</code>'), '`code()`');
        expect(
          htmlToMarkdown(
            '<span style="font-family: Consolas, monospace;">mono</span>',
          ),
          '`mono`',
        );
      },
    );

    test('preserves whitespace around inline markers', () {
      expect(
        htmlToMarkdown('before <b> bold </b> after'),
        'before  **bold**  after',
      );
      expect(
        htmlToMarkdown('before <i> italic </i> after'),
        'before  *italic*  after',
      );
    });

    test('handles combined bold and italic', () {
      expect(
        htmlToMarkdown('<b><i>bold and italic</i></b>'),
        '***bold and italic***',
      );
    });

    test('ignores Google Docs docs-internal-guid wrapper bold', () {
      const html = '''
<b id="docs-internal-guid-12345" style="font-weight:normal;">
  <p>First paragraph with <b>bold</b> word.</p>
</b>''';
      expect(htmlToMarkdown(html), 'First paragraph with **bold** word.');
    });

    test('converts Google Docs standard bullet list with <p> and <span>', () {
      const html = '''
<ul style="margin-top:0;margin-bottom:0;padding-inline-start:48px;">
  <li dir="ltr"><p dir="ltr"><span>First bullet</span></p></li>
  <li dir="ltr"><p dir="ltr"><span>Second bullet</span></p></li>
  <li dir="ltr"><p dir="ltr"><span>Third bullet</span></p></li>
</ul>''';
      expect(
        htmlToMarkdown(html),
        '- First bullet\n- Second bullet\n- Third bullet',
      );
    });

    test('converts nested bullet lists (DOM nesting)', () {
      const html = '''
<ul>
  <li>Item 1
    <ul>
      <li>Sub-item 1.1</li>
      <li>Sub-item 1.2</li>
    </ul>
  </li>
  <li>Item 2</li>
</ul>''';
      expect(
        htmlToMarkdown(html),
        '- Item 1\n  - Sub-item 1.1\n  - Sub-item 1.2\n- Item 2',
      );
    });

    test('converts Google Docs flat list with aria-level and lst-kix classes', () {
      const html = '''
<ul class="lst-kix_list1-0">
  <li class="lst-kix_list1-0" aria-level="1"><p><span>Top level</span></p></li>
  <li class="lst-kix_list1-1" aria-level="2"><p><span>Nested level 1</span></p></li>
  <li class="lst-kix_list1-2" aria-level="3"><p><span>Nested level 2</span></p></li>
  <li class="lst-kix_list1-0" aria-level="1"><p><span>Back to top</span></p></li>
</ul>''';
      expect(
        htmlToMarkdown(html),
        '- Top level\n  - Nested level 1\n    - Nested level 2\n- Back to top',
      );
    });

    test('strips redundant bullet characters from list item text', () {
      const html = '''
<ul>
  <li>• Bullet with unicode dot</li>
  <li>◦ Sub-bullet with white dot</li>
  <li>- Bullet with dash</li>
</ul>''';
      expect(
        htmlToMarkdown(html),
        '- Bullet with unicode dot\n- Sub-bullet with white dot\n- Bullet with dash',
      );
    });

    test('converts ordered (numbered) lists', () {
      const html = '''
<ol>
  <li>First step</li>
  <li>Second step
    <ol>
      <li>Sub-step A</li>
      <li>Sub-step B</li>
    </ol>
  </li>
  <li>Third step</li>
</ol>''';
      expect(
        htmlToMarkdown(html),
        '1. First step\n2. Second step\n  1. Sub-step A\n  2. Sub-step B\n3. Third step',
      );
    });

    test('converts checklist / task items', () {
      const html = '''
<ul>
  <li><input type="checkbox" checked> Done task</li>
  <li><input type="checkbox"> Open task</li>
</ul>''';
      expect(htmlToMarkdown(html), '- [x] Done task\n- [ ] Open task');
    });

    test('converts headings', () {
      const html = '''
<h1>Title</h1>
<h2>Subtitle</h2>
<h3>Section</h3>
<p>Content</p>''';
      expect(
        htmlToMarkdown(html),
        '# Title\n\n## Subtitle\n\n### Section\n\nContent',
      );
    });

    test('converts links and unwraps Google redirection URLs', () {
      const html = '''
<p>
  <a href="https://example.com">Normal link</a>
  <a href="https://www.google.com/url?q=https%3A%2F%2Fgithub.com%2Fproject&sa=D&sntz=1">Google Doc link</a>
</p>''';
      expect(
        htmlToMarkdown(html),
        '[Normal link](https://example.com) [Google Doc link](https://github.com/project)',
      );
    });

    test('converts code blocks in <pre>', () {
      const html = '''
<pre><code class="language-dart">void main() {
  print("hello");
}</code></pre>''';
      expect(
        htmlToMarkdown(html),
        '```dart\nvoid main() {\n  print("hello");\n}\n```',
      );
    });

    test('converts blockquotes', () {
      const html = '''
<blockquote>
  <p>Quote line 1</p>
  <p>Quote line 2</p>
</blockquote>''';
      expect(htmlToMarkdown(html), '> Quote line 1\n> Quote line 2');
    });

    test('converts tables', () {
      const html = '''
<table>
  <tr><th>Header 1</th><th>Header 2</th></tr>
  <tr><td>Val 1</td><td>Val 2</td></tr>
</table>''';
      expect(
        htmlToMarkdown(html),
        '| Header 1 | Header 2 |\n| --- | --- |\n| Val 1 | Val 2 |',
      );
    });

    test('handles <br> and <hr>', () {
      const html = '<p>Line 1<br>Line 2</p><hr><p>Line 3</p>';
      expect(htmlToMarkdown(html), 'Line 1\nLine 2\n\n---\n\nLine 3');
    });
  });
}
