import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:pte_app/features/scheduling/domain/participant_types.dart';
import 'package:pte_app/features/scheduling/domain/usecases/manage_participants.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/participant_command_bloc.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/participant_command_event.dart';
import 'package:pte_app/features/scheduling/presentation/bloc/participant_command_state.dart';

class _MockEnrollStudent extends Mock implements EnrollStudent {}

void main() {
  test('enrollment command is single-flight and returns response', () async {
    final enroll = _MockEnrollStudent();
    final completer = Completer<EnrollmentResult>();
    when(
      () => enroll('session-1', 'student-1'),
    ).thenAnswer((_) => completer.future);
    final bloc = EnrollmentBloc(enrollStudent: enroll);

    bloc
      ..add(const EnrollmentSubmitted('session-1', 'student-1'))
      ..add(const EnrollmentSubmitted('session-1', 'student-1'));
    expect(
      await bloc.stream.firstWhere((state) => state is ParticipantSubmitting),
      isA<ParticipantSubmitting>(),
    );
    verify(() => enroll('session-1', 'student-1')).called(1);
    completer.complete(
      const EnrollmentResult(
        publicId: 'enrollment-1',
        sessionPublicId: 'session-1',
        studentPublicId: 'student-1',
      ),
    );
    expect(
      await bloc.stream.firstWhere((state) => state is ParticipantSuccess),
      isA<ParticipantSuccess>(),
    );
    await bloc.close();
  });
}
