import 'dart:convert';
import 'dart:math';

import 'package:libsignal/libsignal.dart';

import '../storage/secure_storage.dart';

class IdentityKeyService {
  final SecureStorage _storage;

  IdentityKeyService(this._storage);

  /// Initialize LibSignal.
  static Future<void> initialize() async {
    await LibSignal.init();
  }

  /// Get the existing identity or generate a new one.
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async {
    // Try to restore an existing identity first.
    final existingIdentity = await restoreIdentityKeyPair();

    if (existingIdentity != null) {
      print('Identity key restored from secure storage.');
      return existingIdentity;
    }

    // No identity exists, so generate a new one.
    final newIdentity = await generateIdentityKeyPair();

    print('New identity key generated and saved.');

    return newIdentity;
  }

  /// Generate a new identity key pair.
  Future<IdentityKeyPair> generateIdentityKeyPair() async {
    final identityKeyPair = IdentityKeyPair.generate();

    final privateKeyBytes = identityKeyPair.privateKey;

    final privateKeyBase64 = base64Encode(privateKeyBytes);

    await _storage.saveIdentityPrivateKey(privateKeyBase64);

    return identityKeyPair;
  }

  /// Get the public key as Base64.
  String getPublicKey(IdentityKeyPair identityKeyPair) {
    return base64Encode(identityKeyPair.publicKey);
  }

  /// Restore an identity key pair from secure storage.
  Future<IdentityKeyPair?> restoreIdentityKeyPair() async {
    final privateKeyBase64 = await _storage.getIdentityPrivateKey();

    if (privateKeyBase64 == null || privateKeyBase64.isEmpty) {
      return null;
    }

    final privateKeyBytes = base64Decode(privateKeyBase64);

    final privateKey = PrivateKey.deserialize(
      bytes: privateKeyBytes,
    );

    final publicKey = privateKey.getPublicKey();

    return IdentityKeyPair.fromKeys(
      privateKey: privateKey,
      publicKey: publicKey,
    );
  }

  /// Get the existing registration ID or generate a new one.
  ///
  /// Week 4, Day 5: the backend requires this on every POST
  /// /users/keys call (Signal's 14-bit device identifier, valid
  /// range 1–16380). It's generated once per device — not per
  /// upload — and reused after that.
  Future<int> getOrCreateRegistrationId() async {
    final existing = await _storage.getRegistrationId();

    if (existing != null) {
      return existing;
    }

    // Signal's registration ID is a 14-bit value; the backend
    // validates 1–16380 inclusive, so generate within that range
    // (never 0 — the backend's `binding:"required"` on this field
    // would reject it).
    final newRegistrationId = 1 + Random.secure().nextInt(16380);

    await _storage.saveRegistrationId(newRegistrationId);

    return newRegistrationId;
  }
}