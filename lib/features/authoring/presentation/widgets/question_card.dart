import 'package:flutter/material.dart';

import '../../domain/authoring_types.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(question.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.pteTaskType.wireName),
            Text(question.visibility.wireName),
            Text(question.status),
          ],
        ),
      ),
    );
  }
}
