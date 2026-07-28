import '../../domain/session_types.dart';

sealed class SessionDetailState {
  const SessionDetailState();
}

final class SessionDetailInitial extends SessionDetailState {
  const SessionDetailInitial();
}

final class SessionDetailLoading extends SessionDetailState {
  const SessionDetailLoading();
}

base class SessionDetailData extends SessionDetailState {
  const SessionDetailData(this.session, this.options);
  final ExamSession session;
  final List<SnapshotTaskOption> options;
}

final class SessionDetailReady extends SessionDetailData {
  const SessionDetailReady(super.session, super.options);
}

final class SessionDetailTransitioning extends SessionDetailData {
  const SessionDetailTransitioning(super.session, super.options);
}

final class SessionDetailConflict extends SessionDetailData {
  const SessionDetailConflict(super.session, super.options, this.message);
  final String message;
}

final class SessionDetailInvalid extends SessionDetailData {
  const SessionDetailInvalid(super.session, super.options, this.message);
  final String message;
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.error, {this.data});
  final Object error;
  final SessionDetailData? data;
}
