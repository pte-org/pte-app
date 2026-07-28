import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/authoring_types.dart';
import '../bloc/create_read_aloud_bloc.dart';
import '../bloc/create_question_bloc.dart';
import '../bloc/create_write_essay_bloc.dart';
import '../bloc/question_list_bloc.dart';
import '../bloc/question_list_event.dart';
import '../bloc/question_list_state.dart';
import '../widgets/question_card.dart';
import '../widgets/question_type_picker.dart';
import 'create_mc_reading_single_page.dart';
import 'create_read_aloud_page.dart';
import 'create_write_essay_page.dart';

class QuestionListPage extends StatelessWidget {
  const QuestionListPage({super.key, this.questionListBloc});

  final QuestionListBloc? questionListBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuestionListBloc>(
      create: (_) =>
          (questionListBloc ?? GetIt.instance<QuestionListBloc>())
            ..add(const QuestionListRequested()),
      child: const _QuestionListView(),
    );
  }
}

class _QuestionListView extends StatelessWidget {
  const _QuestionListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.questionsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreatePage(context),
        label: const Text(AppStrings.createQuestion),
        icon: const Icon(Icons.add),
      ),
      body: BlocBuilder<QuestionListBloc, QuestionListState>(
        builder: (context, state) {
          return switch (state) {
            QuestionListInitial() ||
            QuestionListLoading() => const LoadingView(),
            QuestionListEmpty() => const Center(
              child: Text(AppStrings.questionsEmpty),
            ),
            QuestionListFailure() => _QuestionListFailureView(
              onRetry: () => context.read<QuestionListBloc>().add(
                const QuestionListRetryRequested(),
              ),
            ),
            QuestionListLoaded(:final questions) => _QuestionList(
              questions: questions,
            ),
          };
        },
      ),
    );
  }

  Future<void> _openCreatePage(BuildContext context) async {
    final type = await showModalBottomSheet<PteTaskType>(
      context: context,
      builder: (_) => const QuestionTypePicker(),
    );
    if (!context.mounted || type == null) {
      return;
    }
    final created = await Navigator.of(
      context,
    ).push<Question>(MaterialPageRoute(builder: (_) => _createPage(type)));
    if (!context.mounted || created == null) {
      return;
    }
    context.read<QuestionListBloc>().add(const QuestionListRequested());
  }

  Widget _createPage(PteTaskType type) {
    return switch (type) {
      PteTaskType.mcReadingSingle => BlocProvider<CreateQuestionBloc>(
        create: (_) => GetIt.instance<CreateQuestionBloc>(),
        child: const CreateMcReadingSinglePage(),
      ),
      PteTaskType.readAloud => BlocProvider<CreateReadAloudBloc>(
        create: (_) => GetIt.instance<CreateReadAloudBloc>(),
        child: const CreateReadAloudPage(),
      ),
      PteTaskType.writeEssay => BlocProvider<CreateWriteEssayBloc>(
        create: (_) => GetIt.instance<CreateWriteEssayBloc>(),
        child: const CreateWriteEssayPage(),
      ),
    };
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingMedium),
      itemCount: questions.length,
      itemBuilder: (_, index) => QuestionCard(
        key: ValueKey(questions[index].publicId),
        question: questions[index],
      ),
    );
  }
}

class _QuestionListFailureView extends StatelessWidget {
  const _QuestionListFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppStrings.questionsLoadFailure),
          const SizedBox(height: AppDimensions.spacingMedium),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}
