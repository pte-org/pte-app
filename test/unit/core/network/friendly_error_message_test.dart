import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/network/api_exceptions.dart';
import 'package:pte_app/core/network/friendly_error_message.dart';

void main() {
  group('friendlyErrorMessage', () {
    test('ALREADY_ATTEMPTED conflict gets a specific, non-technical sentence', () {
      const error = ConflictException('ALREADY_ATTEMPTED');
      expect(friendlyErrorMessage(error), contains("already used this session ID"));
      expect(friendlyErrorMessage(error), isNot(contains('ConflictException')));
    });

    test('a generic ConflictException falls back to a generic conflict sentence', () {
      const error = ConflictException('SOME_OTHER_CODE');
      expect(friendlyErrorMessage(error), 'That action conflicts with the current state. Please try again.');
    });

    test('ResponseWindowExpiredException gets its own sentence', () {
      const error = ResponseWindowExpiredException('RESPONSE_WINDOW_EXPIRED');
      expect(friendlyErrorMessage(error), contains('Time ran out'));
    });

    test('NotCurrentTaskException gets its own sentence', () {
      const error = NotCurrentTaskException('NOT_CURRENT_TASK');
      expect(friendlyErrorMessage(error), contains("isn't current anymore"));
    });

    test('AuthException prompts a re-login', () {
      const error = AuthException('Authentication failed (401)');
      expect(friendlyErrorMessage(error), contains('log in again'));
    });

    test('NetworkException prompts a connectivity check', () {
      const error = NetworkException('connection refused');
      expect(friendlyErrorMessage(error), contains("Couldn't reach the server"));
    });

    test('a non-ApiException falls back to its own toString, unchanged', () {
      final error = Exception('plain exception');
      expect(friendlyErrorMessage(error), error.toString());
    });
  });
}
