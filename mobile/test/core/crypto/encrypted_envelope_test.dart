import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/crypto/encrypted_envelope.dart';

void main() {
  group('EncryptedEnvelope', () {
    test('round-trips type and ciphertext through JSON', () {
      final original = EncryptedEnvelope(
        type: 3, // preKey
        ciphertext: Uint8List.fromList([1, 2, 3, 250, 255, 0]),
      );

      final jsonString = original.toJsonString();
      final decoded = EncryptedEnvelope.fromJsonString(jsonString);

      expect(decoded.type, 3);
      expect(decoded.ciphertext, original.ciphertext);
    });

    test('looksLikeEnvelope is true for a real envelope', () {
      final envelope = EncryptedEnvelope(
        type: 2,
        ciphertext: Uint8List.fromList([9, 9, 9]),
      );

      expect(
        EncryptedEnvelope.looksLikeEnvelope(envelope.toJsonString()),
        isTrue,
      );
    });

    test('looksLikeEnvelope is false for legacy Week 5 plaintext', () {
      expect(
        EncryptedEnvelope.looksLikeEnvelope('hey, how are you?'),
        isFalse,
      );
    });

    test('looksLikeEnvelope is false for unrelated JSON', () {
      expect(
        EncryptedEnvelope.looksLikeEnvelope('{"foo": "bar"}'),
        isFalse,
      );
    });

    test('fromJsonString throws on malformed envelope', () {
      expect(
        () => EncryptedEnvelope.fromJsonString('{"v":1,"type":"oops"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}