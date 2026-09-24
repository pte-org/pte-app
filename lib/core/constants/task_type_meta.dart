/// Interaction family used by the design-system task templates.
enum TaskTemplateFamily {
  recordResponse,
  freeText,
  fillBlanks,
  multiSelect,
  ordering,
  singleSelect,
  tokenToggle,
}

/// Canonical task identifiers shared by the app runtime registry and its
/// legacy read adapter. The three `FILL_BLANKS_*` values are retained only as
/// input aliases for snapshots produced before the V40 naming migration.
class TaskTypeCodes {
  const TaskTypeCodes._();

  static const personalIntroduction = 'PERSONAL_INTRODUCTION';
  static const readAloud = 'READ_ALOUD';
  static const repeatSentence = 'REPEAT_SENTENCE';
  static const describeImage = 'DESCRIBE_IMAGE';
  static const reTellLecture = 'RE_TELL_LECTURE';
  static const answerShortQuestion = 'ANSWER_SHORT_QUESTION';
  static const respondToASituation = 'RESPOND_TO_A_SITUATION';
  static const summarizeGroupDiscussion = 'SUMMARIZE_GROUP_DISCUSSION';
  static const summarizeWrittenText = 'SUMMARIZE_WRITTEN_TEXT';
  static const writeEssay = 'WRITE_ESSAY';
  static const mcReadingSingle = 'MC_READING_SINGLE';
  static const mcReadingMultiple = 'MC_READING_MULTIPLE';
  static const reOrderParagraphs = 'RE_ORDER_PARAGRAPHS';
  static const fillInTheBlanksDragAndDrop = 'FILL_IN_THE_BLANKS_DRAG_AND_DROP';
  static const fillInTheBlanksDropdown = 'FILL_IN_THE_BLANKS_DROPDOWN';
  static const summarizeSpokenText = 'SUMMARIZE_SPOKEN_TEXT';
  static const mcListeningSingle = 'MC_LISTENING_SINGLE';
  static const mcListeningMultiple = 'MC_LISTENING_MULTIPLE';
  static const fillInTheBlanksTypeIn = 'FILL_IN_THE_BLANKS_TYPE_IN';
  static const highlightCorrectSummary = 'HIGHLIGHT_CORRECT_SUMMARY';
  static const selectMissingWord = 'SELECT_MISSING_WORD';
  static const highlightIncorrectWords = 'HIGHLIGHT_INCORRECT_WORDS';
  static const writeFromDictation = 'WRITE_FROM_DICTATION';

  static const legacyFillBlanksReading = 'FILL_BLANKS_READING';
  static const legacyFillBlanksReadingWriting = 'FILL_BLANKS_READING_WRITING';
  static const legacyFillBlanksListening = 'FILL_BLANKS_LISTENING';

  static const Map<String, String> legacyAliases = {
    legacyFillBlanksReading: fillInTheBlanksDragAndDrop,
    legacyFillBlanksReadingWriting: fillInTheBlanksDropdown,
    legacyFillBlanksListening: fillInTheBlanksTypeIn,
  };

  static String? canonicalize(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    return legacyAliases[normalized] ?? normalized;
  }
}

/// Additive runtime metadata sent by the API for a frozen snapshot item.
/// Nullable fields are intentional: malformed or partially populated server
/// metadata must resolve to an unsupported state rather than being guessed.
class TaskRuntimeProfile {
  const TaskRuntimeProfile({
    this.taskTypeCode,
    this.taskTypeKey,
    this.screenKey,
    this.contractVersion,
    this.profileKey,
    this.profileVersion,
    this.behaviorKey,
    this.rendererKey,
    this.answerSchemaVersion,
    this.scoringProfileKey,
    this.scoringProfileVersion,
    this.scoringMode,
    this.minSupportedAppVersion,
    this.authoringContractKey,
    this.authoringContractVersion,
    this.requiredClientCapabilities = const <String>[],
    this.status,
  });

  final String? taskTypeCode;
  final String? taskTypeKey;
  final String? screenKey;
  final int? contractVersion;
  final String? profileKey;
  final int? profileVersion;
  final String? behaviorKey;
  final String? rendererKey;
  final int? answerSchemaVersion;
  final String? scoringProfileKey;
  final int? scoringProfileVersion;
  final String? scoringMode;
  final String? minSupportedAppVersion;
  final String? authoringContractKey;
  final int? authoringContractVersion;
  final List<String> requiredClientCapabilities;
  final String? status;

  bool get isComplete =>
      taskTypeCode != null &&
      profileKey != null &&
      profileVersion != null &&
      behaviorKey != null &&
      rendererKey != null &&
      answerSchemaVersion != null &&
      scoringProfileKey != null &&
      scoringProfileVersion != null &&
      status != null &&
      effectiveScreenKey != null &&
      effectiveContractVersion != null &&
      effectiveScoringMode != null;

  /// New snapshots provide these fields explicitly. Older runtime payloads
  /// are still readable through the legacy profile/renderer projection.
  String? get effectiveScreenKey => screenKey ?? rendererKey;

  int? get effectiveContractVersion => contractVersion ?? profileVersion;

  String? get effectiveScoringMode =>
      scoringMode ??
      (scoringProfileKey == null
          ? null
          : scoringProfileKey == 'UNSCORED'
          ? 'NONE'
          : 'SCORED');

  factory TaskRuntimeProfile.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['requiredClientCapabilities'];
    return TaskRuntimeProfile(
      taskTypeCode: json['taskTypeCode'] as String?,
      taskTypeKey: json['taskTypeKey'] as String?,
      screenKey: json['screenKey'] as String?,
      contractVersion: _readInt(json['contractVersion']),
      profileKey: json['profileKey'] as String?,
      profileVersion: _readInt(json['profileVersion']),
      behaviorKey: json['behaviorKey'] as String?,
      rendererKey: json['rendererKey'] as String?,
      answerSchemaVersion: _readInt(json['answerSchemaVersion']),
      scoringProfileKey: json['scoringProfileKey'] as String?,
      scoringProfileVersion: _readInt(json['scoringProfileVersion']),
      scoringMode: json['scoringMode'] as String?,
      minSupportedAppVersion: json['minSupportedAppVersion'] as String?,
      authoringContractKey: json['authoringContractKey'] as String?,
      authoringContractVersion: _readInt(json['authoringContractVersion']),
      requiredClientCapabilities: rawCapabilities is List
          ? rawCapabilities.whereType<String>().toList(growable: false)
          : const <String>[],
      status: json['status'] as String?,
    );
  }

  static int? _readInt(Object? value) => value is num ? value.toInt() : null;
}

typedef TaskAnswerParser = Object? Function(Object? payload);
typedef TaskAnswerSerializer = Object? Function(Object? answer);

Object? _identityAnswer(Object? value) => value;

/// Codec seam owned by a renderer registration. Existing screens keep their
/// current payload serializers; the registry only provides a safe, typed
/// place for a future interaction to register a new schema implementation.
class TaskAnswerCodec {
  const TaskAnswerCodec({required this.parser, required this.serializer});

  final TaskAnswerParser parser;
  final TaskAnswerSerializer serializer;

  static const identity = TaskAnswerCodec(
    parser: _identityAnswer,
    serializer: _identityAnswer,
  );
}

class TaskTypeRendererRegistration {
  const TaskTypeRendererRegistration({
    required this.meta,
    required this.rendererKey,
    required this.behaviorKey,
    required this.scoringProfileKey,
    required this.requiredClientCapabilities,
    this.supportedProfileVersions = const {1},
    this.supportedContractVersions = const {1},
    this.supportedSchemaVersions = const {1},
    this.supportedScoringProfileVersions = const {1},
    this.answerCodec = TaskAnswerCodec.identity,
  });

  final TaskTypeMeta meta;
  final String rendererKey;
  final String behaviorKey;
  final String scoringProfileKey;
  final Set<int> supportedProfileVersions;
  final Set<int> supportedContractVersions;
  final Set<int> supportedSchemaVersions;
  final Set<int> supportedScoringProfileVersions;
  final List<String> requiredClientCapabilities;
  final TaskAnswerCodec answerCodec;

  String get taskTypeCode => meta.taskType;

  String get screenKey => rendererKey;
}

enum TaskTypeResolutionFailure {
  unknownTaskType,
  unknownRenderer,
  unsupportedSchema,
  runtimeTaskTypeMismatch,
  runtimeProfileMismatch,
  inactiveRuntimeProfile,
}

/// Typed result used by the dispatcher. A null registration is never treated
/// as a request to navigate to the next task.
class TaskTypeResolution {
  const TaskTypeResolution.supported(this.registration)
    : failure = null,
      identifier = '';

  const TaskTypeResolution.unsupported(this.failure, this.identifier)
    : registration = null;

  final TaskTypeRendererRegistration? registration;
  final TaskTypeResolutionFailure? failure;
  final String identifier;

  bool get isSupported => registration != null;
}

/// Presentation metadata for one exam task type.
///
/// This registry is deliberately data-only. It is safe for core widgets and
/// preview tooling to consume without importing a feature BLoC or an API DTO.
class TaskTypeMeta {
  const TaskTypeMeta({
    required this.taskType,
    required this.section,
    required this.title,
    required this.instruction,
    required this.family,
    required this.scoringMode,
    required this.designReference,
  });

  final String taskType;
  final String section;
  final String title;
  final String instruction;
  final TaskTemplateFamily family;
  final String scoringMode;
  final String designReference;

  static const List<TaskTypeMeta> all = [
    TaskTypeMeta(
      taskType: TaskTypeCodes.personalIntroduction,
      section: 'SPEAKING',
      title: 'Personal Introduction',
      instruction: 'Introduce yourself using the prompts below.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'unscored',
      designReference: '11-personal-introduction',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.readAloud,
      section: 'SPEAKING',
      title: 'Read Aloud',
      instruction: 'Read the text aloud as naturally as possible.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '01-read-aloud',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.repeatSentence,
      section: 'SPEAKING',
      title: 'Repeat Sentence',
      instruction: 'Listen to the sentence and repeat it.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '13-repeat-sentence',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.describeImage,
      section: 'SPEAKING',
      title: 'Describe Image',
      instruction: 'Describe the image in detail.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '14-describe-image',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.reTellLecture,
      section: 'SPEAKING',
      title: 'Re-tell Lecture',
      instruction: 'Re-tell the lecture in your own words.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '15-re-tell-lecture',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.answerShortQuestion,
      section: 'SPEAKING',
      title: 'Answer Short Question',
      instruction:
          'Listen to the question and answer with a word or short phrase.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: '16-answer-short-question',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.summarizeGroupDiscussion,
      section: 'SPEAKING',
      title: 'Summarize Group Discussion',
      instruction: 'Summarize the discussion in your own words.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: 'derived-audio-prompt-fallback',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.respondToASituation,
      section: 'SPEAKING',
      title: 'Respond to a Situation',
      instruction: 'Respond appropriately to the situation.',
      family: TaskTemplateFamily.recordResponse,
      scoringMode: 'speaking',
      designReference: 'derived-audio-prompt-fallback',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.summarizeWrittenText,
      section: 'WRITING',
      title: 'Summarize Written Text',
      instruction: 'Summarize the passage in one sentence.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '17-summarize-written-text',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.writeEssay,
      section: 'WRITING',
      title: 'Write Essay',
      instruction: 'Plan, write and revise an essay about the topic below.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '18-write-essay',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.summarizeSpokenText,
      section: 'LISTENING',
      title: 'Summarize Spoken Text',
      instruction: 'Write a summary of the recording.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '26-summarize-spoken-text',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.writeFromDictation,
      section: 'LISTENING',
      title: 'Write from Dictation',
      instruction: 'Type the sentence you hear.',
      family: TaskTemplateFamily.freeText,
      scoringMode: 'writing',
      designReference: '33-write-from-dictation-listening',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.fillInTheBlanksDropdown,
      section: 'READING',
      title: 'Reading and Writing: Fill in the Blanks',
      instruction: 'Select the best word for each blank.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'reading-writing',
      designReference: '20-reading-writing-fill-in-the-blanks',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.mcReadingMultiple,
      section: 'READING',
      title: 'Multiple-Choice, Multiple Answer',
      instruction: 'Select all the correct responses.',
      family: TaskTemplateFamily.multiSelect,
      scoringMode: 'reading',
      designReference: '21-multiple-choice-multiple-answer',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.reOrderParagraphs,
      section: 'READING',
      title: 'Re-order Paragraphs',
      instruction: 'Re-order the paragraphs into the correct sequence.',
      family: TaskTemplateFamily.ordering,
      scoringMode: 'reading',
      designReference: '22-re-order-paragraphs',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.fillInTheBlanksDragAndDrop,
      section: 'READING',
      title: 'Reading: Fill in the Blanks',
      instruction: 'Drag the words into the correct blanks.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'reading',
      designReference: '23-reading-fill-in-the-blanks',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.mcReadingSingle,
      section: 'READING',
      title: 'Reading: Multiple Choice, Single Answer',
      instruction: 'Select the correct response.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'reading',
      designReference: '24-multiple-choice-single-answer',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.mcListeningMultiple,
      section: 'LISTENING',
      title: 'Multiple-Choice, Multiple Answer',
      instruction: 'Select all the correct responses.',
      family: TaskTemplateFamily.multiSelect,
      scoringMode: 'listening',
      designReference: '27-multiple-choice-multiple-answer-listening',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.fillInTheBlanksTypeIn,
      section: 'LISTENING',
      title: 'Listening: Fill in the Blanks',
      instruction: 'Type the missing words as you listen.',
      family: TaskTemplateFamily.fillBlanks,
      scoringMode: 'listening',
      designReference: '28-fill-in-the-blanks-listening',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.highlightCorrectSummary,
      section: 'LISTENING',
      title: 'Highlight Correct Summary',
      instruction: 'Select the summary that best represents the recording.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '29-highlight-correct-summary',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.mcListeningSingle,
      section: 'LISTENING',
      title: 'Multiple-Choice, Single Answer',
      instruction: 'Select the correct response.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '30-multiple-choice-single-answer-listening',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.selectMissingWord,
      section: 'LISTENING',
      title: 'Select Missing Word',
      instruction: 'Select the word that completes the recording.',
      family: TaskTemplateFamily.singleSelect,
      scoringMode: 'listening',
      designReference: '31-select-missing-word-listening',
    ),
    TaskTypeMeta(
      taskType: TaskTypeCodes.highlightIncorrectWords,
      section: 'LISTENING',
      title: 'Highlight Incorrect Words',
      instruction: 'Select the words that differ from the recording.',
      family: TaskTemplateFamily.tokenToggle,
      scoringMode: 'listening',
      designReference: '32-highlight-incorrect-words-listening',
    ),
  ];

  static final Map<String, TaskTypeMeta> _byType = {
    for (final meta in all) meta.taskType: meta,
  };

  static TaskTypeMeta? forTaskType(String taskType) =>
      _byType[TaskTypeCodes.canonicalize(taskType)];
}

class _RendererDefinition {
  const _RendererDefinition(
    this.behaviorKey,
    this.scoringProfileKey,
    this.requiredClientCapabilities,
  );

  final String behaviorKey;
  final String scoringProfileKey;
  final List<String> requiredClientCapabilities;
}

/// Immutable allowlist of renderers shipped by this app release. It mirrors
/// semantic server keys only; it never stores Dart class names or executable
/// server configuration.
class TaskTypeRendererRegistry {
  const TaskTypeRendererRegistry._();

  static final List<TaskTypeRendererRegistration> all = List.unmodifiable(
    TaskTypeMeta.all.map(_registrationFor),
  );

  static final Map<String, TaskTypeRendererRegistration> _byTaskType = {
    for (final registration in all) registration.taskTypeCode: registration,
  };

  static final Map<String, TaskTypeRendererRegistration> _byRendererKey = {
    for (final registration in all) registration.rendererKey: registration,
  };

  /// Returns the exact allowlisted capability identifiers this app release
  /// can execute. The server may normalize them to versioned fingerprints.
  static List<String> get capabilityManifest => List.unmodifiable(
    <String>{
      for (final registration in all)
        ...registration.requiredClientCapabilities,
    }.toList()..sort(),
  );

  static TaskTypeRendererRegistration? forTaskType(String? rawTaskType) {
    final canonical = TaskTypeCodes.canonicalize(rawTaskType);
    return canonical == null ? null : _byTaskType[canonical];
  }

  static TaskTypeResolution resolve({
    required String? taskTypeCode,
    required String? legacyTaskType,
    required TaskRuntimeProfile? runtime,
  }) {
    final canonicalTaskType = TaskTypeCodes.canonicalize(
      taskTypeCode ?? legacyTaskType,
    );

    if (runtime != null) {
      final rendererKey = runtime.effectiveScreenKey;
      final registration = rendererKey == null
          ? null
          : _byRendererKey[rendererKey];
      if (registration == null) {
        return TaskTypeResolution.unsupported(
          TaskTypeResolutionFailure.unknownRenderer,
          rendererKey ?? canonicalTaskType ?? 'UNKNOWN_RENDERER',
        );
      }
      if (!runtime.isComplete) {
        return TaskTypeResolution.unsupported(
          TaskTypeResolutionFailure.runtimeProfileMismatch,
          registration.rendererKey,
        );
      }
      if (runtime.status != 'ACTIVE') {
        return TaskTypeResolution.unsupported(
          TaskTypeResolutionFailure.inactiveRuntimeProfile,
          registration.rendererKey,
        );
      }
      if (!registration.supportedSchemaVersions.contains(
        runtime.answerSchemaVersion,
      )) {
        return TaskTypeResolution.unsupported(
          TaskTypeResolutionFailure.unsupportedSchema,
          '$rendererKey/schema-${runtime.answerSchemaVersion ?? 'unknown'}',
        );
      }
      final runtimeTaskType = TaskTypeCodes.canonicalize(
        runtime.taskTypeKey ?? runtime.taskTypeCode,
      );
      if (canonicalTaskType == null ||
          runtimeTaskType != canonicalTaskType ||
          !registration.supportedProfileVersions.contains(
            runtime.profileVersion,
          ) ||
          !registration.supportedContractVersions.contains(
            runtime.effectiveContractVersion,
          ) ||
          runtime.behaviorKey != registration.behaviorKey ||
          runtime.scoringProfileKey != registration.scoringProfileKey ||
          !registration.supportedScoringProfileVersions.contains(
            runtime.scoringProfileVersion,
          )) {
        return TaskTypeResolution.unsupported(
          TaskTypeResolutionFailure.runtimeProfileMismatch,
          runtimeTaskType ?? canonicalTaskType ?? registration.rendererKey,
        );
      }
      return TaskTypeResolution.supported(registration);
    }

    final registration = forTaskType(canonicalTaskType);
    return registration == null
        ? TaskTypeResolution.unsupported(
            TaskTypeResolutionFailure.unknownTaskType,
            canonicalTaskType ?? 'UNKNOWN_TASK_TYPE',
          )
        : TaskTypeResolution.supported(registration);
  }

  static TaskTypeRendererRegistration _registrationFor(TaskTypeMeta meta) {
    final definition = _definitions[meta.taskType];
    if (definition == null) {
      throw StateError('Missing renderer registration for ${meta.taskType}');
    }
    return TaskTypeRendererRegistration(
      meta: meta,
      rendererKey: '${meta.taskType}_V1',
      behaviorKey: definition.behaviorKey,
      scoringProfileKey: definition.scoringProfileKey,
      requiredClientCapabilities: definition.requiredClientCapabilities,
    );
  }

  static const Map<String, _RendererDefinition> _definitions = {
    TaskTypeCodes.personalIntroduction: _RendererDefinition(
      'PERSONAL_INTRODUCTION',
      'UNSCORED',
      ['AUDIO_RECORDING'],
    ),
    TaskTypeCodes.readAloud: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_RECORDING'],
    ),
    TaskTypeCodes.repeatSentence: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_PLAYBACK', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.describeImage: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['IMAGE_DISPLAY', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.reTellLecture: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_PLAYBACK', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.answerShortQuestion: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_PLAYBACK', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.respondToASituation: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_PLAYBACK', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.summarizeGroupDiscussion: _RendererDefinition(
      'RECORD_RESPONSE',
      'AI_SPEECH',
      ['AUDIO_PLAYBACK', 'AUDIO_RECORDING'],
    ),
    TaskTypeCodes.summarizeWrittenText: _RendererDefinition(
      'TEXT_RESPONSE',
      'AI_TEXT',
      ['TEXT_INPUT'],
    ),
    TaskTypeCodes.writeEssay: _RendererDefinition('TEXT_RESPONSE', 'AI_TEXT', [
      'TEXT_INPUT',
    ]),
    TaskTypeCodes.mcReadingSingle: _RendererDefinition(
      'SELECT_OPTION',
      'OBJECTIVE',
      ['OPTION_SELECTION'],
    ),
    TaskTypeCodes.mcReadingMultiple: _RendererDefinition(
      'SELECT_OPTIONS',
      'OBJECTIVE',
      ['OPTION_SELECTION'],
    ),
    TaskTypeCodes.reOrderParagraphs: _RendererDefinition(
      'ORDER_OPTIONS',
      'OBJECTIVE',
      ['DRAG_AND_DROP'],
    ),
    TaskTypeCodes.fillInTheBlanksDragAndDrop: _RendererDefinition(
      'FILL_BLANKS',
      'OBJECTIVE',
      ['DRAG_AND_DROP'],
    ),
    TaskTypeCodes.fillInTheBlanksDropdown: _RendererDefinition(
      'FILL_BLANKS',
      'OBJECTIVE',
      ['DROPDOWN_SELECTION'],
    ),
    TaskTypeCodes.summarizeSpokenText: _RendererDefinition(
      'TEXT_RESPONSE',
      'AI_TEXT',
      ['AUDIO_PLAYBACK', 'TEXT_INPUT'],
    ),
    TaskTypeCodes.mcListeningSingle: _RendererDefinition(
      'SELECT_OPTION',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'OPTION_SELECTION'],
    ),
    TaskTypeCodes.mcListeningMultiple: _RendererDefinition(
      'SELECT_OPTIONS',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'OPTION_SELECTION'],
    ),
    TaskTypeCodes.fillInTheBlanksTypeIn: _RendererDefinition(
      'TEXT_RESPONSE',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'TEXT_INPUT'],
    ),
    TaskTypeCodes.highlightCorrectSummary: _RendererDefinition(
      'HIGHLIGHT_OPTIONS',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'HIGHLIGHT_SELECTION'],
    ),
    TaskTypeCodes.selectMissingWord: _RendererDefinition(
      'SELECT_OPTION',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'OPTION_SELECTION'],
    ),
    TaskTypeCodes.highlightIncorrectWords: _RendererDefinition(
      'HIGHLIGHT_TEXT',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'HIGHLIGHT_SELECTION'],
    ),
    TaskTypeCodes.writeFromDictation: _RendererDefinition(
      'TEXT_RESPONSE',
      'OBJECTIVE',
      ['AUDIO_PLAYBACK', 'TEXT_INPUT'],
    ),
  };
}
