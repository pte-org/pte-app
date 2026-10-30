import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/auth/domain/exam_access_policy.dart';
import 'package:pte_app/features/auth/domain/jwt_claims.dart';

void main() {
  test('a student account may take an exam', () {
    expect(
      ExamAccessPolicy.canTakeExam(const JwtClaims(roles: ['STUDENT'])),
      isTrue,
    );
  });

  test('a host admin account may enter read-only preview', () {
    expect(
      ExamAccessPolicy.canPreviewExam(const JwtClaims(roles: ['HOST_ADMIN'])),
      isTrue,
    );
  });

  test('host preview wins for a multi-role account', () {
    const claims = JwtClaims(roles: ['HOST_ADMIN', 'STUDENT']);
    expect(ExamAccessPolicy.canPreviewExam(claims), isTrue);
    expect(ExamAccessPolicy.canTakeExam(claims), isTrue);
  });

  for (final roles in <List<String>>[
    ['HOST_AUTHOR'],
    ['PROCTOR'],
    ['EXAMINER'],
    ['PLATFORM_ADMIN'],
    ['STUDENT'],
    [],
  ]) {
    test('roles $roles may not enter host preview', () {
      expect(ExamAccessPolicy.canPreviewExam(JwtClaims(roles: roles)), isFalse);
    });
  }

  for (final roles in <List<String>>[
    ['HOST_ADMIN'],
    ['HOST_AUTHOR'],
    ['PROCTOR'],
    ['EXAMINER'],
    ['PLATFORM_ADMIN'],
    ['student'],
    [],
  ]) {
    test('roles $roles may not take an exam', () {
      expect(ExamAccessPolicy.canTakeExam(JwtClaims(roles: roles)), isFalse);
    });
  }
}
