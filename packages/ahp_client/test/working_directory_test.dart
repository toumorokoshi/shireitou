import 'package:ahp_client/ahp_client.dart';
import 'package:test/test.dart';

AgentInfo _agent({MultipleWorkingDirectoriesCapability? mwd}) => AgentInfo(
  provider: 'test',
  displayName: 'Test',
  description: 'Test agent',
  models: const [],
  capabilities: mwd == null
      ? null
      : AgentCapabilities(multipleWorkingDirectories: mwd),
);

void main() {
  test('canReplacePrimaryWorkingDirectory checks capability flags', () {
    expect(canReplacePrimaryWorkingDirectory(null), isFalse);
    expect(canReplacePrimaryWorkingDirectory(_agent()), isFalse);
    expect(
      canReplacePrimaryWorkingDirectory(
        _agent(mwd: const MultipleWorkingDirectoriesCapability()),
      ),
      isTrue,
    );
    expect(
      canReplacePrimaryWorkingDirectory(
        _agent(
          mwd: const MultipleWorkingDirectoriesCapability(
            immutablePrimary: true,
          ),
        ),
      ),
      isFalse,
    );
    expect(
      canReplacePrimaryWorkingDirectory(
        _agent(
          mwd: const MultipleWorkingDirectoriesCapability(
            immutablePrimary: true,
            primaryReplacement: true,
          ),
        ),
      ),
      isTrue,
    );
    expect(
      canReplacePrimaryWorkingDirectory(
        _agent(
          mwd: const MultipleWorkingDirectoriesCapability(
            primaryReplacement: true,
          ),
        ),
      ),
      isTrue,
    );
  });

  test('replacePrimaryWorkingDirectoryAction builds action or null', () {
    expect(replacePrimaryWorkingDirectoryAction(null, 'file:///b'), isNull);
    expect(replacePrimaryWorkingDirectoryAction(const [], 'file:///b'), isNull);
    expect(
      replacePrimaryWorkingDirectoryAction(const ['file:///a'], ''),
      isNull,
    );
    expect(
      replacePrimaryWorkingDirectoryAction(const ['file:///a'], 'file:///a'),
      isNull,
    );
    expect(
      replacePrimaryWorkingDirectoryAction(const [
        'file:///a',
        'file:///c',
      ], 'file:///b'),
      const {
        'type': 'session/workingDirectoryReplaced',
        'directory': 'file:///a',
        'replacement': 'file:///b',
      },
    );
  });
}
