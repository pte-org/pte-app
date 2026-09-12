import 'package:flutter/material.dart';

import 'package:pte_app/core/constants/app_colors.dart';
import 'package:pte_app/core/constants/app_dimensions.dart';
import 'package:pte_app/core/constants/exam_chrome_config.dart';
import 'package:pte_app/core/widgets/exam/exam_footer_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_header_bar.dart';
import 'package:pte_app/core/widgets/exam/exam_shell.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_catalog.dart';
import 'package:pte_app/features/exam_attempt/dev/exam_ui_preview_task_body.dart';
import 'package:pte_app/features/exam_attempt/presentation/model/exam_task_ui_model.dart';

/// Visual-only offline catalog. It uses the same presentation models as the
/// runtime adapter but intentionally has no API, microphone, cubit, outbox or
/// force-submit dependency.
class ExamUiPreviewScreen extends StatefulWidget {
  const ExamUiPreviewScreen({super.key});

  @override
  State<ExamUiPreviewScreen> createState() => _ExamUiPreviewScreenState();
}

class _ExamUiPreviewScreenState extends State<ExamUiPreviewScreen> {
  ExamTaskUiModel? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam UI design preview')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingMd),
          child: Column(
            children: [
              for (final model in ExamUiPreviewCatalog.models) ...[
                ListTile(
                  tileColor: AppColors.surface,
                  title: Text(model.meta.title),
                  subtitle: Text(
                    '${model.taskType} · ${model.meta.family.name} · ${model.origin.name}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selected = model),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
              ],
            ],
          ),
        ),
      );
    }

    final index = ExamUiPreviewCatalog.models.indexOf(selected);
    return ExamShell(
      header: ExamHeaderBar(
        examTitle: ExamChromeConfig.defaultExamTitle,
        candidateName: 'Preview candidate',
        candidateId: 'Offline fixture',
        itemLabel: 'Item ${index + 1} of ${ExamUiPreviewCatalog.models.length}',
        timeLabel: '20:00',
      ),
      body: ExamUiPreviewTaskBody(model: selected),
      footer: ExamFooterBar(
        onSaveAndExit: () => setState(() => _selected = null),
        onNext: () {
          final next = (index + 1) % ExamUiPreviewCatalog.models.length;
          setState(() => _selected = ExamUiPreviewCatalog.models[next]);
        },
      ),
    );
  }
}
