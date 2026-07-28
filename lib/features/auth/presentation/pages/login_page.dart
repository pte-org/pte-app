import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.loginFormMaxWidth,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildEmailField(),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildPasswordField(),
                  const SizedBox(height: AppDimensions.spacingMedium),
                  _buildFailureMessage(),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(labelText: AppStrings.loginEmailLabel),
      validator: (value) => value == null || value.trim().isEmpty
          ? AppStrings.loginEmailRequired
          : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: AppStrings.loginPasswordLabel,
      ),
      validator: (value) => value == null || value.isEmpty
          ? AppStrings.loginPasswordRequired
          : null,
    );
  }

  Widget _buildFailureMessage() {
    return BlocSelector<AuthBloc, AuthState, bool>(
      selector: (state) => state is AuthError,
      builder: (context, hasError) {
        return hasError
            ? const Text(AppStrings.loginFailure)
            : const SizedBox.shrink();
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
        );
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
