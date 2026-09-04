import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'core/storage/storage_module.dart';
import 'features/authoring/authoring_module.dart';
import 'features/auth/auth_module.dart';
import 'features/exam_attempt/exam_attempt_module.dart';
import 'features/host_console/host_console_module.dart';
import 'features/host_audit/host_audit_module.dart';
import 'features/host_users/host_users_module.dart';
import 'features/live_proctor/live_proctor_module.dart';
import 'features/report/report_module.dart';
import 'features/scoring_review/scoring_review_module.dart';
import 'features/scheduling/scheduling_module.dart';

void main() {
  // just_audio has no native Windows backend of its own — bridge it to
  // media_kit (libmpv) on Windows only. macOS/Android/iOS keep using
  // just_audio's own native backends untouched, since those already work
  // (see plans/phat-windows-audio-playback-fix). Must run before any
  // `AudioPlayer` is constructed anywhere in the app, so it sits first in
  // main(), ahead of every module's DI setup.
  JustAudioMediaKit.ensureInitialized(
    windows: true,
    linux: false,
    android: false,
    iOS: false,
    macOS: false,
  );
  setupAuthModule();
  setupStorageModule();
  setupExamAttemptModule();
  setupReportModule();
  setupHostConsoleModule();
  setupHostAuditModule();
  setupHostUsersModule();
  setupLiveProctorModule();
  setupAuthoringModule();
  setupSchedulingModule();
  setupScoringReviewModule();
  runApp(const PteApp());
}
