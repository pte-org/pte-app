import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

/// A grid of "label on the left → dropdown on the right" rows.
///
/// [leftAligned] switches to a wider, left-aligned, wrapping label column for
/// long phrases (definition questions); the default is a narrow right-aligned
/// single-word column (synonym / collocation questions).
class WordMatchingGrid extends StatelessWidget {
  final List<String> words;
  final List<List<String>> optionsList;
  final Map<int, String?> answers;
  final void Function(int index, String? value) onAnswerChanged;
  final bool leftAligned;

  const WordMatchingGrid({
    super.key,
    required this.words,
    required this.optionsList,
    required this.answers,
    required this.onAnswerChanged,
    this.leftAligned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < words.length; i++)
          _WordMatchingRow(
            word: words[i],
            options: optionsList[i],
            selectedValue: answers[i],
            onChanged: (value) => onAnswerChanged(i, value),
            leftAligned: leftAligned,
            isFirst: i == 0,
          ),
      ],
    );
  }
}

class _WordMatchingRow extends StatelessWidget {
  final String word;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final bool leftAligned;
  final bool isFirst;

  const _WordMatchingRow({
    required this.word,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    required this.leftAligned,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          leftAligned ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: leftAligned
              ? AppDimensions.matchWordWideWidth
              : AppDimensions.matchWordWidth,
          child: Text(
            word,
            textAlign: leftAligned ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontSize: AppDimensions.matchWordFontSize,
              color: AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.matchWordGap),
        _Dropdown(
          options: options,
          value: selectedValue,
          onChanged: onChanged,
          isFirst: isFirst,
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isFirst;

  const _Dropdown({
    required this.options,
    this.value,
    required this.onChanged,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.matchDropdownWidth,
      height: AppDimensions.matchDropdownHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: isFirst
            ? Border.all(
                color: AppColors.dropdownBorder,
                width: AppDimensions.borderWidthThin,
              )
            : const Border(
                left: BorderSide(
                  color: AppColors.dropdownBorder,
                  width: AppDimensions.borderWidthThin,
                ),
                right: BorderSide(
                  color: AppColors.dropdownBorder,
                  width: AppDimensions.borderWidthThin,
                ),
                bottom: BorderSide(
                  color: AppColors.dropdownBorder,
                  width: AppDimensions.borderWidthThin,
                ),
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
