import 'dart:convert';

import 'package:libsignal/libsignal.dart';

import '../../features/keys/data/models/key_bundle_response.dart';
import '../../features/keys/data/services/key_api_service.dart';
import '../storage/secure_storage.dart';
import 'signal_exceptions.dart';
import 'signal_store_provider.dart';

/// Week 6, Day 2: establishes a Signal Protocol session with another
/// user's device using each other's public keys (X3DH/PQXDH), so Day 3
/// has a live session to encrypt messages into.
///
/// Every device is addressed as Signal device ID `1` for now — the
/// backend's device IDs are UUIDs (see `models.Device`), and libsignal's
/// `ProtocolAddress` needs a small int (1-127). Real multi-device support
/// is its own roadmap item (V7), so for now this app only ever has one
/// active device per user, and `1` stands in for "the one device this
/// user has."
class SessionService {
  final SignalStoreProvider _storeProvider;
  final KeyApiService _keyApiService;
  final SecureStorage _secureStorage;

  SessionService({
    required SignalStoreProvider storeProvider,
    required KeyApiService keyApiService,
    required SecureStorage secureStorage,
  })  : _storeProvider = storeProvider,
        _keyApiService = keyApiService,
        _secureStorage = secureStorage;

  static const int _fixedDeviceId = 1;

  Future<ProtocolAddress> _localAddress() async {
    final userId = await _secureStorage.getUserId();

    if (userId == null || userId.isEmpty) {
      throw const SignalSessionException(
        'No logged-in user ID in secure storage — cannot address our own '
        'device for session establishment.',
      );
    }

    return ProtocolAddress(name: userId, deviceId: _fixedDeviceId);
  }

  /// Establishes a session with [remoteUserId]'s (first active) device.
  ///
  /// On success, the session is persisted in [SignalStoreProvider]'s
  /// `SessionStore` under `ProtocolAddress(remoteUserId, 1)` — nothing is
  /// returned, because nothing needs to be: Day 3's `SessionCipher` looks
  /// the session up from that same store by address.
  ///
  /// Throws [SignalSessionException] if the remote user has no keys
  /// uploaded yet, or — the expected outcome against today's backend, see
  /// [SignalSessionException.missingKyberPreKey] — if their bundle has no
  /// Kyber pre-key.
  Future<void> establishSession(String remoteUserId) async {
    final bundleResponse =
        await _keyApiService.fetchUserKeyBundle(remoteUserId);

    if (bundleResponse.devices.isEmpty) {
      throw SignalSessionException.noKeysAvailable(remoteUserId);
    }

    // Week 7 (multi-device) will need a session per device; for now we
    // only ever expect one, so take the first.
    final device = bundleResponse.devices.first;

    final kyberPrekey = device.kyberPrekey;
    if (kyberPrekey == null) {
      throw SignalSessionException.missingKyberPreKey(remoteUserId);
    }

    final remoteAddress = ProtocolAddress(
      name: remoteUserId,
      deviceId: _fixedDeviceId,
    );

    final preKeyBundle = PreKeyBundle(
      registrationId: device.identityKey.registrationId,
      deviceId: _fixedDeviceId,
      preKeyId: device.oneTimePrekey?.keyId,
      preKeyPublic: device.oneTimePrekey != null
          ? base64Decode(device.oneTimePrekey!.publicKey)
          : null,
      signedPreKeyId: device.signedPrekey.keyId,
      signedPreKeyPublic: base64Decode(device.signedPrekey.publicKey),
      signedPreKeySignature: base64Decode(device.signedPrekey.signature),
      identityKey: base64Decode(device.identityKey.publicKey),
      kyberPreKeyId: kyberPrekey.keyId,
      kyberPreKeyPublic: base64Decode(kyberPrekey.publicKey),
      kyberPreKeySignature: base64Decode(kyberPrekey.signature),
    );

    final localAddress = await _localAddress();
    final identityKeyStore = await _storeProvider.getIdentityKeyStore();

    final sessionBuilder = SessionBuilder(
      localAddress: localAddress,
      sessionStore: _storeProvider.sessionStore,
      identityKeyStore: identityKeyStore,
    );

    await sessionBuilder.processPreKeyBundle(remoteAddress, preKeyBundle);

    print('Signal session established with $remoteUserId.');
  }

  /// Whether a session already exists for [remoteUserId]'s device, so
  /// callers (e.g. the Chat screen, from Day 3 onward) can skip re-running
  /// X3DH/PQXDH on every message.
  Future<bool> hasSession(String remoteUserId) async {
    final remoteAddress = ProtocolAddress(
      name: remoteUserId,
      deviceId: _fixedDeviceId,
    );

    return _storeProvider.sessionStore.containsSession(remoteAddress);
  }
}