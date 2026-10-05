import 'package:pte_app/core/config/app_config.dart';
import 'package:pte_app/core/network/api_client.dart';
import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/features/exam_attempt/domain/repositories/session_entry_repository.dart';

/// Strict 8-4-4-4-12 hex form — anything looser would send a pasted code
/// down the UUID path and skip the resolve call.
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Hyphen look-alikes a keyboard or a copied chat message can produce
/// (hyphen, non-breaking hyphen, figure/en/em dash, horizontal bar, minus
/// sign, small and fullwidth hyphens).
final RegExp _unicodeHyphens = RegExp('[‐-―−﹘﹣－]');

final RegExp _whitespace = RegExp(r'\s+');

/// `rawInput` is what the student typed at login: either the exam code a
/// host shares (e.g. `FPT-261010-K7QM`) or, for backward compatibility, the
/// session UUID itself. A UUID is returned as-is without a network call;
/// a code is normalized to its one canonical form (no whitespace, ASCII
/// hyphens, uppercase) and exchanged for the session UUID by the
/// authenticated `resolve` endpoint. Codes typed without hyphens are not
/// reconstructed.
class ExamCodeSessionEntryRepository implements SessionEntryRepository {
  ExamCodeSessionEntryRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<String> resolveSessionPublicId(String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      throw const SessionResolutionException('Exam code cannot be empty.');
    }
    if (_uuidPattern.hasMatch(trimmed)) return trimmed;

    final code = trimmed
        .replaceAll(_whitespace, '')
        .replaceAll(_unicodeHyphens, '-')
        .toUpperCase();
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        AppConfig.sessionCodeResolvePath,
        queryParameters: {'code': code},
      );
      return response.data!['sessionPublicId'] as String;
    } on NotFoundException {
      throw const SessionResolutionException(_codeNotFoundMessage);
    } on ValidationException {
      // 400 `INVALID_SESSION_CODE`: the input is longer than any generated
      // code — for the student that is the same "wrong code" as a 404.
      throw const SessionResolutionException(_codeNotFoundMessage);
    }
  }

  static const String _codeNotFoundMessage =
      "We couldn't find that exam code. Check the code from your host and try again.";
}
