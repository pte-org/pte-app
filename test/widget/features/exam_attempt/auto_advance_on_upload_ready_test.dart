import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/core/storage/pending_media_upload_status.dart';
import 'package:pte_app/core/sync/sync_engine.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/auto_record_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/auto_record_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/auto_advance_on_upload_ready.dart';

// Exercised via one concrete binding, AutoAdvanceOnUploadReady<AutoRecordCubit,
// AutoRecordState> — the generic widget has no logic that varies by type
// parameter, and since Read Aloud, Repeat Sentence, and Describe Image all
// share the same AutoRecordCubit/AutoRecordState now, one binding covers
// all three screens' usage.
class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockAutoRecordCubit extends MockCubit<AutoRecordState> implements AutoRecordCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NextTaskRequested());
  });

  late _MockExamAttemptBloc bloc;
  late _MockSyncEngine syncEngine;
  late _MockAutoRecordCubit autoRecordCubit;
  late StreamController<AutoRecordState> cubitStateController;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    syncEngine = _MockSyncEngine();
    autoRecordCubit = _MockAutoRecordCubit();
    cubitStateController = StreamController<AutoRecordState>.broadcast();
    when(() => syncEngine.flushOne(any())).thenAnswer((_) async {});
  });

  tearDown(() => cubitStateController.close());

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: BlocProvider<AutoRecordCubit>.value(
          value: autoRecordCubit,
          child: Scaffold(
            body: AutoAdvanceOnUploadReady<AutoRecordCubit, AutoRecordState>(
              pinnedItemPublicId: 'item-1',
              syncEngine: syncEngine,
            ),
          ),
        ),
      ),
    );
  }

  void stubCubitState(AutoRecordState initial) {
    when(() => autoRecordCubit.state).thenReturn(initial);
    whenListen(autoRecordCubit, cubitStateController.stream, initialState: initial);
  }

  group('AutoAdvanceOnUploadReady — advances on its own once ready, no tap required', () {
    testWidgets('renders nothing while not yet ready, and never advances', (tester) async {
      stubCubitState(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.uploading));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      verifyNever(() => syncEngine.flushOne(any()));
      verifyNever(() => bloc.add(any()));
    });

    testWidgets(
      'the moment uploadStatus transitions to ready, flushOne is called then NextTaskRequested is dispatched — '
      'automatically, with no user interaction',
      (tester) async {
        stubCubitState(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.uploading));
        await tester.pumpWidget(buildSubject());

        cubitStateController.add(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.ready));
        await tester.pump();
        await tester.pump();

        verify(() => syncEngine.flushOne('item-1')).called(1);
        verify(() => bloc.add(const NextTaskRequested())).called(1);
      },
    );

    testWidgets('a later unrelated rebuild while already ready never advances a second time', (tester) async {
      stubCubitState(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.uploading));
      await tester.pumpWidget(buildSubject());

      cubitStateController.add(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.ready));
      await tester.pump();
      await tester.pump();

      // Same uploadStatus emitted again (e.g. an unrelated recordingPhase
      // no-op re-emission) — listenWhen only fires on the not-ready->ready
      // transition, so this must not trigger a second advance.
      cubitStateController.add(const AutoRecordState(uploadStatus: PendingMediaUploadStatus.ready));
      await tester.pump();
      await tester.pump();

      // Verified once, at the end, counting the cumulative call count across
      // both emissions — mocktail's `verify` marks matched invocations as
      // consumed, so calling `verify(...).called(1)` a second time for the
      // same interaction would spuriously fail even if production code
      // never double-advanced.
      verify(() => syncEngine.flushOne('item-1')).called(1);
      verify(() => bloc.add(const NextTaskRequested())).called(1);
    });
  });
}
