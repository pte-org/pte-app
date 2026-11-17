import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';

void main() {
  group('TaskTypeRendererRegistry and TaskTypeCodes', () {
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

    test('normalizes legacy aliases and handles edge cases', () {
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
      expect(TaskTypeCodes.canonicalize(null), isNull);
      expect(TaskTypeCodes.canonicalize('   '), isNull);
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

    test('legacy response without runtime still resolves through one alias map', () {
      final resolution = TaskTypeRendererRegistry.resolve(
        taskTypeCode: null,
        legacyTaskType: TaskTypeCodes.legacyFillBlanksListening,
        runtime: null,
      );

      expect(
        resolution.registration?.taskTypeCode,
        TaskTypeCodes.fillInTheBlanksTypeIn,
      );
    });

    test('resolve handles unknown renderer, incomplete profile, and inactive status', () {
      // Unknown renderer
      final unknownRenderer = TaskTypeRendererRegistry.resolve(
        taskTypeCode: TaskTypeCodes.mcReadingSingle,
        legacyTaskType: TaskTypeCodes.mcReadingSingle,
        runtime: const TaskRuntimeProfile(rendererKey: 'NON_EXISTENT_RENDERER_V99'),
      );
      expect(unknownRenderer.isSupported, isFalse);
      expect(unknownRenderer.failure, TaskTypeResolutionFailure.unknownRenderer);

      // Incomplete profile
      final incomplete = TaskTypeRendererRegistry.resolve(
        taskTypeCode: TaskTypeCodes.mcReadingSingle,
        legacyTaskType: TaskTypeCodes.mcReadingSingle,
        runtime: const TaskRuntimeProfile(
          rendererKey: 'MC_READING_SINGLE_V1',
          taskTypeCode: TaskTypeCodes.mcReadingSingle,
        ),
      );
      expect(incomplete.isSupported, isFalse);
      expect(incomplete.failure, TaskTypeResolutionFailure.runtimeProfileMismatch);

      // Inactive profile
      final inactive = TaskTypeRendererRegistry.resolve(
        taskTypeCode: TaskTypeCodes.mcReadingSingle,
        legacyTaskType: TaskTypeCodes.mcReadingSingle,
        runtime: const TaskRuntimeProfile(
          taskTypeCode: TaskTypeCodes.mcReadingSingle,
          profileKey: 'PTE.MC_READING_SINGLE',
          profileVersion: 1,
          behaviorKey: 'SELECT_OPTION',
          rendererKey: 'MC_READING_SINGLE_V1',
          answerSchemaVersion: 1,
          scoringProfileKey: 'OBJECTIVE',
          scoringProfileVersion: 1,
          status: 'DISABLED',
        ),
      );
      expect(inactive.isSupported, isFalse);
      expect(inactive.failure, TaskTypeResolutionFailure.inactiveRuntimeProfile);

      // Unknown task type without runtime
      final unknownTask = TaskTypeRendererRegistry.resolve(
        taskTypeCode: 'COMPLETELY_UNKNOWN_TASK_TYPE',
        legacyTaskType: 'COMPLETELY_UNKNOWN_TASK_TYPE',
        runtime: null,
      );
      expect(unknownTask.isSupported, isFalse);
      expect(unknownTask.failure, TaskTypeResolutionFailure.unknownTaskType);
    });

    test('TaskRuntimeProfile fromJson parses all fields and effective getters', () {
      final json = <String, dynamic>{
        'taskTypeCode': 'READ_ALOUD',
        'taskTypeKey': 'READ_ALOUD',
        'screenKey': 'READ_ALOUD_V1',
        'contractVersion': 1,
        'profileKey': 'PTE.READ_ALOUD',
        'profileVersion': 1,
        'behaviorKey': 'RECORD_RESPONSE',
        'rendererKey': 'READ_ALOUD_V1',
        'answerSchemaVersion': 1,
        'scoringProfileKey': 'AI_SPEECH',
        'scoringProfileVersion': 1,
        'scoringMode': 'SCORED',
        'minSupportedAppVersion': '1.0.0',
        'authoringContractKey': 'AUTH_CONTRACT',
        'authoringContractVersion': 1,
        'requiredClientCapabilities': ['AUDIO_RECORDING'],
        'status': 'ACTIVE',
      };

      final profile = TaskRuntimeProfile.fromJson(json);
      expect(profile.isComplete, isTrue);
      expect(profile.effectiveScreenKey, equals('READ_ALOUD_V1'));
      expect(profile.effectiveContractVersion, equals(1));
      expect(profile.effectiveScoringMode, equals('SCORED'));

      // Test fallback effectiveScoringMode
      const unscoredProfile = TaskRuntimeProfile(scoringProfileKey: 'UNSCORED');
      expect(unscoredProfile.effectiveScoringMode, equals('NONE'));

      const objectiveProfile = TaskRuntimeProfile(scoringProfileKey: 'OBJECTIVE');
      expect(objectiveProfile.effectiveScoringMode, equals('SCORED'));

      const nullScoringProfile = TaskRuntimeProfile();
      expect(nullScoringProfile.effectiveScoringMode, isNull);
    });

    test('TaskAnswerCodec identity returns input unchanged', () {
      expect(TaskAnswerCodec.identity.parser('answer_string'), equals('answer_string'));
      expect(TaskAnswerCodec.identity.serializer({'count': 5}), equals({'count': 5}));
    });
  });
}
