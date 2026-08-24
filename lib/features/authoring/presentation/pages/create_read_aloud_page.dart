import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/authoring_types.dart';
import '../bloc/create_read_aloud_bloc.dart';
import '../bloc/create_read_aloud_event.dart';
import '../bloc/create_read_aloud_state.dart';

class CreateReadAloudPage extends StatefulWidget {
  const CreateReadAloudPage({super.key});

  @override
  State<CreateReadAloudPage> createState() => _CreateReadAloudPageState();
}

class _CreateReadAloudPageState extends State<CreateReadAloudPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createReadAloudTitle)),
      body: BlocConsumer<CreateReadAloudBloc, CreateReadAloudState>(
        listener: (context, state) {
          if (state is CreateReadAloudSuccess) {
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
                _RequiredField(
                  controller: _titleController,
                  label: AppStrings.questionTitleLabel,
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                _RequiredField(
                  controller: _promptController,
                  label: AppStrings.questionPromptLabel,
                  maxLines: 8,
                ),
                if (state is CreateReadAloudInvalid)
                  const Text(AppStrings.authoringValidationFailure),
                if (state is CreateReadAloudFailure)
                  const Text(AppStrings.createQuestionFailure),
                const SizedBox(height: AppDimensions.spacingMedium),
                PrimaryButton(
                  label: AppStrings.createQuestionSubmit,
                  isLoading: state is CreateReadAloudSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<CreateReadAloudBloc>().add(
      ReadAloudSubmitted(
        CreateReadAloudInput(
          title: _titleController.text,
          promptText: _promptController.text,
        ),
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) => value == null || value.trim().isEmpty
          ? AppStrings.authoringFieldRequired
          : null,
    );
  }
}
