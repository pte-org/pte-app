import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/friendly_error_message.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

/// Maps attempt-specific machine codes to the feature's approved student
/// copy. Technical codes remain available on [ApiException] for diagnostics,
/// but are never shown as the primary exam-flow message.
String examAttemptFriendlyErrorMessage(Object error) {
  if (error is LockdownActivationException) {
    return ExamAttemptStrings.lockdownStartFailureMessage;
  }
  if (error is SessionResolutionException) {
    return ExamAttemptStrings.sessionResolutionFailureMessage;
  }
  if (error is ConflictException) {
    return switch (error.message) {
      ExamAttemptStrings.examRequiresAppUpdateCode =>
        ExamAttemptStrings.examRequiresAppUpdateMessage,
      ExamAttemptStrings.examConfigurationNotCompatibleCode =>
        ExamAttemptStrings.examConfigurationNotCompatibleMessage,
      _ => friendlyErrorMessage(error),
    };
  }
  return friendlyErrorMessage(error);
}
