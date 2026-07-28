import '../../../../core/network/api_client.dart';
import '../../domain/authoring_types.dart';
import '../../domain/repositories/authoring_repository.dart';
import '../models/question_model.dart';

class AuthoringRepositoryImpl implements AuthoringRepository {
  AuthoringRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  static const _questionsPath = '/api/authoring/questions';

  final ApiClient _apiClient;

  @override
  Future<List<Question>> loadQuestions() async {
    final response = await _apiClient.get<List<dynamic>>(_questionsPath);
    return (response.data ?? const [])
        .map(
          (item) =>
              QuestionModel.fromJson(item as Map<String, dynamic>).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<Question> createMcReadingSingle(
    CreateMcReadingSingleInput input,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _questionsPath,
      data: {
        'pteTaskType': PteTaskType.mcReadingSingle.wireName,
        'visibility': QuestionVisibility.private.wireName,
        'title': input.title,
        'promptText': input.promptText,
        'options': input.options
            .map(
              (option) => {
                'text': option.text,
                'correct': option.correct,
                'orderIndex': option.orderIndex,
              },
            )
            .toList(growable: false),
      },
    );
    return QuestionModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<Question> createReadAloud(CreateReadAloudInput input) async {
    return _createQuestion({
      'pteTaskType': PteTaskType.readAloud.wireName,
      'visibility': QuestionVisibility.private.wireName,
      'title': input.title,
      'promptText': input.promptText,
    });
  }

  @override
  Future<Question> createWriteEssay(CreateWriteEssayInput input) async {
    return _createQuestion({
      'pteTaskType': PteTaskType.writeEssay.wireName,
      'visibility': QuestionVisibility.private.wireName,
      'title': input.title,
      'promptText': input.promptText,
      'referenceAnswerText': input.referenceAnswerText,
      'minWordCount': input.minWordCount,
      'maxWordCount': input.maxWordCount,
    });
  }

  Future<Question> _createQuestion(Map<String, dynamic> payload) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _questionsPath,
      data: payload,
    );
    return QuestionModel.fromJson(response.data!).toEntity();
  }
}
