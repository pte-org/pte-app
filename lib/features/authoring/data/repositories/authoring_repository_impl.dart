import '../../../../core/network/api_client.dart';
import '../../domain/authoring_types.dart';
import '../../domain/blueprint_types.dart';
import '../../domain/repositories/authoring_repository.dart';
import '../models/blueprint_models.dart';
import '../models/question_model.dart';

class AuthoringRepositoryImpl implements AuthoringRepository {
  AuthoringRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  static const _questionsPath = '/api/authoring/questions';
  static const _blueprintsPath = '/api/authoring/blueprints';

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

  @override
  Future<List<Blueprint>> loadBlueprints() async {
    final response = await _apiClient.get<List<dynamic>>(_blueprintsPath);
    return (response.data ?? const [])
        .map(
          (item) =>
              BlueprintModel.fromJson(item as Map<String, dynamic>).toEntity(),
        )
        .toList(growable: false);
  }

  @override
  Future<Blueprint> loadBlueprint(String publicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '$_blueprintsPath/$publicId',
    );
    return BlueprintModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<Blueprint> createBlueprint(CreateBlueprintInput input) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      _blueprintsPath,
      data: {
        'name': input.name,
        'items': input.items
            .map(
              (item) => {
                'questionPublicId': item.questionPublicId,
                'section': item.section,
                'orderIndex': item.orderIndex,
              },
            )
            .toList(growable: false),
      },
    );
    return BlueprintModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ExamSnapshot> publishBlueprint(String publicId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_blueprintsPath/$publicId/publish',
    );
    return SnapshotModel.fromJson(response.data!).toEntity();
  }

  @override
  Future<ExamSnapshot> loadSnapshot(String publicId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/authoring/snapshots/$publicId',
    );
    return SnapshotModel.fromJson(response.data!).toEntity();
  }
}
