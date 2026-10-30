import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import 'app.dart';
import 'package:pte_app/core/di/security_module.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/storage/storage_module.dart';
import 'package:pte_app/features/auth/auth_module.dart';
import 'package:pte_app/features/exam_attempt/exam_attempt_module.dart';
import 'package:pte_app/features/exam_preview/data/preview_audio_session.dart';
import 'package:pte_app/features/exam_preview/exam_preview_module.dart';

Future<void> main() async {
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
  WidgetsFlutterBinding.ensureInitialized();
  setupAuthModule();
  setupStorageModule();
  setupSecurityModule();
  // Load forbidden-apps JSON before any attempt begins — keeps the
  // first attempt from paying a 50-100ms asset load on the activate
  // path.
  await getIt<LockdownService>().initialize();
  setupExamAttemptModule();
  setupExamPreviewModule();
  await PreviewAudioSession.cleanupOrphans();
  runApp(const PteApp());
}

GetIt get getIt => GetIt.instance;
