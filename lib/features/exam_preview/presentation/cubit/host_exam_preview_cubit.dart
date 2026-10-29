import 'package:pte_app/features/exam_preview/constants/exam_preview_strings.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/preview_audio_session.dart';
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

  PreviewAnswerController get answerController => _answerController;

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
    if (mediaSession == null || url.trim().isEmpty) return;
    await mediaSession.play(url);
  }

  Future<void> startRecording() async {
    final current = state;
    final mediaSession = _mediaSession;
    if (current is! HostExamPreviewReady ||
        current.isRecording ||
        mediaSession == null) {
      return;
    }
    await mediaSession.startRecording();
    if (!isClosed) emit(current.copyWith(isRecording: true));
  }

  Future<void> stopRecording() async {
    await _mediaSession?.stopRecording();
    final current = state;
    if (!isClosed && current is HostExamPreviewReady) {
      emit(current.copyWith(isRecording: false));
    }
  }

  Future<void> next() => _move(1);

  Future<void> previous() => _move(-1);

  Future<void> finish() async {
    _epoch++;
    _cancelTimer();
    await _mediaSession?.stopRecording();
    _answerController.clear();
    if (!isClosed) emit(const HostExamPreviewFinished());
  }

  Future<void> _move(int delta) async {
    final current = state;
    if (current is! HostExamPreviewReady || current.isTransitioning) return;
    final nextIndex = current.currentIndex + delta;
    if (nextIndex < 0) return;
    if (nextIndex >= current.snapshot.items.length) {
      if (delta > 0) await finish();
      return;
    }

    final transitionEpoch = ++_epoch;
    _cancelTimer();
    emit(current.copyWith(epoch: transitionEpoch, isTransitioning: true));
    try {
      await _mediaSession?.stopRecording();
      if (isClosed || transitionEpoch != _epoch) return;
      emit(
        current.copyWith(
          currentIndex: nextIndex,
          epoch: transitionEpoch,
          isTransitioning: false,
          isRecording: false,
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
    final seconds = item.responseSeconds > 0 ? item.responseSeconds : null;
    if (seconds == null || isClosed) return;
    final current = state;
    if (current is! HostExamPreviewReady || current.epoch != epoch) return;
    emit(current.copyWith(remainingSeconds: seconds));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final latest = state;
      if (latest is! HostExamPreviewReady || latest.epoch != epoch) {
        _cancelTimer();
        return;
      }
      final remaining = latest.remainingSeconds ?? seconds;
      if (remaining <= 0) {
        _cancelTimer();
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
