import '../authoring_types.dart';

abstract class AuthoringRepository {
  Future<List<Question>> loadQuestions();

  Future<Question> createMcReadingSingle(CreateMcReadingSingleInput input);

  Future<Question> createReadAloud(CreateReadAloudInput input);

  Future<Question> createWriteEssay(CreateWriteEssayInput input);
}
