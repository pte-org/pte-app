import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';

/// Side-by-side passage + interactive-content layout above
/// [AppDimensions.readingPassageLayoutBreakpoint], stacked (scrollable
/// column) below it. Used by task types with a genuinely separate
/// passage/options split (`MC_READING_SINGLE`, `MC_READING_MULTIPLE`) — not
/// by `RE_ORDER_PARAGRAPHS` or either fill-blanks type, which render a
/// single scrollable column instead since they have no separate options
/// pane.
class ReadingPassageLayout extends StatelessWidget {
  const ReadingPassageLayout({super.key, required this.passage, required this.interactive});

  final Widget passage;
  final Widget interactive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.readingPassageLayoutBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsets.all(AppDimensions.spacingMedium), child: passage),
              ),
              Expanded(child: interactive),
            ],
          );
        }
        return Column(
          children: [
            Padding(padding: const EdgeInsets.all(AppDimensions.spacingMedium), child: passage),
            Expanded(child: interactive),
          ],
        );
      },
    );
  }
}
