import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/authoring_types.dart';
import '../bloc/create_write_essay_bloc.dart';
import '../bloc/create_write_essay_event.dart';
import '../bloc/create_write_essay_state.dart';

class CreateWriteEssayPage extends StatefulWidget {
  const CreateWriteEssayPage({super.key});

  @override
  State<CreateWriteEssayPage> createState() => _CreateWriteEssayPageState();
}

class _CreateWriteEssayPageState extends State<CreateWriteEssayPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();
  final _referenceController = TextEditingController();
  final _minWordsController = TextEditingController();
  final _maxWordsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _referenceController.dispose();
    _minWordsController.dispose();
    _maxWordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createWriteEssayTitle)),
      body: BlocConsumer<CreateWriteEssayBloc, CreateWriteEssayState>(
        listener: (context, state) {
          if (state is CreateWriteEssaySuccess) {
            Navigator.of(context).pop(state.question);
          }
        },
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _textField(
                  key: const ValueKey('essay-title'),
                  controller: _titleController,
                  label: AppStrings.questionTitleLabel,
                ),
                _textField(
                  key: const ValueKey('essay-prompt'),
                  controller: _promptController,
                  label: AppStrings.questionPromptLabel,
                  maxLines: 6,
                ),
                _textField(
                  key: const ValueKey('essay-reference'),
                  controller: _referenceController,
                  label: AppStrings.referenceAnswerLabel,
                  maxLines: 6,
                ),
                _wordCountFields(),
                if (state is CreateWriteEssayInvalid)
                  const Text(AppStrings.wordCountInvalid),
                if (state is CreateWriteEssayFailure)
                  const Text(AppStrings.createQuestionFailure),
                const SizedBox(height: AppDimensions.spacingMedium),
                PrimaryButton(
                  label: AppStrings.createQuestionSubmit,
                  isLoading: state is CreateWriteEssaySubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required Key key,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
      child: TextFormField(
        key: key,
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppStrings.authoringFieldRequired
            : null,
      ),
    );
  }

  Widget _wordCountFields() {
    return Row(
      children: [
        Expanded(
          child: _numberField(
            key: const ValueKey('essay-min-words'),
            controller: _minWordsController,
            label: AppStrings.minWordCountLabel,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        Expanded(
          child: _numberField(
            key: const ValueKey('essay-max-words'),
            controller: _maxWordsController,
            label: AppStrings.maxWordCountLabel,
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        return parsed == null || parsed <= 0
            ? AppStrings.wordCountInvalid
            : null;
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateWriteEssayBloc>().add(
      WriteEssaySubmitted(
        CreateWriteEssayInput(
          title: _titleController.text,
          promptText: _promptController.text,
          referenceAnswerText: _referenceController.text,
          minWordCount: int.parse(_minWordsController.text.trim()),
          maxWordCount: int.parse(_maxWordsController.text.trim()),
        ),
      ),
    );
  }
}
