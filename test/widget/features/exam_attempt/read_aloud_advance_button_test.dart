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
import 'package:pte_app/features/exam_attempt/presentation/cubit/read_aloud_cubit.dart';
import 'package:pte_app/features/exam_attempt/presentation/cubit/read_aloud_state.dart';
import 'package:pte_app/features/exam_attempt/presentation/widgets/read_aloud_advance_button.dart';

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState> implements ExamAttemptBloc {}

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockReadAloudCubit extends MockCubit<ReadAloudState> implements ReadAloudCubit {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NextTaskRequested());
  });

  late _MockExamAttemptBloc bloc;
  late _MockSyncEngine syncEngine;
  late _MockReadAloudCubit readAloudCubit;

  setUp(() {
    bloc = _MockExamAttemptBloc();
    syncEngine = _MockSyncEngine();
    readAloudCubit = _MockReadAloudCubit();
    when(() => syncEngine.flushOne(any())).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<ExamAttemptBloc>.value(
        value: bloc,
        child: BlocProvider<ReadAloudCubit>.value(
          value: readAloudCubit,
          child: Scaffold(
            body: ReadAloudAdvanceButton(pinnedItemPublicId: 'item-1', syncEngine: syncEngine),
          ),
        ),
      ),
    );
  }

  void stubCubitState(PendingMediaUploadStatus? uploadStatus) {
    final state = ReadAloudState(uploadStatus: uploadStatus);
    when(() => readAloudCubit.state).thenReturn(state);
    whenListen(readAloudCubit, const Stream<ReadAloudState>.empty(), initialState: state);
  }

  group('ReadAloudAdvanceButton — gated on uploadStatus == ready (Step 13)', () {
    testWidgets('onPressed is null (disabled) while uploadStatus is null (no row yet)', (tester) async {
      stubCubitState(null);

      await tester.pumpWidget(buildSubject());

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.text('Still uploading…'), findsOneWidget);
    });

    testWidgets('onPressed is null (disabled) while uploadStatus is uploading', (tester) async {
      stubCubitState(PendingMediaUploadStatus.uploading);

      await tester.pumpWidget(buildSubject());

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('onPressed is null (disabled) while uploadStatus is completing', (tester) async {
      stubCubitState(PendingMediaUploadStatus.completing);

      await tester.pumpWidget(buildSubject());

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'once uploadStatus reaches ready, the button is enabled and tapping calls syncEngine.flushOne exactly '
      'once, then dispatches NextTaskRequested',
      (tester) async {
        stubCubitState(PendingMediaUploadStatus.ready);

        await tester.pumpWidget(buildSubject());

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNotNull);
        expect(find.text('Next'), findsOneWidget);

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        verify(() => syncEngine.flushOne('item-1')).called(1);
        verify(() => bloc.add(const NextTaskRequested())).called(1);
      },
    );

    testWidgets('a rebuild while still not-ready never calls flushOne — nothing to flush yet', (tester) async {
      stubCubitState(PendingMediaUploadStatus.uploaded);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      verifyNever(() => syncEngine.flushOne(any()));
      verifyNever(() => bloc.add(any()));
    });
  });
}
