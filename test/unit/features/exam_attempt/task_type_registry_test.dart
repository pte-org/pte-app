import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';

void main() {
  test('registers every standard task with canonical renderer keys', () {
    expect(TaskTypeMeta.all, hasLength(23));
    expect(TaskTypeRendererRegistry.all, hasLength(23));
    expect(
      TaskTypeRendererRegistry.all
          .map((registration) => registration.rendererKey)
          .every((key) => key.endsWith('_V1')),
      isTrue,
    );
    expect(
      TaskTypeRendererRegistry.all
          .expand((registration) => registration.requiredClientCapabilities)
          .toSet(),
      containsAll(<String>[
        'AUDIO_PLAYBACK',
        'AUDIO_RECORDING',
        'DRAG_AND_DROP',
        'DROPDOWN_SELECTION',
        'HIGHLIGHT_SELECTION',
        'IMAGE_DISPLAY',
        'OPTION_SELECTION',
        'TEXT_INPUT',
      ]),
    );
  });

  test('normalizes only the legacy FILL aliases', () {
    expect(
      TaskTypeCodes.canonicalize(TaskTypeCodes.legacyFillBlanksReading),
      TaskTypeCodes.fillInTheBlanksDragAndDrop,
    );
    expect(
      TaskTypeCodes.canonicalize(TaskTypeCodes.legacyFillBlanksReadingWriting),
      TaskTypeCodes.fillInTheBlanksDropdown,
    );
    expect(
      TaskTypeCodes.canonicalize(TaskTypeCodes.legacyFillBlanksListening),
      TaskTypeCodes.fillInTheBlanksTypeIn,
    );
    expect(
      TaskTypeCodes.canonicalize('UNKNOWN_TASK_TYPE'),
      'UNKNOWN_TASK_TYPE',
    );
  });

  test('advertises a deterministic, deduplicated capability manifest', () {
    expect(
      TaskTypeRendererRegistry.capabilityManifest,
      orderedEquals(<String>[
        'AUDIO_PLAYBACK',
        'AUDIO_RECORDING',
        'DRAG_AND_DROP',
        'DROPDOWN_SELECTION',
        'HIGHLIGHT_SELECTION',
        'IMAGE_DISPLAY',
        'OPTION_SELECTION',
        'TEXT_INPUT',
      ]),
    );
  });

  test('prefers runtime renderer and rejects unknown schema', () {
    final supported = TaskTypeRendererRegistry.resolve(
      taskTypeCode: TaskTypeCodes.fillInTheBlanksDropdown,
      legacyTaskType: TaskTypeCodes.legacyFillBlanksReadingWriting,
      runtime: const TaskRuntimeProfile(
        taskTypeCode: TaskTypeCodes.fillInTheBlanksDropdown,
        profileKey: 'PTE.FILL_IN_THE_BLANKS_DROPDOWN',
        profileVersion: 1,
        behaviorKey: 'FILL_BLANKS',
        rendererKey: 'FILL_IN_THE_BLANKS_DROPDOWN_V1',
        answerSchemaVersion: 1,
        scoringProfileKey: 'OBJECTIVE',
        scoringProfileVersion: 1,
        status: 'ACTIVE',
      ),
    );
    expect(supported.isSupported, isTrue);

    final unsupported = TaskTypeRendererRegistry.resolve(
      taskTypeCode: TaskTypeCodes.mcReadingSingle,
      legacyTaskType: TaskTypeCodes.mcReadingSingle,
      runtime: const TaskRuntimeProfile(
        taskTypeCode: TaskTypeCodes.mcReadingSingle,
        profileKey: 'PTE.MC_READING_SINGLE',
        profileVersion: 1,
        behaviorKey: 'SELECT_OPTION',
        rendererKey: 'MC_READING_SINGLE_V1',
        answerSchemaVersion: 99,
        scoringProfileKey: 'OBJECTIVE',
        scoringProfileVersion: 1,
        status: 'ACTIVE',
      ),
    );
    expect(unsupported.isSupported, isFalse);
    expect(unsupported.failure, TaskTypeResolutionFailure.unsupportedSchema);
  });

  test(
    'legacy response without runtime still resolves through one alias map',
    () {
      final resolution = TaskTypeRendererRegistry.resolve(
        taskTypeCode: null,
        legacyTaskType: TaskTypeCodes.legacyFillBlanksListening,
        runtime: null,
      );

      expect(
        resolution.registration?.taskTypeCode,
        TaskTypeCodes.fillInTheBlanksTypeIn,
      );
    },
  );
}
