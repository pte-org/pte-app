import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';

void main() {
  runApp(const PteApp());
}

class PteApp extends StatelessWidget {
  const PteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: AppStrings.appTitle,
      home: Scaffold(body: Center(child: Text(AppStrings.appTitle))),
    );
  }
}
