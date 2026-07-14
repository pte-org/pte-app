import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

/// A bordered dropdown box used inside exam question text (sentence completion,
/// reading gap-fill, heading match). Sized to the sentence inline dropdown by
/// default; pass [width]/[height] to widen it (e.g. the heading-match column).
class InlineDropdown extends StatelessWidget {
  final List<String> options;
  final String? value;

  /// A null callback renders a disabled dropdown that still shows [value]
  /// (used for a pre-filled / locked gap).
  final ValueChanged<String?>? onChanged;
  final double width;
  final double height;

  const InlineDropdown({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.width = AppDimensions.sentenceInlineDropdownWidth,
    this.height = AppDimensions.sentenceInlineDropdownHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(
          color: AppColors.dropdownBorder,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sentenceInlineDropdownPaddingH,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.bottomBarBackground,
            size: AppDimensions.sentenceInlineDropdownIconSize,
          ),
          style: AppTextStyles.dropdownText.copyWith(color: AppColors.textDark),
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
