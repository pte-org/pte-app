import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/security/models/violation_event.dart';
import 'package:pte_app/features/exam_attempt/constants/exam_attempt_strings.dart';

/// Top-of-screen yellow banner that briefly announces a detected
/// violation to the student. Driven by `LockdownService.violations`
/// — Phase 5 design constraint: banner is only meaningful for
/// `STANDARD` mode, since `STRICT` violations never reach the UI
/// (they're already blocked at the native layer). `ViolationType`
/// maps onto the right copy via [_messageFor].
///
/// Auto-dismiss after [displayDuration] (5s default) so a noisy exam
/// doesn't accumulate banners. Replacing the banner with a new
/// violation restarts the timer — the latest event is always the most
/// relevant one to keep on screen.
class ViolationWarningBanner extends StatefulWidget {
  const ViolationWarningBanner({
    super.key,
    this.displayDuration = const Duration(seconds: 5),
    required this.violations,
  });

  /// Stream the banner listens to. Provided by `ExamScaffold`'s
  /// container, so multiple banners can be hoisted in distinct
  /// subtrees without re-subscribing.
  final Stream<ViolationType> violations;

  final Duration displayDuration;

  @override
  State<ViolationWarningBanner> createState() => _ViolationWarningBannerState();
}

class _ViolationWarningBannerState extends State<ViolationWarningBanner> {
  StreamSubscription<ViolationType>? _subscription;
  Timer? _dismissTimer;

  String? _message;

  @override
  void initState() {
    super.initState();
    _subscription = widget.violations.listen(_onViolation, onError: _onError);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _onViolation(ViolationType type) {
    if (!mounted) return;
    _dismissTimer?.cancel();
    setState(() {
      _message = _messageFor(type);
    });
    _dismissTimer = Timer(widget.displayDuration, () {
      if (!mounted) return;
      setState(() {
        _message = null;
      });
    });
  }

  void _onError(Object error) {
    // Stream errors are diagnostic-only; the banner remains available
    // for the next valid event.
    _dismissTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) return const SizedBox.shrink();
    return Material(
      color: AppColors.warningBackground,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMedium,
            vertical: AppDimensions.examHeaderBannerPaddingVertical,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warningIcon,
              ),
              const SizedBox(width: AppDimensions.dragChipSpacing),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.warningForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Maps a [ViolationType] to its user-facing copy. Kept as a free
/// function rather than a constant map so adding a future violation
/// type forces a rebuild and surfaces here, not somewhere stale.
String _messageFor(ViolationType type) {
  return switch (type) {
    ViolationType.fullscreenExit => ExamAttemptStrings.violationFullscreenExit,
    ViolationType.clipboardPaste => ExamAttemptStrings.violationClipboardPaste,
    ViolationType.shortcutBlocked =>
      ExamAttemptStrings.violationShortcutBlocked,
    ViolationType.forbiddenAppDetected =>
      ExamAttemptStrings.violationForbiddenApp,
  };
}
