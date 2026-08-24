import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/authoring_types.dart';
import '../bloc/create_question_bloc.dart';
import '../bloc/create_question_event.dart';
import '../bloc/create_question_state.dart';

class CreateMcReadingSinglePage extends StatefulWidget {
  const CreateMcReadingSinglePage({super.key});

  @override
  State<CreateMcReadingSinglePage> createState() =>
      _CreateMcReadingSinglePageState();
}

class _CreateMcReadingSinglePageState extends State<CreateMcReadingSinglePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correctOptionIndex;

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createQuestionTitle)),
      body: BlocConsumer<CreateQuestionBloc, CreateQuestionState>(
        listener: _onStateChanged,
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRequiredField(
                    _titleController,
                    AppStrings.questionTitleLabel,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildRequiredField(
                    _promptController,
                    AppStrings.questionPromptLabel,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildOptions(),
                  OutlinedButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addOption),
                  ),
                  if (state is CreateQuestionInvalid)
                    const Text(AppStrings.authoringValidationFailure),
                  if (state is CreateQuestionFailure)
                    const Text(AppStrings.createQuestionFailure),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  PrimaryButton(
                    label: AppStrings.createQuestionSubmit,
                    isLoading: state is CreateQuestionSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequiredField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.trim().isEmpty
          ? AppStrings.authoringFieldRequired
          : null,
    );
  }

  Widget _buildOptions() {
    return RadioGroup<int>(
      groupValue: _correctOptionIndex,
      onChanged: (value) => setState(() => _correctOptionIndex = value),
      child: Column(
        children: [
          for (var index = 0; index < _optionControllers.length; index++)
            Row(
              children: [
                Expanded(
                  child: _buildRequiredField(
                    _optionControllers[index],
                    '${AppStrings.questionOptionLabel} ${index + 1}',
                  ),
                ),
                Radio<int>(value: index),
                IconButton(
                  tooltip: AppStrings.removeOption,
                  onPressed: _optionControllers.length > 2
                      ? () => _removeOption(index)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _onStateChanged(BuildContext context, CreateQuestionState state) {
    if (state is CreateQuestionSuccess) {
      Navigator.of(context).pop(state.question);
    }
  }

  void _addOption() {
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers.removeAt(index).dispose();
      if (_correctOptionIndex == index) {
        _correctOptionIndex = null;
      } else if (_correctOptionIndex != null && _correctOptionIndex! > index) {
        _correctOptionIndex = _correctOptionIndex! - 1;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<CreateQuestionBloc>().add(
      CreateQuestionSubmitted(
        CreateMcReadingSingleInput(
          title: _titleController.text,
          promptText: _promptController.text,
          options: [
            for (var index = 0; index < _optionControllers.length; index++)
              QuestionOptionInput(
                text: _optionControllers[index].text,
                correct: _correctOptionIndex == index,
                orderIndex: index,
              ),
          ],
        ),
      ),
    );
  }
}
