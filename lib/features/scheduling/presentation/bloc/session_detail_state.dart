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
  const SessionDetailData(this.session, this.assignedClasses);
  final ExamSession session;
  final List<AssignedClass> assignedClasses;
}

final class SessionDetailReady extends SessionDetailData {
  const SessionDetailReady(super.session, super.assignedClasses);
}

final class SessionDetailTransitioning extends SessionDetailData {
  const SessionDetailTransitioning(super.session, super.assignedClasses);
}

final class SessionDetailConflict extends SessionDetailData {
  const SessionDetailConflict(super.session, super.assignedClasses, this.message);
  final String message;
}

final class SessionDetailFailure extends SessionDetailState {
  const SessionDetailFailure(this.error, {this.data});
  final Object error;
  final SessionDetailData? data;
}
