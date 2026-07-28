import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/storage_module.dart';
import 'features/authoring/authoring_module.dart';
import 'features/auth/auth_module.dart';
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/host_console/host_console_module.dart';
import 'features/report/report_module.dart';
import 'features/scheduling/scheduling_module.dart';

void main() {
  setupAuthModule();
  setupStorageModule();
  setupExamAttemptModule();
  setupReportModule();
  setupHostConsoleModule();
  setupAuthoringModule();
  setupSchedulingModule();
  runApp(const PteApp());
}
