import 'package:libsignal/libsignal.dart';

import '../storage/secure_storage.dart';
import 'identity_key_service.dart';

/// Owns the Signal Protocol stores (session, identity, pre-key, signed
/// pre-key, Kyber pre-key) for the lifetime of the app.
///
/// Week 6, Day 2 scope: these are the in-memory implementations that ship
/// with `package:libsignal` — good enough to prove a session can be
/// established and to carry it through a single app run. The package's
/// own README is explicit that in-memory stores "lose all data on app
/// restart" and are for "testing / demo applications" only — swapping
/// these for Drift-backed stores (so a session survives a restart) is
/// real, separate follow-up work, not something this checkpoint needs.
///
/// Every `SessionBuilder`/`SessionCipher` in the app must share the exact
/// same store instances, or a session built on one screen becomes
/// invisible on another — e.g. Day 2's `establishSession` call and Day
/// 3/4's `encryptMessage`/`decryptMessage` calls, made from different
/// screens over the app's lifetime, all need to see the same session.
/// [instance] is the app-wide singleton that guarantees that.
class SignalStoreProvider {
  final IdentityKeyService _identityKeyService;

  SignalStoreProvider(this._identityKeyService);

  static SignalStoreProvider? _instance;

  /// The shared instance every screen should use. Lazily built on first
  /// access, using the device's already-persisted identity (Week 4) —
  /// never a fresh one.
  static SignalStoreProvider get instance {
    return _instance ??=
        SignalStoreProvider(IdentityKeyService(SecureStorage()));
  }

  final SessionStore sessionStore = InMemorySessionStore();
  final PreKeyStore preKeyStore = InMemoryPreKeyStore();
  final SignedPreKeyStore signedPreKeyStore = InMemorySignedPreKeyStore();
  final KyberPreKeyStore kyberPreKeyStore = InMemoryKyberPreKeyStore();

  IdentityKeyStore? _identityKeyStore;

  /// Builds (once) the identity key store, seeded with the identity key
  /// pair and registration ID already persisted on this device from Week
  /// 4 — not a fresh identity, so this device keeps the same long-term
  /// identity every time the app runs.
  Future<IdentityKeyStore> getIdentityKeyStore() async {
    final existing = _identityKeyStore;
    if (existing != null) {
      return existing;
    }

    final identityKeyPair =
        await _identityKeyService.getOrCreateIdentityKeyPair();
    final registrationId =
        await _identityKeyService.getOrCreateRegistrationId();

    final store = InMemoryIdentityKeyStore(identityKeyPair, registrationId);
    _identityKeyStore = store;
    return store;
  }
}