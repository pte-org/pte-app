// Dev-only preview entrypoint for the Core (Grammar & Vocabulary) screens.
//
// Run:  flutter run -t lib/dev/core_test_preview.dart -d chrome
// This is NOT part of the production app (main.dart -> app.dart) and is safe
// to delete. It chains the built screens so the in-app Next/Back buttons walk
// the review set Q1 -> Q26 -> Q27 -> Q28 -> Q30.
import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/features/core_test/presentation/pages/grammar_mcq_page.dart';
import 'package:aptis_app/features/core_test/presentation/pages/word_match_page.dart';
import 'package:aptis_app/features/core_test/presentation/pages/sentence_completion_page.dart';

void main() => runApp(const _CoreTestPreviewApp());

class _CoreTestPreviewApp extends StatelessWidget {
  const _CoreTestPreviewApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CoreTestWalkthrough(),
    );
  }
}

/// Renders the ordered review set in an [IndexedStack] (so each screen keeps
/// its answers) and wires each screen's Next/Back to move the index.
class CoreTestWalkthrough extends StatefulWidget {
  const CoreTestWalkthrough({super.key});

  @override
  State<CoreTestWalkthrough> createState() => _CoreTestWalkthroughState();
}

class _CoreTestWalkthroughState extends State<CoreTestWalkthrough> {
  int _index = 0;

  void _next() {
    if (_index < _screens.length - 1) setState(() => _index++);
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  late final List<Widget> _screens = [
    GrammarMcqPage(onNext: _next),
    WordMatchPage(currentScreen: 26, onNext: _next, onBack: _back),
    WordMatchPage(
      currentScreen: 27,
      instruction: AppStrings.definitionMatchInstruction,
      words: AppStrings.definitionPrompts,
      optionsList: AppStrings.definitionOptions,
      leftAligned: true,
      onNext: _next,
      onBack: _back,
    ),
    SentenceCompletionPage(onNext: _next, onBack: _back),
    WordMatchPage(
      currentScreen: 30,
      instruction: AppStrings.collocationInstruction,
      words: AppStrings.collocationWords,
      optionsList: AppStrings.collocationOptions,
      onNext: _next,
      onBack: _back,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: IndexedStack(index: _index, children: _screens));
  }
}
