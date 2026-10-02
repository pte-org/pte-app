import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_error_message.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

void main() {
  test('session resolution failure is shown as student-friendly copy', () {
    expect(
      examAttemptFriendlyErrorMessage(
        const SessionResolutionException('Session ID cannot be empty.'),
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
}
