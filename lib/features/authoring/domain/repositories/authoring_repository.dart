import '../authoring_types.dart';

abstract class AuthoringRepository {
  Future<List<Question>> loadQuestions();

  Future<Question> createMcReadingSingle(CreateMcReadingSingleInput input);
}
