import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Shown to a signed-in account without the student role, which has nothing
/// to do in the exam client; logging out returns to the sign-in form.
class ExamAccessDeniedPage extends StatelessWidget {
  const ExamAccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StatusScreen(
      icon: Icons.block,
      title: AppStrings.examAccessDeniedTitle,
      message: AppStrings.examAccessDeniedMessage,
      isError: true,
      children: [
        PrimaryButton(
          label: AppStrings.logout,
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
        ),
      ],
    );
  }
}
