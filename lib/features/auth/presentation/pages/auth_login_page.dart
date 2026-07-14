import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/network/api_exceptions.dart';
import 'package:aptis_app/features/auth/domain/entities/auth_session.dart';
import 'package:aptis_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aptis_app/features/auth/presentation/widgets/candidate_login_card.dart';
import 'package:aptis_app/features/auth/presentation/widgets/login_shell_footer.dart';
import 'package:aptis_app/features/auth/presentation/widgets/login_shell_header.dart';

class AuthLoginPage extends StatefulWidget {
  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onLoginSuccess;

  const AuthLoginPage({
    super.key,
    required this.authRepository,
    required this.onLoginSuccess,
  });

  @override
  State<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends State<AuthLoginPage> {
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _accessKeyController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    _accessKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          const LoginShellHeader(),
          Container(
            height: AppDimensions.loginAccentHeight,
            color: AppColors.accentRed,
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: CandidateLoginCard(
                  credentialController: _credentialController,
                  passwordController: _passwordController,
                  accessKeyController: _accessKeyController,
                  isSubmitting: _isSubmitting,
                  obscurePassword: _obscurePassword,
                  errorMessage: _errorMessage,
                  onSubmit: _submitLogin,
                  onTogglePasswordVisibility:
                      _togglePasswordVisibility,
                ),
              ),
            ),
          ),
          const LoginShellFooter(),
        ],
      ),
    );
  }

  Future<void> _submitLogin() async {
    final credential = _credentialController.text.trim();
    final password = _passwordController.text;
    final validationMessage = _validateCredentials(credential, password);
    if (validationMessage != null) {
      setState(() => _errorMessage = validationMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.authRepository.login(
        credential: credential,
        password: password,
      );
      if (!mounted) return;
      if (!session.isStudent) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = AppStrings.loginStudentOnlyError;
        });
        return;
      }
      widget.onLoginSuccess(session);
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppStrings.loginGenericError;
      });
    }
  }

  String? _validateCredentials(String credential, String password) {
    if (credential.isEmpty) {
      return AppStrings.loginMissingAccount;
    }
    if (password.isEmpty) {
      return AppStrings.loginMissingPassword;
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
}
