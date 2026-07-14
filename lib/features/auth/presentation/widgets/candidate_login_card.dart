import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/ui/aptis_text_field.dart';
import 'package:aptis_app/core/widgets/ui/aptis_button.dart';

class CandidateLoginCard extends StatelessWidget {
  final TextEditingController credentialController;
  final TextEditingController passwordController;
  final TextEditingController accessKeyController;
  final bool isSubmitting;
  final bool obscurePassword;
  final String? errorMessage;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;

  const CandidateLoginCard({
    super.key,
    required this.credentialController,
    required this.passwordController,
    required this.accessKeyController,
    required this.isSubmitting,
    required this.obscurePassword,
    required this.errorMessage,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.loginFormWidth,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.loginPanelBorder),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.loginFormPaddingHorizontal,
        vertical: AppDimensions.loginFormPaddingVertical,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LoginCardHeader(),
          const SizedBox(height: AppDimensions.loginFormGap),
          _LoginCardFields(
            credentialController: credentialController,
            passwordController: passwordController,
            accessKeyController: accessKeyController,
            obscurePassword: obscurePassword,
            onSubmit: onSubmit,
            onTogglePasswordVisibility: onTogglePasswordVisibility,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: AppDimensions.loginFormGap),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.loginSubtitle.copyWith(
                color: AppColors.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingMedium),
          AptisButton(
            text: AppStrings.loginButton,
            isSubmitting: isSubmitting,
            onSubmit: onSubmit,
            icon: Icons.chevron_right,
          ),
          const SizedBox(height: AppDimensions.spacingMedium),
          const _InternetSupportLabel(),
        ],
      ),
    );
  }
}

class _LoginCardHeader extends StatelessWidget {
  const _LoginCardHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.loginCandidateTitle,
          style: AppTextStyles.loginTitle,
        ),
        SizedBox(height: AppDimensions.spacingXs),
        Text(
          AppStrings.loginCandidateSubtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.loginSubtitle,
        ),
      ],
    );
  }
}

class _LoginCardFields extends StatelessWidget {
  final TextEditingController credentialController;
  final TextEditingController passwordController;
  final TextEditingController accessKeyController;
  final bool obscurePassword;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePasswordVisibility;

  const _LoginCardFields({
    required this.credentialController,
    required this.passwordController,
    required this.accessKeyController,
    required this.obscurePassword,
    required this.onSubmit,
    required this.onTogglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AptisTextField(
          label: AppStrings.loginAccountLabel,
          hintText: AppStrings.loginAccountHint,
          controller: credentialController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppDimensions.loginFormGap),
        AptisTextField(
          label: AppStrings.loginPasswordLabel,
          hintText: AppStrings.loginPasswordHint,
          controller: passwordController,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            onPressed: onTogglePasswordVisibility,
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
              size: AppDimensions.loginHeaderIconSize,
              color: AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.loginFormGap),
        AptisTextField(
          label: AppStrings.loginAccessKeyLabel,
          hintText: AppStrings.loginAccessKeyHint,
          controller: accessKeyController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          suffixIcon: const Icon(
            Icons.visibility,
            size: AppDimensions.loginHeaderIconSize,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}

class _InternetSupportLabel extends StatelessWidget {
  const _InternetSupportLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.support_agent,
          size: AppDimensions.loginSupportIconSize,
          color: AppColors.logoGray,
        ),
        SizedBox(width: AppDimensions.loginSupportGap),
        Text(AppStrings.loginInternetSupport, style: AppTextStyles.loginFooter),
      ],
    );
  }
}
