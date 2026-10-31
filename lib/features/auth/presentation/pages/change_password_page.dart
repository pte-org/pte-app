import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/friendly_error_message.dart';
import '../../../../core/widgets/components/exam_status_block.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../constants/auth_strings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_field_decoration.dart';

/// Shown instead of anything else while the account still holds the temporary
/// password a centre generated for it. The student retypes that password, so
/// the app never keeps it in memory after sign-in.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginCanvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingMd,
            vertical: AppDimensions.spacingXl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Card(
              margin: EdgeInsets.zero,
              color: AppColors.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                side: const BorderSide(color: AppColors.loginHeaderBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 27, 26, 25),
                child: _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AuthStrings.changePasswordTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AuthStrings.changePasswordSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 1.3,
              color: AppColors.loginText,
            ),
          ),
          const SizedBox(height: 22),
          _passwordField(
            key: const Key('change-current'),
            controller: _currentController,
            label: AuthStrings.changePasswordCurrentLabel,
            validator: _required,
          ),
          const SizedBox(height: 17),
          _passwordField(
            key: const Key('change-new'),
            controller: _newController,
            label: AuthStrings.changePasswordNewLabel,
            validator: _validateNew,
          ),
          const SizedBox(height: 17),
          _passwordField(
            key: const Key('change-confirm'),
            controller: _confirmController,
            label: AuthStrings.changePasswordConfirmLabel,
            validator: _validateConfirmation,
          ),
          const SizedBox(height: 8),
          _buildFailure(),
          const SizedBox(height: 10),
          SizedBox(height: 31, child: _buildSubmit()),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('change-signout'),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
            child: const Text(AuthStrings.changePasswordSignOut),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      obscureText: true,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        color: AppColors.loginText,
      ),
      decoration: authFieldDecoration(label),
      validator: validator,
    );
  }

  String? _required(String? value) =>
      value == null || value.isEmpty ? AuthStrings.changePasswordRequired : null;

  String? _validateNew(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.changePasswordRequired;
    }
    return value.length < AuthStrings.minPasswordLength
        ? AuthStrings.changePasswordTooShort
        : null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return AuthStrings.changePasswordRequired;
    }
    return value != _newController.text
        ? AuthStrings.changePasswordMismatch
        : null;
  }

  Widget _buildFailure() {
    return BlocSelector<AuthBloc, AuthState, AuthPasswordChangeFailed?>(
      selector: (state) => state is AuthPasswordChangeFailed ? state : null,
      builder: (context, failed) {
        return failed == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingSm,
                ),
                child: Semantics(
                  liveRegion: true,
                  child: ExamStatusBlock(
                    key: const Key('change-error'),
                    title: AuthStrings.changePasswordFailureTitle,
                    message: friendlyErrorMessage(failed.error),
                    kind: ExamStatusKind.error,
                  ),
                ),
              );
      },
    );
  }

  Widget _buildSubmit() {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state is AuthPasswordChanging,
      builder: (context, isLoading) {
        return PrimaryButton(
          key: const Key('change-submit'),
          label: AuthStrings.changePasswordSubmit,
          isLoading: isLoading,
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(31),
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.brandPrimary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            textStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AuthBloc>().add(
      PasswordChangeSubmitted(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      ),
    );
  }
}
