import 'package:libsignal/libsignal.dart';

import 'identity_key_service.dart';

/// Owns the Signal Protocol stores (session, identity, pre-key, signed
/// pre-key, Kyber pre-key) for the lifetime of the app.
///
/// Week 6, Day 2 scope: these are the in-memory implementations that ship
/// with `package:libsignal` — good enough to prove a session can be
/// established and to carry it through a single app run, which is this
/// day's checkpoint. The package's own README is explicit that in-memory
/// stores "lose all data on app restart" and are for "testing / demo
/// applications" only — swapping these for Drift-backed stores (so a
/// session survives a restart) is real, separate follow-up work, not
/// something this checkpoint needs.
///
/// One [SignalStoreProvider] must be created once and reused everywhere a
/// `SessionBuilder`/`SessionCipher` is needed — every store has to be the
/// *same instance* across calls for a session to be found again after
/// it's built.
class SignalStoreProvider {
  final IdentityKeyService _identityKeyService;

  SignalStoreProvider(this._identityKeyService);

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