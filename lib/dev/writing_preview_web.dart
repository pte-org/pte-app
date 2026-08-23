import 'package:flutter/material.dart';

import '../../features/exam_attempt/dev/writing_task_fixtures.dart';
import '../../features/exam_attempt/domain/task_view.dart';
import '../../features/exam_attempt/presentation/widgets/summarize_written_text_body.dart';
import '../../features/exam_attempt/presentation/widgets/write_essay_v2_body.dart';

/// Chrome-only dev entry for the writing tasks. Mounts the pure UI bodies
/// ([SummarizeWrittenTextBody] / [WriteEssayV2Body]) directly so the build
/// never reaches `ExamScaffold` → `ExamAppBar` → `ExamAttemptBloc` →
/// `AnswerOutboxDao` → `package:sqlite3`, whose `external` FFI symbols
/// can't compile to JS. The production screens (which wrap the same body
/// in `ExamScaffold`) are still wired through the dispatcher for native
/// runtime.
///
/// Run via:  flutter run -t lib/dev/writing_preview_web.dart -d chrome
void main() {
  runApp(const MaterialApp(home: WritingPreviewWeb()));
}

class WritingPreviewWeb extends StatefulWidget {
  const WritingPreviewWeb({super.key});

  @override
  State<WritingPreviewWeb> createState() => _WritingPreviewWebState();
}

class _WritingPreviewWebState extends State<WritingPreviewWeb> {
  static const List<_Entry> _entries = [
    _Entry(label: 'Summarize Written Text', index: 0),
    _Entry(label: 'Write Essay', index: 1),
  ];

  int _index = 0;

  TaskView _summarizeTask() {
    final now = DateTime.now().toUtc();
    return TaskView(
      pinnedItemPublicId: 'swt-1',
      orderIndex: 1,
      totalTasks: 2,
      section: 'WRITING',
      taskType: 'SUMMARIZE_WRITTEN_TEXT',
      title: 'Summarize Written Text',
      promptText: kSummarizeWrittenTextPassage,
      minWordCount: int.parse(kSummarizeWrittenTextMinWords),
      maxWordCount: int.parse(kSummarizeWrittenTextMaxWords),
      prepSeconds: 0,
      responseSeconds: kSummarizeWrittenTextDurationSeconds,
      prepDeadline: now,
      responseDeadline: now.add(const Duration(minutes: 10)),
      serverNow: now,
    );
  }

  TaskView _writeEssayTask() {
    final now = DateTime.now().toUtc();
    return TaskView(
      pinnedItemPublicId: 'we-2',
      orderIndex: 2,
      totalTasks: 2,
      section: 'WRITING',
      taskType: 'WRITE_ESSAY_V2',
      title: 'Write Essay',
      promptText: kWriteEssayPrompt,
      minWordCount: int.parse(kWriteEssayMinWords),
      maxWordCount: int.parse(kWriteEssayMaxWords),
      prepSeconds: 0,
      responseSeconds: kWriteEssayDurationSeconds,
      prepDeadline: now,
      responseDeadline: now.add(const Duration(minutes: 20)),
      serverNow: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_entries[_index].label),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _index == 0 ? null : () => setState(() => _index -= 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _index == _entries.length - 1 ? null : () => setState(() => _index += 1),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          SummarizeWrittenTextBody(task: _summarizeTask()),
          WriteEssayV2Body(task: _writeEssayTask()),
        ],
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.label, required this.index});

  final String label;
  final int index;
}
