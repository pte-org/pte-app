import '../../domain/entities/host_exam_summary.dart';

sealed class HostExamListState {
  const HostExamListState();
}

final class HostExamListInitial extends HostExamListState {
  const HostExamListInitial();
}

final class HostExamListLoading extends HostExamListState {
  const HostExamListLoading();
}

final class HostExamListLoaded extends HostExamListState {
  const HostExamListLoaded(this.exams);

  final List<HostExamSummary> exams;
}

final class HostExamListError extends HostExamListState {
  const HostExamListError(this.error);

  final Object error;
}
