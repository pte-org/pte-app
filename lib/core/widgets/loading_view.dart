import 'package:flutter/material.dart';

/// Full-body loading state — every screen's initial/in-flight load uses
/// this instead of an inline `Center(child: CircularProgressIndicator())`.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
