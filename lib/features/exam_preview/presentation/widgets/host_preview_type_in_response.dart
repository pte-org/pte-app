import 'package:flutter/material.dart';
import 'package:pte_app/features/exam_attempt/domain/blank_prompt_parser.dart';
import 'package:pte_app/features/exam_attempt/listening/presentation/widgets/fill_blanks_listening_text.dart';

class HostPreviewTypeInResponse extends StatefulWidget {
  const HostPreviewTypeInResponse({
    super.key,
    required this.promptText,
    required this.values,
    required this.onChanged,
  });
  final String promptText;
  final Map<int, String> values;
  final ValueChanged<Map<int, String>> onChanged;

  @override
  State<HostPreviewTypeInResponse> createState() =>
      _HostPreviewTypeInResponseState();
}

class _HostPreviewTypeInResponseState extends State<HostPreviewTypeInResponse> {
  final List<TextEditingController> _controllers = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  void _createControllers() {
    final count = parseBlankPrompt(
      widget.promptText,
    ).whereType<PromptGapSegment>().length;
    for (var index = 0; index < count; index++) {
      _controllers.add(
        TextEditingController(text: widget.values[index] ?? '')
          ..addListener(_edited),
      );
    }
  }

  void _edited() {
    if (_syncing) return;
    widget.onChanged({
      for (var i = 0; i < _controllers.length; i++)
        if (_controllers[i].text.isNotEmpty) i: _controllers[i].text,
    });
  }

  @override
  void didUpdateWidget(covariant HostPreviewTypeInResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promptText != widget.promptText) {
      _disposeControllers();
      _createControllers();
    } else {
      _syncing = true;
      for (var i = 0; i < _controllers.length; i++) {
        final value = widget.values[i] ?? '';
        if (_controllers[i].text != value) _controllers[i].text = value;
      }
      _syncing = false;
    }
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.removeListener(_edited);
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FillBlanksListeningText(
    promptText: widget.promptText,
    controllers: _controllers,
  );
}
