import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

/// Standard elevated button with a built-in loading spinner — every
/// primary action across the app (advance, submit, retry) uses this
/// instead of a bare `ElevatedButton` reimplemented per call site.
/// [onPressed] is ignored (button disabled) while [isLoading] is true,
/// regardless of what's passed in.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: AppDimensions.advanceButtonSpinnerSize,
              height: AppDimensions.advanceButtonSpinnerSize,
              child: CircularProgressIndicator(strokeWidth: AppDimensions.advanceButtonSpinnerStrokeWidth),
            )
          : Text(label),
    );
  }
}
