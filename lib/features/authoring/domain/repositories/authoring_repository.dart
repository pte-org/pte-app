import '../authoring_types.dart';
import '../blueprint_types.dart';

abstract class AuthoringRepository {
  Future<List<Question>> loadQuestions();

  Future<Question> createMcReadingSingle(CreateMcReadingSingleInput input);

  Future<Question> createReadAloud(CreateReadAloudInput input);

  Future<Question> createWriteEssay(CreateWriteEssayInput input);

  Future<List<Blueprint>> loadBlueprints();

  Future<Blueprint> loadBlueprint(String publicId);

  Future<Blueprint> createBlueprint(CreateBlueprintInput input);

  Future<ExamSnapshot> publishBlueprint(String publicId);

  Future<ExamSnapshot> loadSnapshot(String publicId);
}
