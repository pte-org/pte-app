/// User-facing strings for the exam report/results screen.
/// No `Text('literal')` for these — per `docs/CODING_STANDARDS_APP.md`.
class ReportStrings {
  const ReportStrings._();

  static const String reportScreenTitle ='Your report';
  static const String reportNotPublishedTitle ='Waiting for your report';
  static const String reportNotPublishedMessage ='Your host hasn\'t published this report yet. Pull down to check again.';
  static const String reportErrorTitle ='Something went wrong';
  static const String reportErrorMessage ='We couldn\'t load your report. Pull down to try again.';
  static const String reportOverallSectionTitle ='Overall';
  static const String reportCommunicativeSkillsSectionTitle ='Communicative skills';
  static const String reportInsufficientDataLabel ='Insufficient data';
}
