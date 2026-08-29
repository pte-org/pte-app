import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Result of [EncryptionHelper.encrypt] — the three Base64 fields
/// `EncryptedSubmissionRequest` (server-side DTO, Phase 2) expects.
class EncryptedPayload {
  const EncryptedPayload({
    required this.wrappedKey,
    required this.iv,
    required this.ciphertext,
  });

  final String wrappedKey;
  final String iv;
  final String ciphertext;
}

/// RSA-OAEP (SHA-256 digest, SHA-256 MGF1 — `OAEPEncoding.withSHA256`
/// structurally guarantees both match in this pointycastle version, see
/// phase file Preflight) + AES-256-GCM hybrid encryption for STRICT-integrity
/// answer submissions (task 20). A fresh AES key and 96-bit IV are generated
/// per [encrypt] call — never cached, never reused across submissions (FR-06).
class EncryptionHelper {
  static const int _aesKeyLengthBytes = 32;
  static const int _gcmIvLengthBytes = 12;
  static const int _gcmTagLengthBits = 128;

  /// Parses a Base64-encoded X.509 SubjectPublicKeyInfo DER string — the
  /// exact format `EncryptionKeyProvider.getPublicKeyBase64()` produces
  /// server-side (Phase 1) — into an [RSAPublicKey].
  RSAPublicKey parsePublicKey(String base64SubjectPublicKeyInfo) {
    final derBytes = base64Decode(base64SubjectPublicKeyInfo);
    final topLevelSeq = ASN1Parser(derBytes).nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements![1] as ASN1BitString;
    final publicKeyAsn = ASN1Parser(Uint8List.fromList(publicKeyBitString.stringValues!));
    final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    final modulus = (publicKeySeq.elements![0] as ASN1Integer).integer!;
    final exponent = (publicKeySeq.elements![1] as ASN1Integer).integer!;
    return RSAPublicKey(modulus, exponent);
  }

  EncryptedPayload encrypt(String plaintext, RSAPublicKey publicKey) {
    final random = _seededRandom();
    final aesKey = random.nextBytes(_aesKeyLengthBytes);
    final iv = random.nextBytes(_gcmIvLengthBytes);

    final gcm = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(aesKey), _gcmTagLengthBits, iv, Uint8List(0)));
    final ciphertext = gcm.process(Uint8List.fromList(utf8.encode(plaintext)));

    final oaep = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, ParametersWithRandom(PublicKeyParameter<RSAPublicKey>(publicKey), random));
    final wrappedKey = oaep.process(aesKey);

    return EncryptedPayload(
      wrappedKey: base64Encode(wrappedKey),
      iv: base64Encode(iv),
      ciphertext: base64Encode(ciphertext),
    );
  }

  /// `FortunaRandom` is not self-seeding — seed it from `dart:math`'s
  /// `Random.secure()` (platform CSPRNG), the standard pattern for this
  /// library, per call so no seed material is ever reused across encryptions.
  SecureRandom _seededRandom() {
    final seedSource = Random.secure();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => seedSource.nextInt(256)));
    return FortunaRandom()..seed(KeyParameter(seed));
  }
}
