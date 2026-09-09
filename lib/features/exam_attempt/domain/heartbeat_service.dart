import 'dart:async';

import 'package:logger/logger.dart';

import 'package:pte_app/core/network/api_client.dart';

/// Matches [Timer.periodic]'s signature so a fake factory can be injected
/// for deterministic tests (no real wall-clock waits) — same pattern
/// `SyncEngine.PeriodicTimerFactory` uses.
typedef PeriodicTimerFactory = Timer Function(Duration period, void Function(Timer timer) callback);

const Duration _defaultInterval = Duration(seconds: 15);

/// Presence signal for the parallel connectivity-monitoring feature
/// (client-side-exam-timer Phase 4, FR-04) — pings `POST /attempts/{id}/heartbeat`
/// on a fixed interval throughout an `IN_PROGRESS` attempt, independent of
/// [TimerService]'s per-task lifecycle and of `SyncEngine`'s active-task
/// exclusion (this must fire even while a long response/recording is in
/// progress for the on-screen task — there is no "active task" concept
/// here at all, unlike `SyncEngine`).
///
/// A plain Dart service (not a `Bloc`), started/stopped by `ExamAttemptBloc`
/// alongside `SyncEngine`/`TimerService` — mirrors `SyncEngine`'s own
/// start/stop lifecycle and injectable-timer-factory testing pattern.
class HeartbeatService {
  HeartbeatService({
    required ApiClient apiClient,
    Duration interval = _defaultInterval,
    PeriodicTimerFactory? createPeriodicTimer,
    Logger? logger,
  }) : _apiClient = apiClient,
       _interval = interval,
       _createPeriodicTimer = createPeriodicTimer ?? Timer.periodic,
       _logger = logger ?? Logger();

  final ApiClient _apiClient;
  final Duration _interval;
  final PeriodicTimerFactory _createPeriodicTimer;
  final Logger _logger;

  Timer? _timer;
  String? _runningAttemptId;

  /// Starts pinging immediately (not waiting for the first interval to
  /// elapse) and every [_interval] thereafter. A no-op if already running
  /// for the SAME [attemptPublicId] — mirrors `SyncEngine.startSync`'s own
  /// idempotency guard, since `ExamAttemptBloc` calls this on every
  /// in-progress transition (every task, not just the first); without this
  /// guard, a task transition would restart the periodic timer each time
  /// and could suppress the 15s cadence almost entirely for a run of
  /// quick task-by-task submissions — exactly the "independent of
  /// TimerService's task-scoped lifecycle" requirement this phase calls
  /// for. Starting for a genuinely different attempt implicitly supersedes
  /// any prior chain via [stop] — deliberately *not* `SyncEngine.startSync`'s
  /// stricter behavior of throwing `StateError` for that case (code review
  /// finding: the doc above only claims to mirror the same-attempt
  /// idempotency guard, not that stricter contract). `ExamAttemptBloc`
  /// always routes through `_completeAttempt` — which stops the heartbeat —
  /// before a new attempt can start, so today this branch is unreachable in
  /// practice; silent supersede is chosen over fail-loud here only because
  /// this is a best-effort presence signal, not exam-critical state.
  void start(String attemptPublicId) {
    if (_runningAttemptId == attemptPublicId) return;
    stop();
    _runningAttemptId = attemptPublicId;
    unawaited(_beat(attemptPublicId));
    _timer = _createPeriodicTimer(_interval, (_) => unawaited(_beat(attemptPublicId)));
  }

  /// Never throws, never surfaces to the caller — a failed heartbeat is
  /// purely informational for the (separate) connectivity-monitoring
  /// feature and must never affect the exam flow (Phase 4 Risk mitigation).
  Future<void> _beat(String attemptPublicId) async {
    try {
      await _apiClient.sendHeartbeat(attemptPublicId);
    } catch (e, stackTrace) {
      _logger.w('Heartbeat failed, retrying in $_interval', error: e, stackTrace: stackTrace);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _runningAttemptId = null;
  }

  /// Terminal teardown — not called between attempts, only at app/service
  /// teardown, mirroring `TimerService.dispose`/`SyncEngine.dispose`.
  void dispose() => stop();
}
