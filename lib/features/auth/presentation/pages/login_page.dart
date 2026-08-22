import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Mirrors `SessionEntryPage`'s shape (phase-01 Design Constraints): a
/// dumb form that only dispatches [LoginRequested] and renders whatever
/// [AuthState] the bloc is in — no local success/failure branching here,
/// that belongs to whatever widget is above this one in the tree (the
/// `AuthGate` in `main.dart`) once `AuthAuthenticated` is reached.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.loginTitle)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error.toString())));
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMedium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: AppStrings.loginEmailFieldLabel),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: AppStrings.loginPasswordFieldLabel),
                  obscureText: true,
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                PrimaryButton(
                  label: AppStrings.loginButtonLabel,
                  isLoading: state is AuthAuthenticating,
                  onPressed: () => context.read<AuthBloc>().add(
                    LoginRequested(email: _emailController.text, password: _passwordController.text),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
