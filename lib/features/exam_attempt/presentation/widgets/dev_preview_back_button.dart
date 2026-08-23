import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_dimensions.dart';

/// Small floating back affordance overlaid on top of a task screen rendered
/// by a `kDebugMode`-gated preview screen (`ReadingTaskPreviewScreen`,
/// `ListeningTaskPreviewScreen`) — lets a developer return to the fixture
/// list without restarting the app. Deliberately NOT part of `ExamScaffold`/
/// `ExamAppBar` — a real exam attempt must never let a student back out of
/// an in-progress task, so this only exists in the dev-only Stack wrapper
/// each preview screen builds around `TaskTypeDispatcher`.
class DevPreviewBackButton extends StatelessWidget {
  const DevPreviewBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppDimensions.devPreviewBackButtonOffset,
      left: AppDimensions.devPreviewBackButtonOffset,
      child: FloatingActionButton.small(
        heroTag: 'dev-preview-back',
        onPressed: onPressed,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
