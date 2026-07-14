import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/widgets/resizable/resizable_box.dart';
import 'package:aptis_app/features/speaking/domain/entities/speaking_question.dart';
import 'package:aptis_app/features/speaking/domain/repositories/speaking_repository.dart';
import 'package:aptis_app/features/speaking/presentation/widgets/speaking_test_card.dart';
import 'package:aptis_app/features/speaking/presentation/widgets/speaking_microphone_button.dart';

class SpeakingPage extends StatefulWidget {
  /// When [attemptId] is null the page runs in preview/mock mode and skips
  /// all API calls. Pass a real [SpeakingRepository] alongside a real
  /// [attemptId] to enable full upload + submit flow.
  const SpeakingPage({
    super.key,
    this.attemptId,
    this.repository,
  }) : assert(
          (attemptId == null) == (repository == null),
          'Provide both attemptId and repository, or neither (mock mode).',
        );

  final int? attemptId;
  final SpeakingRepository? repository;

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  int _currentQuestionIndex = 0;
  SpeakingMicState _micState = SpeakingMicState.idle;

  // Timer states
  Timer? _countdownTimer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  String _timerLabel = AppStrings.speakingTimerRecording;
  bool _isPrepPhase = false;

  // Track if recording was already completed per question ID to enforce "speak only once"
  final Map<int, SpeakingMicState> _questionStates = {};

  // Audio recorder
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;
  final List<int> _audioChunks = [];
  Uint8List? _lastAudioBytes;

  // Submitting flag to show loading indicator while uploading
  bool _isSubmitting = false;

  static const List<SpeakingQuestion> _sampleQuestions = [
    // Part 1 — no image, 30 s recording
    SpeakingQuestion(
      partLabel: AppStrings.speakingPartOneLabel,
      prompt: AppStrings.speakingPartOneIntro,
      showsImage: false,
    ),
    // Part 2 — single image, 45 s recording
    SpeakingQuestion(
      partLabel: AppStrings.speakingPartTwoLabel,
      prompt: AppStrings.speakingPartTwoPrompt,
      showsImage: true,
      imageUrls: ['nature_placeholder'],
    ),
    // Part 3 — two images, 45 s recording
    SpeakingQuestion(
      partLabel: 'Part 3: Describe, Compare & Explain',
      prompt: 'Compare these two pictures showing different hobbies. What are the advantages of each hobby?',
      showsImage: true,
      imageUrls: ['hobby_a', 'hobby_b'],
    ),
    // Part 4 — sub-prompts, 60 s prep + 120 s recording
    SpeakingQuestion(
      partLabel: 'Part 4: Discuss Abstract Topic',
      prompt: 'Tell me about a time you had to make a difficult decision in your life.',
      showsImage: false,
      subPrompts: [
        'What was the decision you had to make?',
        'How did you feel about making that decision?',
        'What did you learn from the outcome?',
      ],
    ),
  ];

  bool get _isMockMode => widget.attemptId == null;

  @override
  void initState() {
    super.initState();
    _loadQuestion(_currentQuestionIndex);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _audioSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  // Set up timer limits and states for the selected question
  void _loadQuestion(int index) {
    _countdownTimer?.cancel();

    // Restore or initialize mic state for this question
    _micState = _questionStates[index] ?? SpeakingMicState.idle;

    // Check if Part 4 (which requires prep time)
    final bool hasPrep = index == 3; // Part 4

    if (_micState == SpeakingMicState.completed) {
      _timeRemaining = 0;
      _totalTime = 0;
      _timerLabel = AppStrings.speakingTimerCompleted;
      _isPrepPhase = false;
    } else if (hasPrep) {
      _isPrepPhase = true;
      _timeRemaining = 60; // 1-minute prep time
      _totalTime = 60;
      _timerLabel = AppStrings.speakingTimerPrep;
      _startPrepTimer();
    } else {
      _isPrepPhase = false;
      _timeRemaining = index == 0 ? 30 : 45; // Part 1: 30s, Part 2 & 3: 45s
      _totalTime = _timeRemaining;
      _timerLabel = AppStrings.speakingTimerRecordingReady;
    }

    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _startPrepTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 1) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        // Prep time expired -> auto start recording
        _countdownTimer?.cancel();
        _startRecording();
      }
    });
  }

  void _startRecording() {
    int recordLimit = 45;
    if (_currentQuestionIndex == 0) recordLimit = 30;
    if (_currentQuestionIndex == 3) recordLimit = 120; // Part 4: 2 minutes

    setState(() {
      _isPrepPhase = false;
      _micState = SpeakingMicState.recording;
      _timeRemaining = recordLimit;
      _totalTime = recordLimit;
      _timerLabel = AppStrings.speakingTimerRecordingSpeak;
    });

    // Start real microphone recording — stream mode works on Web & mobile
    _recorder.hasPermission().then((hasPermission) async {
      if (!hasPermission) return;
      _audioChunks.clear();
      _lastAudioBytes = null;
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.opus,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _audioSubscription = stream.listen(
        (chunk) => _audioChunks.addAll(chunk),
        onError: (_) {},
        cancelOnError: true,
      );
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 1) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _countdownTimer?.cancel();

    // Stop real recorder and collect bytes before changing state
    _recorder.isRecording().then((isRec) async {
      if (isRec) {
        await _audioSubscription?.cancel();
        _audioSubscription = null;
        await _recorder.stop();
        // Finalize accumulated audio bytes
        if (_audioChunks.isNotEmpty) {
          _lastAudioBytes = Uint8List.fromList(_audioChunks);
        }
      }
      if (mounted) {
        setState(() {
          _micState = SpeakingMicState.completed;
          _timeRemaining = 0;
          _timerLabel = AppStrings.speakingTimerCompleted;
          _questionStates[_currentQuestionIndex] = SpeakingMicState.completed;
        });
        if (!_isMockMode) {
          unawaited(_uploadAndSubmit());
        }
      }
    });
  }

  Future<void> _uploadAndSubmit() async {
    final question = _sampleQuestions[_currentQuestionIndex];
    final int? questionId = question.id;

    // Skip if question has no BE id (e.g. still using full mock data)
    if (questionId == null) return;

    final bytes = _lastAudioBytes ?? Uint8List(0);

    setState(() => _isSubmitting = true);
    try {
      final audioUrl = await widget.repository!.uploadRecording(
        attemptId: widget.attemptId!,
        questionId: questionId,
        audioBytes: bytes,
        mimeType: 'audio/webm',
      );
      await widget.repository!.submitAnswer(
        attemptId: widget.attemptId!,
        questionId: questionId,
        audioUrl: audioUrl,
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleMicrophonePressed() {
    if (_micState == SpeakingMicState.idle) {
      // If in prep phase, cancel it and start recording immediately
      if (_isPrepPhase) {
        _countdownTimer?.cancel();
      }
      _startRecording();
    } else if (_micState == SpeakingMicState.recording) {
      _stopRecording();
    }
  }

  void _selectQuestion(int index) {
    _loadQuestion(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            ResizableBox(
              defaultWidth: AppDimensions.speakingCardDefaultWidth,
              defaultHeight: AppDimensions.speakingCardDefaultHeight,
              minWidth: AppDimensions.speakingCardMinWidth,
              minHeight: AppDimensions.speakingCardMinHeight,
              maxWidth: AppDimensions.speakingCardMaxWidth,
              maxHeight: AppDimensions.speakingCardMaxHeight,
              viewportPadding: AppDimensions.speakingPagePadding,
              padding: const EdgeInsets.all(AppDimensions.speakingPagePadding),
              child: SpeakingTestCard(
                question: _sampleQuestions[_currentQuestionIndex],
                currentIndex: _currentQuestionIndex,
                totalCount: _sampleQuestions.length,
                onQuestionSelected: _selectQuestion,
                onMicrophonePressed: _handleMicrophonePressed,
                micState: _micState,
                timeRemaining: _timeRemaining,
                totalTime: _totalTime,
                timerLabel: _timerLabel,
              ),
            ),
            if (_isSubmitting)
              const Positioned(
                bottom: 12,
                right: 12,
                child: _UploadingBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadingBadge extends StatelessWidget {
  const _UploadingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.topBarBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            'Uploading…',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
