/// Errors specific to Signal Protocol session establishment.
///
/// Kept separate from the `Exception('SOME_CODE')` pattern used in the
/// key-upload/search repositories, since these carry an explanation meant
/// to be read by a developer, not just a code the UI switches on.
class SignalSessionException implements Exception {
  final String message;

  const SignalSessionException(this.message);

  /// The remote user has no devices with keys uploaded at all — nobody to
  /// build a session with yet. Mirrors the backend's `NO_KEYS_AVAILABLE`.
  factory SignalSessionException.noKeysAvailable(String remoteUserId) {
    return SignalSessionException(
      'User $remoteUserId has no device with a key bundle available yet '
      '(their app may not have finished uploading its Signal keys).',
    );
  }

  /// Week 6, Day 2 finding: `package:libsignal` (^7.0.2)'s `PreKeyBundle`
  /// requires a Kyber (post-quantum) pre-key for every session — its
  /// constructor marks `kyberPreKeyId`/`kyberPreKeyPublic`/
  /// `kyberPreKeySignature` as required, non-nullable arguments, not
  /// optional ones. That's libsignal's PQXDH requirement (confirmed
  /// against the package's actual Rust source, `rust/src/api/bundle.rs`,
  /// which takes `kyber_pre_key_id: u32`, not `Option<u32>`) — not a bug
  /// in this wrapper.
  ///
  /// The backend's `GET /users/:userId/keys` (Week 4, Day 4) only serves
  /// `identity_key` / `signed_prekey` / `one_time_prekey` — there's no
  /// Kyber pre-key in the response to build a real bundle from, and one
  /// can't be substituted locally: the Kyber key must genuinely belong to
  /// the remote device and be signed by *their* identity key, or
  /// `processPreKeyBundle`'s signature check would (correctly) fail.
  ///
  /// This is a backend gap, not a Flutter one. Until it's closed, this
  /// exception is the expected, documented outcome of calling
  /// `SessionService.establishSession`.
  factory SignalSessionException.missingKyberPreKey(String remoteUserId) {
    return SignalSessionException(
      'Cannot establish a session with $remoteUserId yet: the key bundle '
      'from GET /users/$remoteUserId/keys has no Kyber pre-key, and '
      'libsignal ^7.0.2 requires one for every PreKeyBundle (PQXDH). '
      'The backend needs to start serving a signed Kyber pre-key alongside '
      'the existing identity/signed/one-time pre-keys before real session '
      'establishment can succeed.',
    );
  }

  @override
  String toString() => 'SignalSessionException: $message';
}