import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/friendly_error_message.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.onSessionIdProvided,
    this.requireSessionId = false,
  });

  /// Keeps exam entry context outside the authentication API. The app uses
  /// this value only after a successful student sign-in.
  final ValueChanged<String>? onSessionIdProvided;

  /// Host and proctor accounts can use their workspaces without an exam
  /// session. Student accounts are required to provide the session before
  /// entering the exam flow.
  final bool requireSessionId;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sessionIdController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _sessionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loginCanvas,
      body: Column(
        children: [
          const _LoginHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
                vertical: AppDimensions.spacingXl,
              ),
              child: Center(
                child: _LoginCard(
                  formKey: _formKey,
                  emailField: _buildEmailField(),
                  passwordField: _buildPasswordField(),
                  sessionIdField: _buildSessionIdField(),
                  failureMessage: _buildFailureMessage(),
                  submitButton: _buildSubmitButton(),
                ),
              ),
            ),
          ),
          const _LoginFooter(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        color: AppColors.loginText,
      ),
      decoration: _fieldDecoration(AppStrings.loginUsernameLabel),
      validator: (value) => value == null || value.trim().isEmpty
          ? AppStrings.loginEmailRequired
          : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        color: AppColors.loginText,
      ),
      decoration: _fieldDecoration(AppStrings.loginPasswordLabel),
      validator: (value) => value == null || value.isEmpty
          ? AppStrings.loginPasswordRequired
          : null,
    );
  }

  Widget _buildSessionIdField() {
    return TextFormField(
      controller: _sessionIdController,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 12,
        color: AppColors.loginText,
      ),
      decoration: _fieldDecoration(
        widget.requireSessionId
            ? AppStrings.loginSessionIdRequiredLabel
            : AppStrings.loginSessionIdLabel,
        helperText: widget.requireSessionId
            ? AppStrings.loginSessionIdRequiredHint
            : AppStrings.loginSessionIdHint,
      ),
      validator: (value) =>
          widget.requireSessionId && (value == null || value.trim().isEmpty)
          ? AppStrings.loginSessionIdRequired
          : null,
    );
  }

  InputDecoration _fieldDecoration(String label, {String? helperText}) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      helperStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        height: 1.25,
        color: AppColors.loginMutedText,
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.loginText,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.loginFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.loginFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 10,
        height: 1.2,
        color: AppColors.error,
      ),
    );
  }

  /// Uses [friendlyErrorMessage] rather than the generic
  /// [AppStrings.loginFailure] so a rate-limit/network/validation failure
  /// reads as what actually happened, not just "sign-in failed."
  Widget _buildFailureMessage() {
    return BlocSelector<AuthBloc, AuthState, AuthError?>(
      selector: (state) => state is AuthError ? state : null,
      builder: (context, errorState) {
        return errorState == null
            ? const SizedBox.shrink()
            : Text(friendlyErrorMessage(errorState.error));
      },
    );
  }

  Widget _buildSubmitButton() {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state is AuthAuthenticating,
      builder: (context, isLoading) {
        return PrimaryButton(
          label: AppStrings.loginSubmit,
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
    widget.onSessionIdProvided?.call(_sessionIdController.text.trim());
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailField,
    required this.passwordField,
    required this.sessionIdField,
    required this.failureMessage,
    required this.submitButton,
  });

  final GlobalKey<FormState> formKey;
  final Widget emailField;
  final Widget passwordField;
  final Widget sessionIdField;
  final Widget failureMessage;
  final Widget submitButton;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.loginBrand,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    height: 1.2,
                    color: AppColors.loginText,
                  ),
                ),
                const SizedBox(height: 28),
                emailField,
                const SizedBox(height: 17),
                passwordField,
                const SizedBox(height: 17),
                sessionIdField,
                const SizedBox(height: 8),
                failureMessage,
                const SizedBox(height: 10),
                SizedBox(height: 31, child: submitButton),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.loginHeaderBorder),
                const SizedBox(height: 12),
                const Text(
                  AppStrings.loginHelp,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    height: 1.45,
                    color: AppColors.loginMutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 27),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.loginHeaderBorder)),
      ),
      child: Row(
        children: [
          const Text(
            AppStrings.loginBrand,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.loginText,
            ),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.loginHeaderBorder,
          ),
          const Text(
            AppStrings.loginProduct,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppColors.loginMutedText,
            ),
          ),
          const Spacer(),
          const Text(
            AppStrings.loginHeaderSystem,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              color: AppColors.loginMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 27),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.loginHeaderBorder)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              AppStrings.loginFooterEnvironment,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                color: AppColors.loginText,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          const Expanded(
            child: Text(
              AppStrings.loginFooterCopyright,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                color: AppColors.loginMutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
