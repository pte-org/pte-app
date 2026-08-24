import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/live_proctor/domain/live_proctor_access_policy.dart';

void main() {
  test('role matrix matches the approved live-console policy', () {
    const proctor = JwtClaims(roles: ['PROCTOR']);
    const admin = JwtClaims(roles: ['HOST_ADMIN']);
    const author = JwtClaims(roles: ['HOST_AUTHOR']);

    expect(LiveProctorAccessPolicy.canControl(proctor), isTrue);
    expect(LiveProctorAccessPolicy.canObserve(proctor), isFalse);
    expect(LiveProctorAccessPolicy.canObserve(admin), isTrue);
    expect(LiveProctorAccessPolicy.canControl(admin), isFalse);
    expect(LiveProctorAccessPolicy.canControl(author), isFalse);
    expect(LiveProctorAccessPolicy.canObserve(author), isFalse);
  });
}
