import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/session_types.dart';
import '../../domain/usecases/load_session.dart';
import '../../domain/usecases/load_snapshot_options.dart';
import '../../domain/usecases/update_session_composition.dart';
import '../../domain/usecases/update_session_status.dart';
import 'session_detail_event.dart';
import 'session_detail_state.dart';

class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required LoadSession loadSession,
    required LoadSnapshotOptions loadSnapshotOptions,
    required UpdateSessionComposition updateComposition,
    required OpenSession openSession,
    required CloseSession closeSession,
  }) : _loadSession = loadSession,
       _loadSnapshotOptions = loadSnapshotOptions,
       _updateComposition = updateComposition,
       _openSession = openSession,
       _closeSession = closeSession,
       super(const SessionDetailInitial()) {
    on<SessionDetailRequested>(_onLoad);
    on<SessionCompositionSubmitted>(_onComposition);
    on<SessionOpenRequested>(_onOpen);
    on<SessionCloseRequested>(_onClose);
  }

  final LoadSession _loadSession;
  final LoadSnapshotOptions _loadSnapshotOptions;
  final UpdateSessionComposition _updateComposition;
  final OpenSession _openSession;
  final CloseSession _closeSession;
  ExamSession? _session;
  List<SnapshotTaskOption> _options = const [];
  bool _mutating = false;

  Future<void> _onLoad(
    SessionDetailRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    emit(const SessionDetailLoading());
    try {
      await _reload(event.publicId);
      emit(SessionDetailReady(_session!, _options));
    } catch (error) {
      emit(SessionDetailFailure(error));
    }
  }

  Future<void> _onComposition(
    SessionCompositionSubmitted event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_mutating || _session == null) return;
    late final SetCompositionInput input;
    try {
      input = event.input.normalized();
    } on SchedulingValidationException catch (error) {
      emit(SessionDetailInvalid(_session!, _options, error.message));
      return;
    }
    await _mutate(emit, () => _updateComposition(_session!.publicId, input));
  }

  Future<void> _onOpen(
    SessionOpenRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.canOpen != true) return;
    await _mutate(emit, () => _openSession(_session!.publicId));
  }

  Future<void> _onClose(
    SessionCloseRequested event,
    Emitter<SessionDetailState> emit,
  ) async {
    if (_session?.status.canClose != true) return;
    await _mutate(emit, () => _closeSession(_session!.publicId));
  }

  Future<void> _mutate(
    Emitter<SessionDetailState> emit,
    Future<ExamSession> Function() command,
  ) async {
    if (_mutating || _session == null) return;
    _mutating = true;
    emit(SessionDetailTransitioning(_session!, _options));
    try {
      _session = await command();
      emit(SessionDetailReady(_session!, _options));
    } on ConflictException catch (error) {
      try {
        await _reload(_session!.publicId);
        emit(SessionDetailConflict(_session!, _options, error.message));
      } catch (reloadError) {
        emit(SessionDetailFailure(reloadError));
      }
    } catch (error) {
      emit(
        SessionDetailFailure(
          error,
          data: SessionDetailReady(_session!, _options),
        ),
      );
    } finally {
      _mutating = false;
    }
  }

  Future<void> _reload(String publicId) async {
    final session = await _loadSession(publicId);
    final options = await _loadSnapshotOptions(session.snapshotPublicId);
    _session = session;
    _options = options;
  }
}
