import 'package:flutter_test/flutter_test.dart';
import 'package:shireitou/src/composer/config_fields.dart';
import 'package:shireitou/src/composer/new_session_draft.dart';

void main() {
  const target = (host: 'h', directory: 'file:///src/app');
  const other = (host: 'h', directory: null);
  NewSessionDraft draft(String prompt) =>
      (host: 'h', provider: 'pi', directory: '/src/app', prompt: prompt);

  test('drafts with text are kept per target; empty ones are dropped', () {
    var drafts = withDraft(const {}, target, draft('Fix it'));
    drafts = withDraft(drafts, other, draft('Other'));
    expect(drafts[target]?.prompt, 'Fix it');
    expect(drafts[other]?.prompt, 'Other');
    drafts = withDraft(drafts, target, draft('  '));
    expect(drafts.containsKey(target), isFalse);
    expect(drafts[other]?.prompt, 'Other');
  });

  test('the initial folder is the target, else the host default', () {
    expect(initialDirectoryText('file:///src/app/', '/home'), '/src/app');
    expect(initialDirectoryText(null, 'file:///home/me'), '/home/me');
    expect(initialDirectoryText(null, null), '');
  });

  test('only editable choices fit a compact picker', () {
    const choice = ConfigField(
      id: 'mode',
      title: 'Mode',
      kind: ConfigFieldKind.choice,
    );
    expect(isPickerField(choice), isTrue);
    expect(
      isPickerField(
        const ConfigField(
          id: 'mode',
          title: 'Mode',
          kind: ConfigFieldKind.choice,
          readOnly: true,
        ),
      ),
      isFalse,
    );
    expect(
      isPickerField(
        const ConfigField(
          id: 'branch',
          title: 'Branch',
          kind: ConfigFieldKind.suggested,
        ),
      ),
      isFalse,
    );
  });
}
