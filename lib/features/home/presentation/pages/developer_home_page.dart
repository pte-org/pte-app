import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/brand_logo.dart';
import 'package:aptis_app/core/widgets/ui/aptis_button.dart';
import 'package:aptis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aptis_app/core/network/dio_client.dart';
import 'package:aptis_app/core/network/token_store.dart';
import 'package:aptis_app/core/config/app_config.dart';
import 'package:aptis_app/features/auth/presentation/pages/auth_login_page.dart';
import 'package:aptis_app/features/speaking/presentation/pages/speaking_page.dart';
import 'package:aptis_app/features/listening/presentation/pages/listening/listening_test_runner_page.dart';

class DeveloperHomePage extends StatelessWidget {
  const DeveloperHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            height: AppDimensions.loginHeaderHeight,
            color: AppColors.topBarBackground,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.loginHeaderPaddingHorizontal,
            ),
            child: Row(
              children: [
                const BrandLogo(),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textMedium,
                    size: AppDimensions.loginHeaderIconSize,
                  ),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
          // Accent red line
          Container(
            height: AppDimensions.loginAccentHeight,
            color: AppColors.accentRed,
          ),
          // Body
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingLarge),
                child: Container(
                  width: 520,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    border: Border.all(color: AppColors.loginPanelBorder),
                  ),
                  padding: const EdgeInsets.all(AppDimensions.loginFormPaddingHorizontal),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Developer Hub',
                        style: AppTextStyles.loginTitle,
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      const Text(
                        'Select a feature screen below to start previewing and testing during development.',
                        style: AppTextStyles.loginSubtitle,
                      ),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      
                      // Speaking module card
                      _FeatureCard(
                        title: 'Speaking Exam Module',
                        description: 'Aptis Speaking test interface with microphone recorder mockups and resizable viewport shell.',
                        icon: Icons.mic,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const SpeakingPage()),
                          );
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingMedium),
                      
                      // Listening module card
                      _FeatureCard(
                        title: 'Listening Exam Module',
                        description: 'Aptis Listening test interface with custom audio player, matching dropdowns and multiple choice questions.',
                        icon: Icons.headset,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ListeningTestRunnerPage()),
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppDimensions.spacingXl),
                      
                      // Logout action
                      AptisButton(
                        text: 'BACK TO CANDIDATE LOGIN',
                        isSubmitting: false,
                        onSubmit: () => _handleLogout(context),
                        color: AppColors.dividerGray,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Footer
          Container(
            height: AppDimensions.loginFooterHeight,
            color: AppColors.loginFooterBackground,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.loginFooterPaddingHorizontal,
            ),
            alignment: Alignment.center,
            child: const Row(
              children: [
                Text(AppStrings.loginCopyright, style: AppTextStyles.loginFooter),
                Spacer(),
                Text('Developer Preview Mode', style: AppTextStyles.loginFooter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AuthLoginPage(
          authRepository: AuthRepositoryImpl(
            dio: createDio(const AppConfig()),
            tokenStore: InMemoryTokenStore(),
          ),
          onLoginSuccess: (_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const DeveloperHomePage()),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.loginPanelBorder),
      ),
      color: AppColors.backgroundLight.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: AppColors.accentRed,
                size: 28,
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.loginLabel.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXs),
                    Text(
                      description,
                      style: AppTextStyles.loginSubtitle.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingSmall),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.logoGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
