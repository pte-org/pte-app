import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/session_types.dart';
import '../bloc/session_create_bloc.dart';
import '../bloc/session_create_event.dart';
import '../bloc/session_create_state.dart';

class SessionCreatePage extends StatefulWidget {
  const SessionCreatePage({super.key});

  @override
  State<SessionCreatePage> createState() => _SessionCreatePageState();
}

class _SessionCreatePageState extends State<SessionCreatePage> {
  final _nameController = TextEditingController();
  final _opensController = TextEditingController();
  final _closesController = TextEditingController();
  final Set<ExamSkill> _selectedSkills = {};
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _opensController.dispose();
    _closesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.createSessionTitle)),
      body: BlocConsumer<SessionCreateBloc, SessionCreateState>(
        listener: (context, state) {
          if (state is SessionCreateSuccess) {
            Navigator.of(context).pop(state.session);
          }
        },
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          children: [
            _field(
              key: const ValueKey('session-name'),
              controller: _nameController,
              label: AppStrings.sessionNameLabel,
            ),
            Text(
              AppStrings.examSkillsLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(AppStrings.examSkillsHint),
            for (final skill in ExamSkill.values)
              CheckboxListTile(
                key: ValueKey('skill-${skill.wireName}'),
                value: _selectedSkills.contains(skill),
                title: Text(_skillLabel(skill)),
                onChanged: (selected) => setState(() {
                  if (selected ?? false) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                }),
              ),
            const SizedBox(height: AppDimensions.spacingMedium),
            _field(
              key: const ValueKey('opens-at'),
              controller: _opensController,
              label: AppStrings.opensAtLabel,
              hint: AppStrings.sessionWindowHint,
            ),
            _field(
              key: const ValueKey('closes-at'),
              controller: _closesController,
              label: AppStrings.closesAtLabel,
              hint: AppStrings.sessionWindowHint,
            ),
            if (_message(state) case final message?)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.spacingMedium,
                ),
                child: Text(message),
              ),
            PrimaryButton(
              label: AppStrings.createSession,
              isLoading: state is SessionCreateSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  String _skillLabel(ExamSkill skill) => switch (skill) {
    ExamSkill.speaking => AppStrings.examSkillSpeaking,
    ExamSkill.writing => AppStrings.examSkillWriting,
    ExamSkill.reading => AppStrings.examSkillReading,
    ExamSkill.listening => AppStrings.examSkillListening,
  };

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
    child: TextField(
      key: key,
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

  String? _message(SessionCreateState state) => switch (state) {
    SessionCreateInvalid(:final message) => message,
    SessionCreateFailure() => AppStrings.sessionCreateFailure,
    _ => _localError,
  };

  void _submit() {
    final opensAt = DateTime.tryParse(_opensController.text.trim());
    final closesAt = DateTime.tryParse(_closesController.text.trim());
    if (opensAt == null || closesAt == null) {
      setState(() => _localError = AppStrings.sessionValidationFailure);
      return;
    }
    setState(() => _localError = null);
    context.read<SessionCreateBloc>().add(
      SessionCreateSubmitted(
        CreateSessionInput(
          name: _nameController.text,
          skills: _selectedSkills,
          opensAt: opensAt,
          closesAt: closesAt,
        ),
      ),
    );
  }
}
