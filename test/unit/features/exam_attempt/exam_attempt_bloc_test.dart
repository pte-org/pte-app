import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/exam_attempt_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';
import 'package:pte_app/features/exam_attempt/domain/task_view.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';

class _MockExamAttemptRepository extends Mock implements ExamAttemptRepository {}

class _MockSessionEntryRepository extends Mock implements SessionEntryRepository {}

class _MockSyncEngine extends Mock implements SyncEngine {}

/// Stands in for "Member 3's eventual replacement" — a second, independent
/// `SessionEntryRepository` implementation used only to prove the
/// interface seam requires no `ExamAttemptBloc` change (phase-03 Steps 11).
class _AlternativeSessionEntryRepository implements SessionEntryRepository {
  _AlternativeSessionEntryRepository(this._sessionPublicId);

  final String _sessionPublicId;

  @override
  Future<String> resolveSessionPublicId(String rawInput) async => _sessionPublicId;
}

TaskView _task({String pinnedItemPublicId = 'item-1'}) {
  return TaskView(
    pinnedItemPublicId: pinnedItemPublicId,
    orderIndex: 1,
    totalTasks: 5,
    section: 'READING',
    taskType: 'MC_READING_SINGLE',
    title: 'Task title',
    prepSeconds: 30,
    responseSeconds: 60,
    prepDeadline: DateTime(2026, 1, 1),
    responseDeadline: DateTime(2026, 1, 1, 0, 1),
    serverNow: DateTime(2026, 1, 1),
  );
}

void main() {
  late _MockExamAttemptRepository repository;
  late _MockSessionEntryRepository sessionEntryRepository;
  late _MockSyncEngine syncEngine;

  setUp(() {
    repository = _MockExamAttemptRepository();
    sessionEntryRepository = _MockSessionEntryRepository();
    syncEngine = _MockSyncEngine();
    when(() => syncEngine.setActiveTask(any())).thenReturn(null);
    when(() => syncEngine.startSync(any())).thenReturn(null);
    when(() => syncEngine.flushNow(any())).thenAnswer((_) async {});
    when(() => syncEngine.stopSync()).thenReturn(null);
  });

  ExamAttemptBloc buildBloc() => ExamAttemptBloc(
        repository: repository,
        sessionEntryRepository: sessionEntryRepository,
        syncEngine: syncEngine,
      );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'completed:true, task:null produces AttemptCompleted, never AttemptError',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
    verify: (_) {
      verify(() => syncEngine.stopSync()).called(1);
      verifyNever(() => syncEngine.startSync(any()));
      verifyNever(() => syncEngine.flushNow(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'resuming an in-progress attempt calls SyncEngine.startSync then flushNow before AttemptInProgress is emitted '
    '(immediate flush of any leftover outbox rows, not a passive wait)',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(),
        ),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'session-1')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.startSync('attempt-1'),
        () => syncEngine.flushNow('attempt-1'),
      ]);
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'swapping SessionEntryRepository for a different implementation requires no change to ExamAttemptBloc',
    setUp: () {
      when(() => repository.startOrResumeAttempt('deep-link-session')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(),
        ),
      );
    },
    build: () => ExamAttemptBloc(
      repository: repository,
      sessionEntryRepository: _AlternativeSessionEntryRepository('deep-link-session'),
      syncEngine: syncEngine,
    ),
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: 'ignored-by-fake')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptInProgress>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'AttemptCompleted calls stopSync exactly once; a stray NextTaskRequested afterward is a no-op, not a crash',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async =>
            const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true),
      );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
    },
    expect: () => [isA<AttemptStarting>(), isA<AttemptCompleted>()],
    verify: (_) {
      verify(() => syncEngine.stopSync()).called(1);
      verifyNever(() => repository.fetchNextTask(any()));
    },
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'a SessionResolutionException results in AttemptError, never a crash or hang',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId(''))
          .thenThrow(const SessionResolutionException('Session ID cannot be empty.'));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const SessionResolutionRequested(rawInput: '')),
    expect: () => [isA<AttemptStarting>(), isA<AttemptError>()],
  );

  blocTest<ExamAttemptBloc, ExamAttemptState>(
    'setActiveTask is called with the correct pinnedItemPublicId on every task transition, and null immediately before AttemptCompleted',
    setUp: () {
      when(() => sessionEntryRepository.resolveSessionPublicId('session-1')).thenAnswer((_) async => 'session-1');
      when(() => repository.startOrResumeAttempt('session-1')).thenAnswer(
        (_) async => AttemptTaskResponse(
          attemptPublicId: 'attempt-1',
          attemptStatus: 'IN_PROGRESS',
          completed: false,
          task: _task(pinnedItemPublicId: 'item-1'),
        ),
      );

      var fetchCallCount = 0;
      when(() => repository.fetchNextTask('attempt-1')).thenAnswer((_) async {
        fetchCallCount++;
        if (fetchCallCount == 1) {
          return AttemptTaskResponse(
            attemptPublicId: 'attempt-1',
            attemptStatus: 'IN_PROGRESS',
            completed: false,
            task: _task(pinnedItemPublicId: 'item-2'),
          );
        }
        return const AttemptTaskResponse(attemptPublicId: 'attempt-1', attemptStatus: 'COMPLETED', completed: true);
      });
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const SessionResolutionRequested(rawInput: 'session-1'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const NextTaskRequested());
    },
    expect: () => [
      isA<AttemptStarting>(),
      isA<AttemptInProgress>(),
      isA<AttemptInProgress>(),
      isA<AttemptCompleted>(),
    ],
    verify: (_) {
      verifyInOrder([
        () => syncEngine.setActiveTask('item-1'),
        () => syncEngine.setActiveTask('item-2'),
        () => syncEngine.setActiveTask(null),
      ]);
    },
  );
}
