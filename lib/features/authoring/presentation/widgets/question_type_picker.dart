import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/authoring_types.dart';

class QuestionTypePicker extends StatelessWidget {
  const QuestionTypePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(title: Text(AppStrings.selectQuestionType)),
          _option(context, PteTaskType.mcReadingSingle),
          _option(context, PteTaskType.readAloud),
          _option(context, PteTaskType.writeEssay),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, PteTaskType type) {
    final label = switch (type) {
      PteTaskType.mcReadingSingle => AppStrings.mcReadingSingleLabel,
      PteTaskType.readAloud => AppStrings.readAloudLabel,
      PteTaskType.writeEssay => AppStrings.writeEssayLabel,
    };
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.of(context).pop(type),
    );
  }
}
