import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/features/auth/domain/jwt_claims.dart';
import 'package:pte_app/features/host_console/domain/host_access_policy.dart';

void main() {
  test('HOST_ADMIN can enter the Host console with admin capabilities', () {
    const claims = JwtClaims(roles: ['HOST_ADMIN'], tenantId: 'tenant-1');

    expect(HostAccessPolicy.canEnterHostConsole(claims), isTrue);
    expect(HostAccessPolicy.isHostAdmin(claims), isTrue);
    expect(HostAccessPolicy.isHostAuthor(claims), isFalse);
  });

  test('HOST_AUTHOR can enter the Host console without admin capabilities', () {
    const claims = JwtClaims(roles: ['HOST_AUTHOR'], tenantId: 'tenant-1');

    expect(HostAccessPolicy.canEnterHostConsole(claims), isTrue);
    expect(HostAccessPolicy.isHostAdmin(claims), isFalse);
    expect(HostAccessPolicy.isHostAuthor(claims), isTrue);
  });

  test('Host membership is found among multiple JWT roles', () {
    const claims = JwtClaims(
      roles: ['STUDENT', 'HOST_AUTHOR'],
      tenantId: 'tenant-1',
    );

    expect(HostAccessPolicy.canEnterHostConsole(claims), isTrue);
  });

  test('student and platform roles cannot enter the Host console', () {
    const student = JwtClaims(roles: ['STUDENT'], tenantId: 'tenant-1');
    const platformAdmin = JwtClaims(roles: ['PLATFORM_ADMIN']);

    expect(HostAccessPolicy.canEnterHostConsole(student), isFalse);
    expect(HostAccessPolicy.canEnterHostConsole(platformAdmin), isFalse);
  });
}
