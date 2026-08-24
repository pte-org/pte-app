abstract final class AuditTimestampFormatter {
  static String format(DateTime? value, {required String missingLabel}) {
    return value?.toUtc().toIso8601String() ?? missingLabel;
  }
}
