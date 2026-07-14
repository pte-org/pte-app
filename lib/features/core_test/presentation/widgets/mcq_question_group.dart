import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

/// A grammar multiple-choice group: an optional "Example" label, a prompt
/// sentence with a blank, and a vertical list of single-select radio options.
///
/// Read-only when [onSelected] is null (used for the pre-answered example).
class McqQuestionGroup extends StatelessWidget {
  final String? exampleLabel;
  final String prompt;
  final List<String> options;
  final int? selectedIndex;
  final ValueChanged<int>? onSelected;

  const McqQuestionGroup({
    super.key,
    this.exampleLabel,
    required this.prompt,
    required this.options,
    this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exampleLabel != null) ...[
          Text(exampleLabel!, style: AppTextStyles.mcqExampleLabel),
          const SizedBox(height: AppDimensions.spacingMedium),
        ],
        Text(prompt, style: AppTextStyles.mcqPrompt),
        const SizedBox(height: AppDimensions.mcqPromptGap),
        for (int i = 0; i < options.length; i++) ...[
          _RadioOptionRow(
            label: options[i],
            selected: selectedIndex == i,
            onTap: onSelected == null ? null : () => onSelected!(i),
          ),
          if (i < options.length - 1)
            const SizedBox(height: AppDimensions.mcqOptionRowGap),
        ],
      ],
    );
  }
}

class _RadioOptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _RadioOptionRow({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          _RadioButton(selected: selected),
          const SizedBox(width: AppDimensions.mcqRadioLabelGap),
          Text(label, style: AppTextStyles.mcqOptionLabel),
        ],
      ),
    );
  }
}

class _RadioButton extends StatelessWidget {
  final bool selected;

  const _RadioButton({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.mcqRadioSize,
      height: AppDimensions.mcqRadioSize,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.radioSelectedBackground
            : AppColors.backgroundWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primaryLime : AppColors.radioBorder,
          width: AppDimensions.mcqRadioBorderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.radioShadow,
            blurRadius: AppDimensions.radioShadowBlur,
            offset: Offset(0, AppDimensions.radioShadowOffsetY),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: AppDimensions.mcqRadioInnerSize,
              height: AppDimensions.mcqRadioInnerSize,
              decoration: const BoxDecoration(
                color: AppColors.primaryLime,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
