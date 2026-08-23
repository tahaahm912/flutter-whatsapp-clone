import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal/libsignal.dart';

import '../../features/keys/data/models/key_bundle_response.dart';
import '../../features/keys/data/services/key_api_service.dart';
import '../storage/secure_storage.dart';
import 'encrypted_envelope.dart';
import 'signal_exceptions.dart';
import 'signal_store_provider.dart';

/// Week 6: establishes Signal Protocol sessions (Day 2) and encrypts /
/// decrypts messages over them (Day 3 / Day 4).
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

  ProtocolAddress _remoteAddress(String remoteUserId) {
    return ProtocolAddress(name: remoteUserId, deviceId: _fixedDeviceId);
  }

  /// Establishes a session with [remoteUserId]'s (first active) device.
  ///
  /// On success, the session is persisted in [SignalStoreProvider]'s
  /// `SessionStore` under `ProtocolAddress(remoteUserId, 1)` — nothing is
  /// returned, because nothing needs to be: [encryptMessage] looks the
  /// session up from that same store by address.
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

    final remoteAddress = _remoteAddress(remoteUserId);

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
  /// callers can skip re-running X3DH/PQXDH on every message.
  Future<bool> hasSession(String remoteUserId) async {
    return _storeProvider.sessionStore
        .containsSession(_remoteAddress(remoteUserId));
  }

  Future<SessionCipher> _cipherFor(String remoteUserId) async {
    final localAddress = await _localAddress();
    final identityKeyStore = await _storeProvider.getIdentityKeyStore();

    return SessionCipher(
      localAddress: localAddress,
      sessionStore: _storeProvider.sessionStore,
      identityKeyStore: identityKeyStore,
      preKeyStore: _storeProvider.preKeyStore,
      signedPreKeyStore: _storeProvider.signedPreKeyStore,
      kyberPreKeyStore: _storeProvider.kyberPreKeyStore,
    );
  }

  /// Week 6, Day 3: encrypts [plaintext] for [remoteUserId] using the
  /// Double Ratchet session already established for them.
  ///
  /// Requires [establishSession] to have succeeded for this user first —
  /// throws [SignalSessionException.noSessionEstablished] otherwise.
  /// `MessageRepository.sendMessage` handles calling `establishSession`
  /// automatically, so this is mainly a safety check for callers that
  /// use `SessionService` directly.
  Future<EncryptedEnvelope> encryptMessage({
    required String remoteUserId,
    required String plaintext,
  }) async {
    if (!await hasSession(remoteUserId)) {
      throw SignalSessionException.noSessionEstablished(remoteUserId);
    }

    final cipher = await _cipherFor(remoteUserId);
    final remoteAddress = _remoteAddress(remoteUserId);

    final ciphertextMessage = await cipher.encrypt(
      remoteAddress,
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    return EncryptedEnvelope(
      type: ciphertextMessage.type.value,
      ciphertext: ciphertextMessage.ciphertext,
    );
  }

  /// Week 6, Day 4: decrypts an [envelope] received from [remoteUserId].
  ///
  /// If [envelope] is a pre-key message (the session's first message and
  /// we're the responder — see `SessionCipher.decrypt`'s
  /// `_decryptPreKeyMessage` path), this can transparently *create* the
  /// session from our own stored pre-keys rather than requiring
  /// [establishSession] to have run first — that's normal Signal
  /// Protocol behaviour, not a gap here. It still needs our own Kyber
  /// pre-key to be present in [SignalStoreProvider.kyberPreKeyStore],
  /// which today's app never populates (Week 4 only generates classic
  /// Curve25519 pre-keys), so this path currently fails the same way
  /// [establishSession] does, for the same underlying reason.
  Future<String> decryptMessage({
    required String remoteUserId,
    required EncryptedEnvelope envelope,
  }) async {
    final cipher = await _cipherFor(remoteUserId);
    final remoteAddress = _remoteAddress(remoteUserId);

    final ciphertextMessage = CiphertextMessage(
      type: CiphertextMessageType.fromValue(envelope.type),
      ciphertext: envelope.ciphertext,
    );

    final plaintextBytes =
        await cipher.decrypt(remoteAddress, ciphertextMessage);

    return utf8.decode(plaintextBytes);
  }
}