import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/app.dart';
import 'package:pte_app/core/audio/volume_service.dart';
import 'package:pte_app/core/constants/app_strings.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/violation_retry_coordinator.dart';
import 'package:pte_app/core/widgets/loading_view.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:pte_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pte_app/features/auth/presentation/pages/login_page.dart';
import 'package:pte_app/features/device_check/constants/device_check_strings.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_event.dart';
import 'package:pte_app/features/exam_attempt/presentation/bloc/exam_attempt_state.dart';
import 'package:pte_app/features/exam_attempt/reading/presentation/pages/section_completed_screen.dart';
import 'package:pte_app/features/exam_attempt/speaking_writing/domain/audio_recorder_service.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockExamAttemptBloc extends MockBloc<ExamAttemptEvent, ExamAttemptState>
    implements ExamAttemptBloc {}

class _MockViolationRetryCoordinator extends Mock
    implements ViolationRetryCoordinator {}

class _MockLockdownService extends Mock implements LockdownService {}

class _MockAudioRecorderService extends Mock implements AudioRecorderService {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockExamAttemptBloc examBloc;
  late _MockViolationRetryCoordinator coordinator;
  late _MockLockdownService lockdownService;
  late _MockAudioRecorderService recorderService;
  late VolumeService volumeService;

  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
    registerFallbackValue(
      const SessionResolutionRequested(rawInput: 'session-id'),
    );
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    examBloc = _MockExamAttemptBloc();
    coordinator = _MockViolationRetryCoordinator();
    lockdownService = _MockLockdownService();
    recorderService = _MockAudioRecorderService();
    volumeService = VolumeService();

    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthIdle(),
    );
    whenListen(
      examBloc,
      const Stream<ExamAttemptState>.empty(),
      initialState: const AttemptIdle(),
    );

    when(() => coordinator.start()).thenReturn(null);
    when(() => coordinator.dispose()).thenAnswer((_) async {});
    when(
      () => lockdownService.exitDeviceCheckFullscreen(),
    ).thenAnswer((_) async {});
    when(
      () => lockdownService.enterDeviceCheckFullscreen(),
    ).thenAnswer((_) async {});

    final getIt = GetIt.instance;
    if (getIt.isRegistered<AuthBloc>()) getIt.unregister<AuthBloc>();
    if (getIt.isRegistered<ExamAttemptBloc>())
      getIt.unregister<ExamAttemptBloc>();
    if (getIt.isRegistered<ViolationRetryCoordinator>()) {
      getIt.unregister<ViolationRetryCoordinator>();
    }
    if (getIt.isRegistered<LockdownService>())
      getIt.unregister<LockdownService>();
    if (getIt.isRegistered<AudioRecorderService>())
      getIt.unregister<AudioRecorderService>();
    if (getIt.isRegistered<VolumeService>()) getIt.unregister<VolumeService>();

    getIt.registerSingleton<AuthBloc>(authBloc);
    getIt.registerLazySingleton<ExamAttemptBloc>(() => examBloc);
    getIt.registerSingleton<ViolationRetryCoordinator>(coordinator);
    getIt.registerSingleton<LockdownService>(lockdownService);
    getIt.registerSingleton<AudioRecorderService>(recorderService);
    getIt.registerSingleton<VolumeService>(volumeService);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<AuthBloc>()) getIt.unregister<AuthBloc>();
    if (getIt.isRegistered<ExamAttemptBloc>())
      getIt.unregister<ExamAttemptBloc>();
    if (getIt.isRegistered<ViolationRetryCoordinator>()) {
      getIt.unregister<ViolationRetryCoordinator>();
    }
    if (getIt.isRegistered<LockdownService>())
      getIt.unregister<LockdownService>();
    if (getIt.isRegistered<AudioRecorderService>())
      getIt.unregister<AudioRecorderService>();
    if (getIt.isRegistered<VolumeService>()) getIt.unregister<VolumeService>();
  });

  group('PteApp and App Shell integration', () {
    testWidgets('PteApp builds MaterialApp with LoginPage as initial home', (
      tester,
    ) async {
      await tester.pumpWidget(const PteApp());
      await tester.pump();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets(
      'AppAuthGate syncs ViolationRetryCoordinator on auth state changes',
      (tester) async {
        final authStates = StreamController<AuthState>.broadcast();
        whenListen(authBloc, authStates.stream, initialState: const AuthIdle());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const AppAuthGate(),
            ),
          ),
        );

        // Student logs in -> coordinator started
        authStates.add(
          const AuthAuthenticated(
            JwtClaims(roles: ['STUDENT'], tenantId: 'tenant-1'),
          ),
        );
        await tester.pump();
        verify(() => coordinator.start()).called(1);

        // Unauthenticated -> coordinator disposed
        authStates.add(const AuthUnauthenticated());
        await tester.pump();
        verify(() => coordinator.dispose()).called(1);

        await authStates.close();
      },
    );

    testWidgets(
      'StudentExamGate renders SectionCompletedScreen on AttemptCompleted',
      (tester) async {
        whenListen(
          examBloc,
          const Stream<ExamAttemptState>.empty(),
          initialState: const AttemptCompleted(
            'att-done',
            attemptNumber: 1,
            remainingRetries: 2,
            canRetry: true,
            timeExpired: false,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const StudentExamGate(initialSessionId: 'sess-completed'),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(SectionCompletedScreen), findsOneWidget);

        // Tap continue -> calls _resetToLogin which dispatches LogoutRequested
        await tester.tap(find.text(AppStrings.sectionCompletedContinueButton));
        await tester.pump();
        verify(() => authBloc.add(any(that: isA<LogoutRequested>()))).called(1);
      },
    );

    testWidgets(
      'StudentExamGate displays retry and error state on AttemptError',
      (tester) async {
        final examStates = StreamController<ExamAttemptState>.broadcast();
        whenListen(
          examBloc,
          examStates.stream,
          initialState: const AttemptIdle(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const StudentExamGate(initialSessionId: 'sess-err'),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(LoadingView), findsOneWidget);

        // Transition to AttemptError before attempt start
        examStates.add(AttemptError(Exception('Session expired')));
        await tester.pump();

        expect(
          find.text(ExamAttemptStrings.attemptStartFailureTitle),
          findsOneWidget,
        );
        expect(find.text(ExamAttemptStrings.attemptStartRetry), findsOneWidget);
        expect(
          find.text(ExamAttemptStrings.attemptStartChangeSession),
          findsOneWidget,
        );

        // Tap retry
        await tester.tap(find.text(ExamAttemptStrings.attemptStartRetry));
        await tester.pump();
        verify(
          () => examBloc.add(any(that: isA<SessionResolutionRequested>())),
        ).called(greaterThanOrEqualTo(1));

        // Tap change session
        await tester.tap(
          find.text(ExamAttemptStrings.attemptStartChangeSession),
        );
        await tester.pump();
        verify(() => authBloc.add(any(that: isA<LogoutRequested>()))).called(1);

        await examStates.close();
      },
    );

    testWidgets(
      'StudentExamGate shows fullscreen error when enterDeviceCheckFullscreen fails',
      (tester) async {
        when(() => lockdownService.enterDeviceCheckFullscreen()).thenThrow(
          const LockdownActivationException(
            'Fullscreen failed',
            failedChecks: ['Display error'],
          ),
        );

        whenListen(
          examBloc,
          const Stream<ExamAttemptState>.empty(),
          initialState: const DeviceCheckRequired('sess-dc-fail'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: const StudentExamGate(initialSessionId: 'sess-dc-fail'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text(DeviceCheckStrings.fullscreenUnavailableTitle),
          findsOneWidget,
        );
        expect(
          find.text(DeviceCheckStrings.fullscreenRetryLabel),
          findsOneWidget,
        );
        expect(find.text('Display error'), findsOneWidget);

        // Tap retry on fullscreen gate
        await tester.tap(find.text(DeviceCheckStrings.fullscreenRetryLabel));
        await tester.pump();
        verify(
          () => lockdownService.enterDeviceCheckFullscreen(),
        ).called(greaterThanOrEqualTo(2));
      },
    );
  });
}
