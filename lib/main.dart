import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/storage_module.dart';
import 'features/authoring/authoring_module.dart';
import 'features/auth/auth_module.dart';
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/host_console/host_console_module.dart';
import 'features/host_audit/host_audit_module.dart';
import 'features/host_users/host_users_module.dart';
import 'features/report/report_module.dart';
import 'features/scoring_review/scoring_review_module.dart';
import 'features/scheduling/scheduling_module.dart';

void main() {
  setupAuthModule();
  setupStorageModule();
  setupExamAttemptModule();
  setupReportModule();
  setupHostConsoleModule();
  setupHostAuditModule();
  setupHostUsersModule();
  setupAuthoringModule();
  setupSchedulingModule();
  setupScoringReviewModule();
  runApp(const PteApp());
}
