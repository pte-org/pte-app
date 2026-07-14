import 'package:flutter/material.dart';
import 'package:aptis_app/core/constants/app_colors.dart';
import 'package:aptis_app/core/constants/app_dimensions.dart';
import 'package:aptis_app/core/constants/app_strings.dart';
import 'package:aptis_app/core/constants/app_text_styles.dart';
import 'package:aptis_app/core/widgets/exam/exam_scaffold.dart';

const int _defaultCurrentScreen = 2;
const int _defaultTotalScreens = 4;
const Duration _defaultTimeRemaining = Duration(minutes: 33);

class SentenceOrderingPage extends StatefulWidget {
  final int currentScreen;
  final int totalScreens;
  final Duration timeRemaining;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onFlag;

  const SentenceOrderingPage({
    super.key,
    this.currentScreen = _defaultCurrentScreen,
    this.totalScreens = _defaultTotalScreens,
    this.timeRemaining = _defaultTimeRemaining,
    this.onNext,
    this.onBack,
    this.onFlag,
  });

  @override
  State<SentenceOrderingPage> createState() => _SentenceOrderingPageState();
}

class _SentenceOrderingPageState extends State<SentenceOrderingPage> {
  // TODO(sample-data): replace with data from a Reading Question entity once it
  // exists; wiring to a bloc/backend is deferred.
  late final List<String> _order;

  @override
  void initState() {
    super.initState();
    _order = List<String>.of(AppStrings.readingOrderingSentences);
  }

  // onReorderItem gives a newIndex already adjusted for the removed item.
  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      _order.insert(newIndex, _order.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExamScaffold(
      currentScreen: widget.currentScreen,
      totalScreens: widget.totalScreens,
      timeRemaining: widget.timeRemaining,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(),
      onFlag: widget.onFlag ?? () {},
      onNext: widget.onNext ?? () {},
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.readingOrderingInstruction,
          style: AppTextStyles.instructionBold,
        ),
        const SizedBox(height: AppDimensions.readingMessageBlockGap),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          header: const _SentenceTile(
            text: AppStrings.readingOrderingExample,
            isExample: true,
          ),
          onReorderItem: _onReorderItem,
          children: [
            for (final sentence in _order)
              _SentenceTile(key: ValueKey(sentence), text: sentence),
          ],
        ),
      ],
    );
  }
}

class _SentenceTile extends StatelessWidget {
  final String text;
  final bool isExample;

  const _SentenceTile({super.key, required this.text, this.isExample = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.readingTileGap),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.readingTilePaddingH,
          vertical: AppDimensions.readingTilePaddingV,
        ),
        decoration: BoxDecoration(
          color: isExample
              ? AppColors.readingExampleTile
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.readingTileRadius),
          boxShadow: const [
            BoxShadow(
              color: AppColors.radioShadow,
              blurRadius: AppDimensions.radioShadowBlur,
              offset: Offset(0, AppDimensions.radioShadowOffsetY),
            ),
          ],
        ),
        child: Text(text, style: AppTextStyles.sentenceText),
      ),
    );
  }
}
