import '../../domain/entities/preview_snapshot.dart';

sealed class HostExamPreviewState {
  const HostExamPreviewState();
}

final class HostExamPreviewInitial extends HostExamPreviewState {
  const HostExamPreviewInitial();
}

final class HostExamPreviewLoading extends HostExamPreviewState {
  const HostExamPreviewLoading();
}

final class HostExamPreviewReady extends HostExamPreviewState {
  const HostExamPreviewReady({
    required this.snapshot,
    required this.currentIndex,
    required this.answers,
    required this.epoch,
    this.remainingSeconds,
    this.isTransitioning = false,
    this.isRecording = false,
  });

  final PreviewSnapshot snapshot;
  final int currentIndex;
  final Map<String, Object?> answers;
  final int epoch;
  final int? remainingSeconds;
  final bool isTransitioning;
  final bool isRecording;

  PreviewItem get currentItem => snapshot.items[currentIndex];

  HostExamPreviewReady copyWith({
    int? currentIndex,
    Map<String, Object?>? answers,
    int? epoch,
    int? remainingSeconds,
    bool clearRemainingSeconds = false,
    bool? isTransitioning,
    bool? isRecording,
  }) {
    return HostExamPreviewReady(
      snapshot: snapshot,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      epoch: epoch ?? this.epoch,
      remainingSeconds: clearRemainingSeconds
          ? null
          : remainingSeconds ?? this.remainingSeconds,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      isRecording: isRecording ?? this.isRecording,
    );
  }
}

final class HostExamPreviewFinished extends HostExamPreviewState {
  const HostExamPreviewFinished();
}

final class HostExamPreviewError extends HostExamPreviewState {
  const HostExamPreviewError(this.error);

  final Object error;
}
