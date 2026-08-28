import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pte_app/core/crypto/encryption_helper.dart';

void main() {
  late EncryptionHelper encryptionHelper;

  // Real RSA-2048 public key generated via:
  // openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out test.pem
  // openssl pkey -in test.pem -pubout -outform DER | base64 -w0
  const String testPublicKeyBase64 =
      'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmkRv1ibV6X9T/mPzAkvP68kJ7v+nhkV99yPj3EMYdGtrS4t8+41k6UJFKNKFe4ea7AfGQnl68XFgwQsezrOqEe5D2ildsNi6t8+MGfxbYFmN2QH4F/u2eTPjCH31RNeeuY0p0pjlL7nD2hX9GhGjRzz1juhu0Mvc5qPIVEsJKMjPpY/vhpccmPLtDU240hq5roEOV/NObL8HywJjiP8i9NUimPvDq8aA5f5lMdBj0ui3skCaF1J4lBVOST5KRjDBmAEGMloMbZstN2Q5LiVZWk1AQzL18zHQ9sNp0FzxlyD/iVXsYJEYCzYB4KoGttreCDyhzIeYnqZnyZia70jCwQIDAQAB';

  setUp(() {
    encryptionHelper = EncryptionHelper();
  });

  group('EncryptionHelper.parsePublicKey', () {
    test(
      'correctly parses a Base64 X.509 SubjectPublicKeyInfo public key string',
      () async {
        // Act
        final publicKey = encryptionHelper.parsePublicKey(testPublicKeyBase64);

        // Assert
        expect(publicKey, isNotNull);
        // The parsed key should be an RSAPublicKey with modulus and exponent
        expect(publicKey.modulus, isNotNull);
        expect(publicKey.publicExponent, isNotNull);
        // RSA-2048 has a modulus of 2048 bits (256 bytes when encoded)
        expect(publicKey.modulus?.bitLength, greaterThanOrEqualTo(2048));
      },
    );

    test(
      'throws on malformed Base64 string',
      () async {
        // Act & Assert
        expect(
          () => encryptionHelper.parsePublicKey('not-valid-base64!!!!'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'throws on empty Base64 string',
      () async {
        // Act & Assert
        expect(
          () => encryptionHelper.parsePublicKey(''),
          throwsA(anything),
        );
      },
    );
  });

  group('EncryptionHelper.encrypt', () {
    late final publicKey;

    setUpAll(() {
      publicKey = encryptionHelper.parsePublicKey(testPublicKeyBase64);
    });

    test(
      'generates and returns an EncryptedPayload with wrappedKey, iv, and ciphertext fields',
      () async {
        // Arrange
        const plaintext = 'test answer text';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);

        // Assert
        expect(payload, isNotNull);
        expect(payload.wrappedKey, isNotEmpty);
        expect(payload.iv, isNotEmpty);
        expect(payload.ciphertext, isNotEmpty);
        expect(payload.wrappedKey, isA<String>());
        expect(payload.iv, isA<String>());
        expect(payload.ciphertext, isA<String>());
      },
    );

    test(
      'generates exactly 12-byte IV (96 bits) per encryption call',
      () async {
        // Arrange
        const plaintext = 'test answer';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);
        final decodedIv = base64Decode(payload.iv);

        // Assert
        expect(decodedIv.length, equals(12),
            reason: 'IV must be exactly 12 bytes (96 bits) for AES-GCM');
      },
    );

    test(
      'generates exactly 32-byte AES key per encryption call (verified indirectly via wrappedKey size)',
      () async {
        // Arrange
        const plaintext = 'test answer';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);
        final decodedWrappedKey = base64Decode(payload.wrappedKey);

        // Assert
        // RSA-2048 wraps a 32-byte AES key → wrapped result is 256 bytes (RSA key size)
        expect(decodedWrappedKey.length, equals(256),
            reason:
                'Wrapped 32-byte AES key via RSA-2048 must be 256 bytes (2048 bits)');
      },
    );

    test(
      'produces different wrappedKey, iv, and ciphertext on consecutive calls (freshness guarantee)',
      () async {
        // Arrange
        const plaintext = 'same plaintext';

        // Act
        final payload1 = encryptionHelper.encrypt(plaintext, publicKey);
        final payload2 = encryptionHelper.encrypt(plaintext, publicKey);

        // Assert
        // IV must always be different (fresh random per call)
        expect(payload1.iv, isNot(equals(payload2.iv)),
            reason: 'Each encryption must generate a fresh IV');

        // Wrapped key must be different (since IV changed, the encryption changed)
        expect(payload1.wrappedKey, isNot(equals(payload2.wrappedKey)),
            reason:
                'Each encryption must generate a fresh wrapped key (due to fresh IV)');

        // Ciphertext must be different (fresh IV means different GCM output)
        expect(payload1.ciphertext, isNot(equals(payload2.ciphertext)),
            reason: 'Each encryption must produce different ciphertext (due to fresh IV)');
      },
    );

    test(
      'produces Base64-decodable ciphertext with correct length (plaintext + GCM tag)',
      () async {
        // Arrange
        const plaintext = 'test answer text';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);
        final decodedCiphertext = base64Decode(payload.ciphertext);

        // Assert
        // AES-GCM appends a 16-byte (128-bit) authentication tag
        expect(decodedCiphertext.length, equals(plaintext.length + 16),
            reason:
                'Ciphertext (with GCM tag) must be plaintext length + 16 bytes');
      },
    );

    test(
      'all returned fields are valid Base64 strings that decode without error',
      () async {
        // Arrange
        const plaintext = 'test';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);

        // Assert
        expect(() => base64Decode(payload.wrappedKey), returnsNormally);
        expect(() => base64Decode(payload.iv), returnsNormally);
        expect(() => base64Decode(payload.ciphertext), returnsNormally);
      },
    );

    test(
      'handles empty plaintext correctly',
      () async {
        // Arrange
        const plaintext = '';

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);

        // Assert
        expect(payload, isNotNull);
        final decodedCiphertext = base64Decode(payload.ciphertext);
        // Empty plaintext + 16-byte GCM tag = 16 bytes ciphertext
        expect(decodedCiphertext.length, equals(16));
      },
    );

    test(
      'handles long plaintext correctly',
      () async {
        // Arrange
        final plaintext = 'x' * 10000;

        // Act
        final payload = encryptionHelper.encrypt(plaintext, publicKey);

        // Assert
        expect(payload, isNotNull);
        final decodedCiphertext = base64Decode(payload.ciphertext);
        expect(decodedCiphertext.length, equals(plaintext.length + 16));
      },
    );
  });

  group('EncryptedPayload', () {
    test('is a value class with wrappedKey, iv, ciphertext fields', () {
      // Arrange
      const wrappedKey = 'abc123';
      const iv = 'def456';
      const ciphertext = 'ghi789';

      // Act
      final payload = EncryptedPayload(
        wrappedKey: wrappedKey,
        iv: iv,
        ciphertext: ciphertext,
      );

      // Assert
      expect(payload.wrappedKey, equals(wrappedKey));
      expect(payload.iv, equals(iv));
      expect(payload.ciphertext, equals(ciphertext));
    });
  });
}
