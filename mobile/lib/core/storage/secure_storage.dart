import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _identityPrivateKey = "identity_private_key";
  static const String _registrationIdKey = "registration_id";
  static const String _userIdKey = "user_id";


  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(
      key: _accessTokenKey,
    );
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: _refreshTokenKey,
    );
  }

  Future<void> saveIdentityPrivateKey(String key) async {
    await _storage.write(
      key: _identityPrivateKey,
      value: key,
    );
  }

  Future<String?> getIdentityPrivateKey() async {
    return await _storage.read(
      key: _identityPrivateKey,
    );
  }

  Future<void> deleteIdentityPrivateKey() async {
    await _storage.delete(
      key: _identityPrivateKey,
    );
  }

  // Week 4, Day 5: the backend's POST /users/keys requires a
  // registration_id (Signal's 14-bit device identifier, 1–16380) —
  // it's generated once per device and reused on every key upload
  // after that, so it's persisted here alongside the identity key.
  Future<void> saveRegistrationId(int registrationId) async {
    await _storage.write(
      key: _registrationIdKey,
      value: registrationId.toString(),
    );
  }

  Future<int?> getRegistrationId() async {
    final value = await _storage.read(
      key: _registrationIdKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  Future<void> clearTokens() async {
    await _storage.delete(
      key: _accessTokenKey,
    );
  
    await _storage.delete(
      key: _refreshTokenKey,
    );
  
    await _storage.delete(
      key: _userIdKey,
    );
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> saveUserId(String userId) async {
  await _storage.write(
    key: _userIdKey,
    value: userId,
  );
}

Future<String?> getUserId() async {
  return await _storage.read(
    key: _userIdKey,
  );
}

Future<void> deleteUserId() async {
  await _storage.delete(
    key: _userIdKey,
  );
}
}