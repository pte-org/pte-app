import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';

class InlineBlankChoice {
  const InlineBlankChoice({required this.value, required this.text});
  final String value;
  final String text;
}

/// Anchored exam dropdown: opens below the blank instead of covering it.
class InlineBlankDropdown extends StatefulWidget {
  const InlineBlankDropdown({
    super.key,
    required this.options,
    required this.width,
    required this.value,
    required this.onChanged,
  });
  final List<InlineBlankChoice> options;
  final double width;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  State<InlineBlankDropdown> createState() => _InlineBlankDropdownState();
}

class _InlineBlankDropdownState extends State<InlineBlankDropdown> {
  final _controller = MenuController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.options
        .where((option) => option.value == widget.value)
        .firstOrNull;
    return SizedBox(
      width: widget.width,
      child: MenuAnchor(
        controller: _controller,
        childFocusNode: _focus,
        consumeOutsideTap: true,
        crossAxisUnconstrained: false,
        onOpen: () => setState(() {}),
        onClose: () => setState(() {}),
        style: MenuStyle(
          alignment: Alignment.bottomLeft,
          minimumSize: WidgetStatePropertyAll(Size(widget.width, 0)),
          maximumSize: WidgetStatePropertyAll(
            Size(widget.width, AppDimensions.inlineBlankMenuMaxHeight),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.inlineBlankRadius,
              ),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        menuChildren: [
          for (final option in widget.options)
            MenuItemButton(
              key: ValueKey('inlineBlankOption-${option.value}'),
              style: ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.standard,
                minimumSize: WidgetStatePropertyAll(
                  Size(widget.width, AppDimensions.inlineBlankControlHeight),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: AppDimensions.spacingSm),
                ),
                textStyle: const WidgetStatePropertyAll(
                  AppTypography.examAnswer,
                ),
                shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      option.value == widget.value ||
                          states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)
                      ? AppColors.brandPrimary
                      : AppColors.surface,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      option.value == widget.value ||
                          states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)
                      ? AppColors.onPrimary
                      : AppColors.textPrimary,
                ),
              ),
              onPressed: () => widget.onChanged(option.value),
              child: Text(
                option.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        builder: (context, controller, _) => TextButton(
          focusNode: _focus,
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          style: TextButton.styleFrom(
            minimumSize: Size(
              widget.width,
              AppDimensions.inlineBlankControlHeight,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            textStyle: AppTypography.examAnswer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppDimensions.inlineBlankRadius,
              ),
              side: BorderSide(
                color: controller.isOpen
                    ? AppColors.brandPrimary
                    : AppColors.border,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected?.text ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                size: AppDimensions.inlineBlankArrowSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
