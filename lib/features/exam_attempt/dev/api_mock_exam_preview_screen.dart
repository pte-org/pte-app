import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_task_body.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/audio_prompt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/listening/domain/audio_player_service.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/task_view_ui_adapter.dart';

/// Dev-only screen that consumes the real exam-delivery repository against the
/// opt-in pte-api mock profile. It renders the same design-system body as the
/// offline catalog while proving the app can parse the API envelope and move
/// through two deterministic Repeat Sentence items.
class ApiMockExamPreviewScreen extends StatefulWidget {
  const ApiMockExamPreviewScreen({
    super.key,
    required this.repository,
    required this.audioPromptRepository,
    required this.audioPlayerService,
  });

  final ExamAttemptRepository repository;
  final AudioPromptRepository audioPromptRepository;
  final AudioPlayerService audioPlayerService;

  @override
  State<ApiMockExamPreviewScreen> createState() =>
      _ApiMockExamPreviewScreenState();
}

class _ApiMockExamPreviewScreenState extends State<ApiMockExamPreviewScreen> {
  static const _sessionPublicId = '00000000-0000-0000-0000-000000000001';

  AttemptTaskResponse? _response;
  Object? _error;
  bool _loading = true;
  bool _audioLoading = false;
  bool _audioPlaying = false;
  bool _audioFinished = false;
  double _audioProgress = 0;
  late final StreamSubscription<bool> _audioFinishedSubscription;

  @override
  void initState() {
    super.initState();
    _audioFinishedSubscription = widget.audioPlayerService.hasFinishedPlaying
        .listen((_) {
          if (!mounted) return;
          setState(() {
            _audioLoading = false;
            _audioPlaying = false;
            _audioFinished = true;
            _audioProgress = 1;
          });
        });
    _startMockAttempt();
  }

  @override
  void dispose() {
    unawaited(_audioFinishedSubscription.cancel());
    unawaited(widget.audioPlayerService.close());
    super.dispose();
  }

  Future<void> _startMockAttempt() {
    return _run(() => widget.repository.startOrResumeAttempt(_sessionPublicId));
  }

  Future<void> _nextTask() {
    final attemptId = _response?.attemptPublicId;
    if (attemptId == null) return Future.value();
    return _run(() => widget.repository.fetchNextTask(attemptId));
  }

  Future<void> _playAudio() async {
    final response = _response;
    final task = response?.task;
    if (response == null ||
        task == null ||
        _audioLoading ||
        _audioPlaying ||
        _audioFinished) {
      return;
    }
    setState(() {
      _audioLoading = true;
      _audioProgress = 0;
    });
    try {
      final url = await widget.audioPromptRepository.playAudio(
        attemptPublicId: response.attemptPublicId,
        pinnedItemPublicId: task.pinnedItemPublicId,
        playRequestId: _newPlayRequestId(),
      );
      await widget.audioPlayerService.playUrl(url);
      if (!mounted) return;
      setState(() {
        _audioLoading = false;
        _audioPlaying = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _audioLoading = false;
        _audioPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play mock audio: $error')),
      );
    }
  }

  String _newPlayRequestId() =>
      '${DateTime.now().microsecondsSinceEpoch}-api-mock';

  Future<void> _run(Future<AttemptTaskResponse> Function() request) async {
    setState(() {
      _loading = true;
      _error = null;
      _audioLoading = false;
      _audioPlaying = false;
      _audioFinished = false;
      _audioProgress = 0;
    });
    try {
      final response = await request();
      if (!mounted) return;
      setState(() {
        _response = response;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _response == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final error = _error;
    if (error != null && _response == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PTE API mock exam')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('API mock unavailable: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _startMockAttempt,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final response = _response!;
    final task = response.task;
    if (response.completed || task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PTE API mock exam')),
        body: const Center(child: Text('Mock attempt completed.')),
      );
    }

    final model = TaskViewUiAdapter.adapt(task, origin: DataOrigin.api);
    final audioLabel = _audioLoading
        ? 'Loading API mock audio...'
        : _audioFinished
        ? 'Audio finished'
        : 'API mock audio';
    return ExamShell(
      header: ExamHeaderBar(
        examTitle: 'PTE API mock exam',
        candidateName: 'API mock candidate',
        candidateId: 'dev-session',
        itemLabel: 'Item ${task.orderIndex + 1} of ${task.totalTasks}',
        timeLabel: '01:00',
      ),
      body: ExamUiPreviewTaskBody(
        model: model,
        audioLabel: audioLabel,
        onAudioPressed: _audioFinished ? null : _playAudio,
        audioPlaying: _audioPlaying,
        audioProgress: _audioProgress,
      ),
      footer: ExamFooterBar(
        onSaveAndExit: () => Navigator.of(context).pop(),
        onNext: _nextTask,
        nextLoading: _loading,
        nextLabel: ExamChromeConfig.nextLabel,
      ),
    );
  }
}
