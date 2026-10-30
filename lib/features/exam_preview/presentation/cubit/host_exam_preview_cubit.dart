import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pte_app/core/constants/task_type_meta.dart';

import '../../data/preview_audio_session.dart';
import '../../data/preview_playback_state.dart';
import '../../domain/entities/preview_snapshot.dart';
import '../../domain/repositories/host_exam_preview_repository.dart';
import '../widgets/preview_answer_controller.dart';
import 'host_exam_preview_state.dart';

class HostExamPreviewCubit extends Cubit<HostExamPreviewState> {
  HostExamPreviewCubit({
    required HostExamPreviewRepository repository,
    PreviewAudioSession? mediaSession,
  }) : _repository = repository,
       _mediaSession = mediaSession,
       super(const HostExamPreviewInitial());

  final HostExamPreviewRepository _repository;
  final PreviewAudioSession? _mediaSession;
  final PreviewAnswerController _answerController = PreviewAnswerController();
  Timer? _timer;
  int _epoch = 0;
  int? _audioStartedEpoch;

  PreviewAnswerController get answerController => _answerController;
  Stream<double>? get inputLevels => _mediaSession?.inputLevels;
  Stream<Duration>? get audioPosition => _mediaSession?.position;
  PreviewAudioSession? get mediaSession => _mediaSession;
  bool _recordingControlBusy = false;

  Future<void> toggleRecordingPause() async {
    final current = state;
    final media = _mediaSession;
    if (current is! HostExamPreviewReady ||
        !current.isRecording ||
        current.isTransitioning ||
        media == null ||
        _recordingControlBusy) {
      return;
    }
    final epoch = _epoch;
    _recordingControlBusy = true;
    try {
      if (current.isRecordingPaused) {
        await media.resumeRecording();
      } else {
        await media.pauseRecording();
      }
      final latest = state;
      if (!isClosed &&
          epoch == _epoch &&
          latest is HostExamPreviewReady &&
          latest.isRecording) {
        emit(latest.copyWith(isRecordingPaused: !current.isRecordingPaused));
      }
    } catch (_) {
      final latest = state;
      if (!isClosed && epoch == _epoch && latest is HostExamPreviewReady) {
        emit(latest.copyWith(recordingUnavailable: true));
      }
    } finally {
      _recordingControlBusy = false;
    }
  }

  Future<void> loadForEntry(String rawInput) async {
    emit(const HostExamPreviewLoading());
    try {
      final input = rawInput.trim();
      if (input.isEmpty) {
        throw const FormatException(ExamPreviewStrings.sessionIdRequired);
      }
      final exams = await _repository.listExams();
      final matches = exams.where(
        (exam) =>
            exam.publicId.toLowerCase() == input.toLowerCase() ||
            exam.sessionCode?.toLowerCase() == input.toLowerCase(),
      );
      if (isClosed) return;
      if (matches.isEmpty) {
        throw const FormatException(ExamPreviewStrings.sessionNotFound);
      }
      final exam = matches.first;
      if (!exam.canPreview) {
        throw const FormatException(ExamPreviewStrings.sessionNotReady);
      }
      await load(exam.publicId);
    } catch (error) {
      if (!isClosed) emit(HostExamPreviewError(error));
    }
  }

  Future<void> load(String sessionPublicId) async {
    _cancelTimer();
    _answerController.clear();
    emit(const HostExamPreviewLoading());
    try {
      final snapshot = await _repository.fetchPreview(sessionPublicId);
      final items = [...snapshot.items]
        ..sort((left, right) => left.orderIndex.compareTo(right.orderIndex));
      final normalized = PreviewSnapshot(
        snapshotPublicId: snapshot.snapshotPublicId,
        name: snapshot.name,
        version: snapshot.version,
        items: List.unmodifiable(items),
      );
      if (normalized.items.isEmpty) {
        throw const FormatException(ExamPreviewStrings.emptyTasks);
      }
      _epoch++;
      if (!isClosed) {
        emit(
          HostExamPreviewReady(
            snapshot: normalized,
            currentIndex: 0,
            answers: _answerController.snapshot(),
            epoch: _epoch,
          ),
        );
        _startTimer(normalized.items.first, _epoch);
      }
    } catch (error) {
      if (!isClosed) emit(HostExamPreviewError(error));
    }
  }

  void setAnswer(Object? answer) {
    final current = state;
    if (current is! HostExamPreviewReady) return;
    final key = _answerKey(current.snapshot, current.currentItem);
    _answerController.setValue(key, answer);
    emit(current.copyWith(answers: _answerController.snapshot()));
  }

  Object? answerFor(PreviewItem item) {
    final current = state;
    if (current is! HostExamPreviewReady) return null;
    return _answerController.valueFor(_answerKey(current.snapshot, item));
  }

  Future<void> playAudio(String url) async {
    final mediaSession = _mediaSession;
    if (mediaSession == null ||
        url.trim().isEmpty ||
        _audioStartedEpoch == _epoch) {
      return;
    }
    _audioStartedEpoch = _epoch;
    try {
      await mediaSession.play(url);
    } catch (error) {
      if (_audioStartedEpoch == _epoch) _audioStartedEpoch = null;
      rethrow;
    }
  }

  Future<void> startRecording() async {
    final current = state;
    final mediaSession = _mediaSession;
    if (current is! HostExamPreviewReady ||
        current.isRecording ||
        mediaSession == null) {
      return;
    }
    final epoch = _epoch;
    try {
      await mediaSession.startRecording();
      final latest = state;
      if (!isClosed &&
          epoch == _epoch &&
          latest is HostExamPreviewReady &&
          (latest.remainingSeconds ?? 1) > 0) {
        emit(latest.copyWith(isRecording: true));
      }
    } catch (_) {
      final latest = state;
      if (!isClosed && epoch == _epoch && latest is HostExamPreviewReady) {
        emit(latest.copyWith(recordingUnavailable: true));
      }
    }
  }

  Future<void> stopRecording() async {
    final epoch = _epoch;
    await _mediaSession?.stopRecording();
    final current = state;
    if (!isClosed && epoch == _epoch && current is HostExamPreviewReady) {
      _cancelTimer();
      emit(
        current.copyWith(
          isRecording: false,
          isRecordingPaused: false,
          remainingSeconds: 0,
        ),
      );
    }
  }

  Future<void> next() => _move(1);

  Future<void> previous() => _move(-1);

  Future<void> finish() async {
    final current = state;
    if (current is! HostExamPreviewReady || current.isTransitioning) return;
    _epoch++;
    _cancelTimer();
    emit(current.copyWith(isTransitioning: true));
    try {
      await _mediaSession?.stopRecording();
      await _mediaSession?.stopPlayback();
      _answerController.clear();
      if (!isClosed) emit(const HostExamPreviewFinished());
    } catch (error) {
      if (!isClosed) emit(HostExamPreviewError(error));
    }
  }

  Future<void> _move(int delta) async {
    final current = state;
    if (current is! HostExamPreviewReady || current.isTransitioning) return;
    var nextIndex = current.currentIndex + delta;
    if (nextIndex < 0) nextIndex = current.snapshot.items.length - 1;
    if (nextIndex >= current.snapshot.items.length) {
      nextIndex = 0;
    }

    final transitionEpoch = ++_epoch;
    _cancelTimer();
    emit(current.copyWith(epoch: transitionEpoch, isTransitioning: true));
    try {
      await _mediaSession?.stopRecording();
      await _mediaSession?.stopPlayback();
      if (isClosed || transitionEpoch != _epoch) return;
      emit(
        current.copyWith(
          currentIndex: nextIndex,
          epoch: transitionEpoch,
          isTransitioning: false,
          isRecording: false,
          isRecordingPaused: false,
          isPreparing: false,
          recordingUnavailable: false,
          clearRemainingSeconds: true,
        ),
      );
      _startTimer(current.snapshot.items[nextIndex], transitionEpoch);
    } catch (error) {
      if (!isClosed && transitionEpoch == _epoch) {
        emit(HostExamPreviewError(error));
      }
    }
  }

  void _startTimer(PreviewItem item, int epoch) {
    _cancelTimer();
    final recording =
        TaskTypeMeta.forTaskType(
          item.taskTypeCode ?? item.taskType ?? '',
        )?.family ==
        TaskTemplateFamily.recordResponse;
    final preparation = recording && item.prepSeconds > 0;
    final seconds = preparation
        ? item.prepSeconds
        : item.responseSeconds > 0
        ? item.responseSeconds
        : null;
    if (seconds == null || isClosed) return;
    final current = state;
    if (current is! HostExamPreviewReady || current.epoch != epoch) return;
    emit(current.copyWith(remainingSeconds: seconds, isPreparing: preparation));
    var audioStarted = false;
    void playIfReady(int remaining) {
      if (audioStarted || item.audioUrl == null) return;
      final elapsed = seconds - remaining;
      if (elapsed < (item.preListenSeconds ?? 0)) return;
      audioStarted = true;
      unawaited(playAudio(item.audioUrl!).catchError((Object _) {}));
    }

    playIfReady(seconds);
    if (recording && !preparation) unawaited(startRecording());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final latest = state;
      if (latest is! HostExamPreviewReady || latest.epoch != epoch) {
        _cancelTimer();
        return;
      }
      final remaining = latest.remainingSeconds ?? seconds;
      if (latest.isRecordingPaused || _recordingControlBusy) return;
      if (item.audioUrl != null && _mediaSession?.playbackControlBusy == true) {
        return;
      }
      if (item.audioUrl != null &&
          _mediaSession?.playback.value.phase == PreviewPlaybackPhase.paused) {
        return;
      }
      playIfReady(remaining - 1);
      if (remaining <= 1) {
        if (latest.isPreparing) {
          emit(
            latest.copyWith(
              isPreparing: false,
              remainingSeconds: item.responseSeconds,
            ),
          );
          unawaited(startRecording());
          return;
        }
        emit(latest.copyWith(remainingSeconds: 0));
        _cancelTimer();
        if (recording) unawaited(stopRecording());
        return;
      }
      emit(latest.copyWith(remainingSeconds: remaining - 1));
    });
  }

  String _answerKey(PreviewSnapshot snapshot, PreviewItem item) =>
      '${snapshot.snapshotPublicId}:${item.snapshotItemPublicId}';

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() async {
    _epoch++;
    _cancelTimer();
    _answerController.clear();
    await _mediaSession?.dispose();
    return super.close();
  }
}
