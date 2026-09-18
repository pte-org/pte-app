import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/session_types.dart';
import '../../domain/usecases/assign_class.dart';
import '../../domain/usecases/load_assigned_classes.dart';
import '../../domain/usecases/load_session.dart';
import '../../domain/usecases/unassign_class.dart';
import '../../domain/usecases/update_session_status.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required LoadSession loadSession,
    required LoadAssignedClasses loadAssignedClasses,
    required AssignClass assignClass,
    required UnassignClass unassignClass,
    required OpenSession openSession,
    required CloseSession closeSession,
  }) : _loadSession = loadSession,
       _loadAssignedClasses = loadAssignedClasses,
       _assignClass = assignClass,
       _unassignClass = unassignClass,
       _openSession = openSession,
       _closeSession = closeSession,
       super(const SessionDetailInitial()) {
    on<SessionDetailRequested>(_onLoad);
    on<SessionOpenRequested>(_onOpen);
    on<SessionCloseRequested>(_onClose);
    on<ClassAssignRequested>(_onAssignClass);
    on<ClassUnassignRequested>(_onUnassignClass);
  }

  final LoadSession _loadSession;
  final LoadAssignedClasses _loadAssignedClasses;
  final AssignClass _assignClass;
  final UnassignClass _unassignClass;
  final OpenSession _openSession;
  final CloseSession _closeSession;
  ExamSession? _session;
  List<AssignedClass> _assignedClasses = const [];
  bool _mutating = false;

  Future<void> _onLoad(
    SessionDetailRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());
    try {
      await _reload(event.publicId);
      emit(SessionDetailReady(_session!, _assignedClasses));
    } catch (error) {
      emit(SessionDetailFailure(error));
    }
  }

  Future<void> _onOpen(
    SessionOpenRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.canOpen != true) return;
    await _mutateSession(emit, () => _openSession(_session!.publicId));
  }

  Future<void> _onClose(
    SessionCloseRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.canClose != true) return;
    await _mutateSession(emit, () => _closeSession(_session!.publicId));
  }

  Future<void> _onAssignClass(
    ClassAssignRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.isScheduled != true) return;
    await _mutateClasses(
      emit,
      () => _assignClass(_session!.publicId, event.classPublicId),
    );
  }

  Future<void> _onUnassignClass(
    ClassUnassignRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.isScheduled != true) return;
    await _mutateClasses(
      emit,
      () => _unassignClass(_session!.publicId, event.classPublicId),
    );
  }

  Future<void> _mutateSession(
    Emitter<SessionDetailState> emit,
    Future<ExamSession> Function() command,
  ) async {
    if (_mutating || _session == null) return;
    _mutating = true;
    emit(SessionDetailTransitioning(_session!, _assignedClasses));
    try {
      _session = await command();
      emit(SessionDetailReady(_session!, _assignedClasses));
    } on ConflictException catch (error) {
      try {
        await _reload(_session!.publicId);
        emit(SessionDetailConflict(_session!, _assignedClasses, error.message));
      } catch (reloadError) {
        emit(SessionDetailFailure(reloadError));
      }
    } catch (error) {
      emit(
        SessionDetailFailure(
          error,
          data: SessionDetailReady(_session!, _assignedClasses),
        ),
      );
    } finally {
      _mutating = false;
    }
  }

  Future<void> _mutateClasses(
    Emitter<SessionDetailState> emit,
    Future<void> Function() command,
  ) async {
    if (_mutating || _session == null) return;
    _mutating = true;
    emit(SessionDetailTransitioning(_session!, _assignedClasses));
    try {
      await command();
      _assignedClasses = await _loadAssignedClasses(_session!.publicId);
      emit(SessionDetailReady(_session!, _assignedClasses));
    } catch (error) {
      emit(
        SessionDetailFailure(
          error,
          data: SessionDetailReady(_session!, _assignedClasses),
        ),
      );
    } finally {
      _mutating = false;
    }
  }

  Future<void> _reload(String publicId) async {
    final session = await _loadSession(publicId);
    final assignedClasses = await _loadAssignedClasses(publicId);
    _session = session;
    _assignedClasses = assignedClasses;
  }
}
