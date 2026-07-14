import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

class DropdownMatchingList extends StatelessWidget {
  final List<String> labels;
  final List<List<String>> optionsList;
  final List<String?> selectedValues;
  final void Function(int index, String? value) onChanged;

  const DropdownMatchingList({
    super.key,
    required this.labels,
    required this.optionsList,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(labels.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  labels[index],
                  style: AppTextStyles.instruction,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              _MatchingDropdown(
                options: optionsList[index],
                value: selectedValues[index],
                onChanged: (value) => onChanged(index, value),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MatchingDropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _MatchingDropdown({
    required this.options,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Allow flexible width up to a reasonable max for options like "Man", "Woman", "Speaker A", etc.
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
      height: AppDimensions.matchDropdownHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.dropdownBorder,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.matchDropdownPaddingH,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.bottomBarBackground,
            size: AppDimensions.matchDropdownIconSize,
          ),
          style: AppTextStyles.dropdownText.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.normal,
          ),
          isExpanded: true,
          items: options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
