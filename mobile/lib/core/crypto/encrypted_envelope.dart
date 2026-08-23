import 'dart:convert';
import 'dart:typed_data';

/// Wire format for a single encrypted chat message body.
///
/// Sent as the plain `body` string field of `POST /messages` (Week 5's
/// `SendMessageRequest.Body`) — the backend needs zero changes: Week 6
/// Day 1's backend task was confirming it stores whatever it's given as
/// an opaque blob, and this JSON string (with the ciphertext bytes
/// base64-encoded inside it) satisfies that without a new field.
///
/// `type` mirrors libsignal's `CiphertextMessageType.value` — the
/// recipient needs it to know whether to treat this as a pre-key message
/// (the session's first message) or a regular one when calling
/// `SessionCipher.decrypt`.
class EncryptedEnvelope {
  static const int _formatVersion = 1;

  final int type;
  final Uint8List ciphertext;

  EncryptedEnvelope({required this.type, required this.ciphertext});

  String toJsonString() {
    return jsonEncode({
      'v': _formatVersion,
      'type': type,
      'ciphertext': base64Encode(ciphertext),
    });
  }

  static EncryptedEnvelope fromJsonString(String raw) {
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not an encrypted envelope');
    }

    final type = decoded['type'];
    final ciphertextB64 = decoded['ciphertext'];

    if (type is! int || ciphertextB64 is! String) {
      throw const FormatException('Malformed encrypted envelope');
    }

    return EncryptedEnvelope(
      type: type,
      ciphertext: base64Decode(ciphertextB64),
    );
  }

  /// True if [raw] looks like an [EncryptedEnvelope] rather than a
  /// pre-encryption (Week 5) plaintext message — lets old plaintext test
  /// messages already sitting in the backend/DB keep displaying
  /// correctly instead of being mistaken for garbled ciphertext.
  static bool looksLikeEnvelope(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> &&
          decoded['v'] == _formatVersion &&
          decoded.containsKey('type') &&
          decoded.containsKey('ciphertext');
    } catch (_) {
      return false;
    }
  }
}