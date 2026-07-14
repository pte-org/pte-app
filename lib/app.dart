import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/listening/presentation/pages/listening/listening_test_runner_page.dart';
import 'package:aptis_app/core/config/app_config.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/network/dio_client.dart';
import 'package:aptis_app/core/network/token_store.dart';
import 'package:aptis_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aptis_app/features/auth/presentation/pages/auth_login_page.dart';
import 'package:aptis_app/features/home/presentation/pages/developer_home_page.dart';

import 'features/speaking/presentation/pages/speaking_page.dart';

class AptisApp extends StatelessWidget {
  const AptisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.brandAptis,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryLime),
      ),
      home: const DeveloperHomePage(),
    );
  }
}
