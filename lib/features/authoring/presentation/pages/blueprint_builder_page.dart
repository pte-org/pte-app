import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/authoring_types.dart';
import '../../domain/blueprint_types.dart';
import '../../domain/usecases/load_questions.dart';
import '../bloc/blueprint_builder_bloc.dart';
import '../bloc/blueprint_builder_event.dart';
import '../bloc/blueprint_builder_state.dart';

class BlueprintBuilderPage extends StatefulWidget {
  const BlueprintBuilderPage({super.key});

  @override
  State<BlueprintBuilderPage> createState() => _BlueprintBuilderPageState();
}

class _BlueprintBuilderPageState extends State<BlueprintBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<Question> _selected = [];
  late final Future<List<Question>> _questions =
      GetIt.instance<LoadQuestions>()();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createBlueprint)),
      body: BlocConsumer<BlueprintBuilderBloc, BlueprintBuilderState>(
        listener: (context, state) {
          if (state is BlueprintBuilderSuccess) {
            Navigator.of(context).pop(state.blueprint);
          }
        },
        builder: (context, state) => Form(
          key: _formKey,
          child: Column(
            children: [
              _nameField(),
              const Text(AppStrings.blueprintQuestionsLabel),
              Expanded(child: _questionPicker()),
              if (state is BlueprintBuilderInvalid)
                const Text(AppStrings.blueprintValidationFailure),
              if (state is BlueprintBuilderFailure)
                const Text(AppStrings.blueprintCreateFailure),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMedium),
                child: PrimaryButton(
                  label: AppStrings.createBlueprint,
                  isLoading: state is BlueprintBuilderSubmitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameField() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      child: TextFormField(
        key: const ValueKey('blueprint-name'),
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: AppStrings.blueprintNameLabel,
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? AppStrings.authoringFieldRequired
            : null,
      ),
    );
  }

  Widget _questionPicker() {
    return FutureBuilder<List<Question>>(
      future: _questions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text(AppStrings.questionsLoadFailure));
        }
        if (!snapshot.hasData) return const LoadingView();
        final questions = snapshot.data!;
        return ListView.builder(
          itemCount: questions.length,
          itemBuilder: (_, index) {
            final question = questions[index];
            final selectedIndex = _selected.indexWhere(
              (item) => item.publicId == question.publicId,
            );
            return CheckboxListTile(
              value: selectedIndex >= 0,
              title: Text(question.title),
              subtitle: Text(
                selectedIndex >= 0
                    ? '${selectedIndex + 1}. ${question.section}'
                    : question.section,
              ),
              onChanged: (selected) => _toggle(question, selected ?? false),
            );
          },
        );
      },
    );
  }

  void _toggle(Question question, bool selected) {
    setState(() {
      _selected.removeWhere((item) => item.publicId == question.publicId);
      if (selected) _selected.add(question);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<BlueprintBuilderBloc>().add(
      BlueprintSubmitted(
        CreateBlueprintInput(
          name: _nameController.text,
          items: [
            for (var index = 0; index < _selected.length; index++)
              BlueprintItemInput(
                questionPublicId: _selected[index].publicId,
                section: _selected[index].section,
                orderIndex: index,
              ),
          ],
        ),
      ),
    );
  }
}
