import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/app_strings.dart';

/// Cut / Copy / Paste / Undo / Redo row above a text field. Operates
/// directly on [controller] — no external state required. Undo/redo are
/// self-managed via capped [_undoStack]/[_redoStack] snapshots of [controller.text]
/// taken before each edit; cancelled on widget disposal.
class TextEditorToolbar extends StatefulWidget {
  const TextEditorToolbar({super.key, required this.controller, this.trailing});

  final TextEditingController controller;
  final Widget? trailing;

  @override
  State<TextEditorToolbar> createState() => _TextEditorToolbarState();
}

class _TextEditorToolbarState extends State<TextEditorToolbar> {
  static const int _undoStackLimit = 50;

  final List<String> _undoStack = <String>[];
  final List<String> _redoStack = <String>[];
  String _lastSnapshot = '';
  String _copiedText = '';
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _lastSnapshot = widget.controller.text;
    widget.controller.addListener(_pushSnapshotOnEdit);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_pushSnapshotOnEdit);
    super.dispose();
  }

  void _pushSnapshotOnEdit() {
    final current = widget.controller.text;
    if (_restoring || current == _lastSnapshot) return;
    _undoStack.add(_lastSnapshot);
    if (_undoStack.length > _undoStackLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _lastSnapshot = current;
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final previous = _undoStack.removeLast();
    _redoStack.add(_lastSnapshot);
    _restoring = true;
    widget.controller.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    _lastSnapshot = previous;
    _restoring = false;
    setState(() {});
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(_lastSnapshot);
    _restoring = true;
    widget.controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _lastSnapshot = next;
    _restoring = false;
    setState(() {});
  }

  void _cut() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    _copiedText = selection.textInside(value.text);
    widget.controller.value = value.replaced(selection, '');
  }

  void _copy() {
    final value = widget.controller.value;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    _copiedText = selection.textInside(value.text);
  }

  void _paste() {
    // Keep toolbar copy/paste inside this editor; exam clipboard restrictions
    // continue to govern the system clipboard independently.
    if (_copiedText.isEmpty) return;
    final value = widget.controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    widget.controller.value = value.replaced(selection, _copiedText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceSubtle,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMedium,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth <
              AppDimensions.editorToolbarCounterBreakpoint;
          final controls = Row(
            children: [
              _IconButton(
                icon: Icons.content_cut,
                tooltip: AppStrings.editorCutTooltip,
                onPressed: _cut,
              ),
              _IconButton(
                icon: Icons.content_copy,
                tooltip: AppStrings.editorCopyTooltip,
                onPressed: _copy,
              ),
              _IconButton(
                icon: Icons.content_paste,
                tooltip: AppStrings.editorPasteTooltip,
                onPressed: _paste,
              ),
              const Spacer(),
              _IconButton(
                icon: Icons.undo,
                tooltip: AppStrings.editorUndoTooltip,
                onPressed: _undoStack.isEmpty ? null : _undo,
              ),
              _IconButton(
                icon: Icons.redo,
                tooltip: AppStrings.editorRedoTooltip,
                onPressed: _redoStack.isEmpty ? null : _redo,
              ),
              if (!compact && widget.trailing != null) ...[
                const SizedBox(width: AppDimensions.spacingMd),
                widget.trailing!,
              ],
            ],
          );
          return compact && widget.trailing != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    controls,
                    Align(
                      alignment: Alignment.centerRight,
                      child: widget.trailing!,
                    ),
                  ],
                )
              : controls;
        },
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: AppDimensions.editorToolbarIconSize,
      constraints: const BoxConstraints(
        minWidth: AppDimensions.editorToolbarButtonSize,
        minHeight: AppDimensions.editorToolbarButtonSize,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
