import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_error_message.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

void main() {
  test('session resolution failure is shown as student-friendly copy', () {
    expect(
      examAttemptFriendlyErrorMessage(
        const SessionResolutionException('Exam code cannot be empty.'),
      ),
      ExamAttemptStrings.sessionResolutionFailureMessage,
    );
  });

  test('lockdown failure does not expose the exception technical name', () {
    expect(
      examAttemptFriendlyErrorMessage(
        const LockdownActivationException('activation failed'),
      ),
      ExamAttemptStrings.lockdownStartFailureMessage,
    );
  });

  group('session entry 403s explain why the exam cannot be entered', () {
    final cases = {
      'SESSION_NOT_STARTED': ExamAttemptStrings.sessionNotStartedMessage,
      'SESSION_CLOSED': ExamAttemptStrings.sessionClosedMessage,
      'NOT_ENTITLED': ExamAttemptStrings.notEntitledMessage,
    };
    cases.forEach((code, message) {
      test(code, () {
        expect(
          examAttemptFriendlyErrorMessage(ForbiddenException(code)),
          message,
        );
      });
    });

    test('other 403 codes keep the generic permission copy', () {
      expect(
        examAttemptFriendlyErrorMessage(
          const ForbiddenException('SOMETHING_ELSE'),
        ),
        "You don't have permission to do that.",
      );
    });
  });
}
