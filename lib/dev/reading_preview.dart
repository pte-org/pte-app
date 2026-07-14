// Dev-only preview entrypoint for the Reading screens.
//
// Run:  flutter run -t lib/dev/reading_preview.dart -d chrome --web-port=8080
// This is NOT part of the production app (main.dart -> app.dart) and is safe to
// delete. The in-app Next/Back buttons walk R1 → R2 → R3 → R4.
import 'package:flutter/material.dart';
import 'package:aptis_app/features/reading/presentation/pages/gap_fill_message_page.dart';
import 'package:aptis_app/features/reading/presentation/pages/sentence_ordering_page.dart';
import 'package:aptis_app/features/reading/presentation/pages/word_bank_gap_fill_page.dart';
import 'package:aptis_app/features/reading/presentation/pages/heading_match_page.dart';

void main() => runApp(const _ReadingPreviewApp());

class _ReadingPreviewApp extends StatelessWidget {
  const _ReadingPreviewApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReadingWalkthrough(),
    );
  }
}

/// Holds R1–R4 in an [IndexedStack] (each keeps its answers) and wires each
/// screen's Next/Back to move the index.
class ReadingWalkthrough extends StatefulWidget {
  const ReadingWalkthrough({super.key});

  @override
  State<ReadingWalkthrough> createState() => _ReadingWalkthroughState();
}

class _ReadingWalkthroughState extends State<ReadingWalkthrough> {
  int _index = 0;

  void _next() {
    if (_index < _screens.length - 1) setState(() => _index++);
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  late final List<Widget> _screens = [
    GapFillMessagePage(onNext: _next),
    SentenceOrderingPage(onNext: _next, onBack: _back),
    WordBankGapFillPage(onNext: _next, onBack: _back),
    HeadingMatchPage(onNext: _next, onBack: _back),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: IndexedStack(index: _index, children: _screens));
  }
}
