import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';

const int _fixedGapIndex = 0;

/// A passage with drop-in gaps plus a bank of draggable word tiles. Drag a tile
/// from the bank into a gap to fill it; drag a filled gap's word out (or onto
/// another gap) to move it. The first gap is pre-filled and fixed.
class WordBankGapFill extends StatefulWidget {
  final String title;
  final List<String> segments; // length == gapCount + 1
  final int gapCount;
  final List<String> tiles;
  final String fixedAnswer;

  const WordBankGapFill({
    super.key,
    required this.title,
    required this.segments,
    required this.gapCount,
    required this.tiles,
    required this.fixedAnswer,
  });

  @override
  State<WordBankGapFill> createState() => _WordBankGapFillState();
}

class _WordBankGapFillState extends State<WordBankGapFill> {
  late final Map<int, String?> _gaps;
  late final List<String> _bank;

  @override
  void initState() {
    super.initState();
    _gaps = {for (int i = 0; i < widget.gapCount; i++) i: null};
    _gaps[_fixedGapIndex] = widget.fixedAnswer;
    _bank = List<String>.of(widget.tiles);
  }

  void _place(int index, String word) {
    setState(() {
      final existing = _gaps[index];
      if (existing != null) _bank.add(existing);
      _gaps[index] = word;
      _bank.remove(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text(widget.title, style: AppTextStyles.readingTitle)),
        const SizedBox(height: AppDimensions.readingPassageTitleGap),
        _buildPassage(),
        const SizedBox(height: AppDimensions.readingMessageBlockGap),
        _buildBank(),
      ],
    );
  }

  Widget _buildPassage() {
    final spans = <InlineSpan>[];
    for (int i = 0; i < widget.segments.length; i++) {
      spans.add(TextSpan(text: widget.segments[i]));
      if (i < widget.gapCount) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildGap(i),
          ),
        );
      }
    }
    return Text.rich(
      TextSpan(style: AppTextStyles.sentenceText, children: spans),
    );
  }

  Widget _buildGap(int index) {
    final word = _gaps[index];
    if (index == _fixedGapIndex) {
      return _GapBox(filled: true, child: _label(word!));
    }
    return DragTarget<String>(
      onAcceptWithDetails: (details) => _place(index, details.data),
      builder: (context, candidate, rejected) {
        if (word == null) {
          return _GapBox(highlighted: candidate.isNotEmpty);
        }
        return Draggable<String>(
          data: word,
          feedback: WordTile(word: word),
          childWhenDragging: const _GapBox(),
          onDragStarted: () => setState(() => _gaps[index] = null),
          onDraggableCanceled: (_, _) => setState(() => _bank.add(word)),
          child: _GapBox(filled: true, child: _label(word)),
        );
      },
    );
  }

  Widget _buildBank() {
    return Wrap(
      spacing: AppDimensions.readingTileGap,
      runSpacing: AppDimensions.readingTileGap,
      children: [
        for (final word in _bank)
          Draggable<String>(
            key: ValueKey(word),
            data: word,
            feedback: WordTile(word: word),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: WordTile(word: word),
            ),
            child: WordTile(word: word),
          ),
      ],
    );
  }

  Widget _label(String word) => Text(word, style: AppTextStyles.sentenceText);
}

/// A raised word tile used in the bank and as drag feedback.
class WordTile extends StatelessWidget {
  final String word;

  const WordTile({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.readingTilePaddingH,
          vertical: AppDimensions.readingTilePaddingV,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.readingTileRadius),
          border: Border.all(
            color: AppColors.dropdownBorder,
            width: AppDimensions.borderWidthThin,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.radioShadow,
              blurRadius: AppDimensions.radioShadowBlur,
              offset: Offset(0, AppDimensions.radioShadowOffsetY),
            ),
          ],
        ),
        child: Text(word, style: AppTextStyles.sentenceText),
      ),
    );
  }
}

class _GapBox extends StatelessWidget {
  final bool filled;
  final bool highlighted;
  final Widget? child;

  const _GapBox({this.filled = false, this.highlighted = false, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.readingGapSlotWidth,
      height: AppDimensions.readingGapSlotHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? AppColors.exampleValueBackground
            : AppColors.backgroundWhite,
        border: Border.all(
          color: highlighted
              ? AppColors.readingGapHighlight
              : AppColors.dropdownBorder,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: child,
    );
  }
}
