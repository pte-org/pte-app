import 'package:flutter/material.dart';
import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_typography.dart';
import '../../constants/reading_strings.dart';

/// Controlled answer order. Source retains the supplied shuffled option order;
/// only paragraphs explicitly moved to Target form the answer.
class ParagraphSourceTarget extends StatefulWidget {
  const ParagraphSourceTarget({
    super.key,
    required this.paragraphs,
    required this.targetIds,
    required this.onChanged,
  });
  final Map<String, String> paragraphs;
  final List<String> targetIds;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ParagraphSourceTarget> createState() => _ParagraphSourceTargetState();
}

class _ParagraphSourceTargetState extends State<ParagraphSourceTarget> {
  String? _selected;

  void _move(String id, bool toTarget, [int? position]) {
    if (!widget.paragraphs.containsKey(id)) return;
    final next = List<String>.of(widget.targetIds);
    final oldPosition = next.indexOf(id);
    next.remove(id);
    if (toTarget) {
      var insertion = position ?? widget.targetIds.length;
      if (oldPosition >= 0 && oldPosition < insertion) insertion--;
      next.insert(insertion.clamp(0, next.length), id);
    }
    setState(() => _selected = id);
    widget.onChanged(next);
  }

  void _shift(int delta) {
    final next = List<String>.of(widget.targetIds);
    final position = next.indexOf(_selected ?? '');
    if (position < 0 ||
        position + delta < 0 ||
        position + delta >= next.length) {
      return;
    }
    final id = next.removeAt(position);
    next.insert(position + delta, id);
    widget.onChanged(next);
  }

  Widget _arrow(String label, IconData icon, VoidCallback? action) =>
      IconButton(
        tooltip: label,
        onPressed: action,
        iconSize: AppDimensions.paragraphArrowIconSize,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: AppDimensions.paragraphArrowIconSize,
          height: AppDimensions.paragraphArrowIconSize,
        ),
        icon: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final selectedInTarget = widget.targetIds.contains(_selected);
    final validSelection = widget.paragraphs.containsKey(_selected);
    final position = widget.targetIds.indexOf(_selected ?? '');
    final transfers = Wrap(
      alignment: WrapAlignment.center,
      children: [
        _arrow(
          ReadingStrings.moveToSource,
          Icons.arrow_left,
          validSelection && selectedInTarget
              ? () => _move(_selected!, false)
              : null,
        ),
        _arrow(
          ReadingStrings.moveToTarget,
          Icons.arrow_right,
          validSelection && !selectedInTarget
              ? () => _move(_selected!, true)
              : null,
        ),
      ],
    );
    final shifts = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrow(
          ReadingStrings.moveUp,
          Icons.arrow_drop_up,
          position > 0 ? () => _shift(-1) : null,
        ),
        _arrow(
          ReadingStrings.moveDown,
          Icons.arrow_drop_down,
          position >= 0 && position < widget.targetIds.length - 1
              ? () => _shift(1)
              : null,
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final source = _panel(false, constraints.maxWidth);
        final target = _panel(true, constraints.maxWidth);
        if (constraints.maxWidth < AppDimensions.templateSideBySideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              source,
              transfers,
              target,
              Center(child: shifts),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: source),
            Padding(
              padding: const EdgeInsets.only(top: 96),
              child: SizedBox(width: 80, child: transfers),
            ),
            Expanded(child: target),
            Padding(padding: const EdgeInsets.only(top: 96), child: shifts),
          ],
        );
      },
    );
  }

  Widget _panel(bool target, double availableWidth) {
    final ids = target
        ? widget.targetIds
        : widget.paragraphs.keys
              .where((id) => !widget.targetIds.contains(id))
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          color: AppColors.textSecondary,
          child: Text(
            target ? ReadingStrings.target : ReadingStrings.source,
            textAlign: TextAlign.center,
            style: AppTypography.instructionBold.copyWith(
              color: AppColors.textInverse,
            ),
          ),
        ),
        DragTarget<String>(
          onWillAcceptWithDetails: (details) =>
              widget.paragraphs.containsKey(details.data),
          onAcceptWithDetails: (details) => _move(details.data, target),
          builder: (context, candidates, rejected) => Container(
            key: ValueKey(target ? 'paragraphTarget' : 'paragraphSource'),
            constraints: const BoxConstraints(minHeight: 280),
            decoration: BoxDecoration(
              color: candidates.isEmpty
                  ? AppColors.surface
                  : AppColors.interactiveSelected,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < ids.length; index++)
                  _dropRow(ids[index], target, index, availableWidth),
                // Empty slots remain available as a drop destination.
                for (
                  var index = ids.length;
                  index < widget.paragraphs.length;
                  index++
                )
                  Container(
                    height: 56,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropRow(String id, bool target, int index, double availableWidth) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          widget.paragraphs.containsKey(details.data),
      onAcceptWithDetails: (details) =>
          _move(details.data, target, target ? index : null),
      builder: (context, candidates, rejected) => DecoratedBox(
        decoration: BoxDecoration(
          border: candidates.isEmpty
              ? null
              : const Border(
                  top: BorderSide(color: AppColors.brandPrimary, width: 2),
                ),
        ),
        child: Draggable<String>(
          data: id,
          feedback: Material(
            child: SizedBox(
              width: (availableWidth / 2).clamp(180, 500),
              child: _tile(id),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: _tile(id)),
          child: _tile(id),
        ),
      ),
    );
  }

  Widget _tile(String id) {
    final selected = _selected == id;
    return Material(
      color: selected ? AppColors.textSecondary : AppColors.surface,
      child: InkWell(
        key: ValueKey('paragraph-$id'),
        onTap: () => setState(() => _selected = id),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.drag_handle,
                size: 18,
                color: selected
                    ? AppColors.textInverse
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Expanded(
                child: Text(
                  widget.paragraphs[id]!,
                  style: AppTypography.examAnswer.copyWith(
                    color: selected
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
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
