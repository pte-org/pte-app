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
  final _snapshotController = TextEditingController();
  final _opensController = TextEditingController();
  final _closesController = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _snapshotController.dispose();
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
            _field(
              key: const ValueKey('snapshot-id'),
              controller: _snapshotController,
              label: AppStrings.snapshotIdLabel,
            ),
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
          snapshotPublicId: _snapshotController.text,
          opensAt: opensAt,
          closesAt: closesAt,
        ),
      ),
    );
  }
}
