import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal/libsignal.dart';
import 'package:mobile/core/crypto/encrypted_envelope.dart';

/// Proves Week 6, Day 3 (encrypt) and Day 4 (decrypt) actually work,
/// without needing the backend's Kyber pre-key gap closed first.
///
/// `SessionService.establishSession`/`encryptMessage`/`decryptMessage`
/// can't be called directly here: they go through `KeyApiService`
/// (real HTTP) and `IdentityKeyService` (real `flutter_secure_storage`,
/// which needs platform channels `flutter test` doesn't provide without
/// extra mocking). Instead, this test performs the exact same libsignal
/// calls those methods make — `SessionBuilder.processPreKeyBundle`,
/// `SessionCipher.encrypt`, `SessionCipher.decrypt` — against two fully
/// local, in-memory identities standing in for two real accounts. If
/// this test passes, the protocol logic `SessionService` wraps is
/// correct; the only remaining blocker to it working in the real app is
/// the backend serving a real Kyber pre-key.
void main() {
  const fixedDeviceId = 1;

  // `package:libsignal` is a flutter_rust_bridge package — its native
  // side must be loaded once before ANY of its classes are touched,
  // exactly like `main.dart` does for the real app. Without this, every
  // call below throws "flutter_rust_bridge has not been initialized"
  // immediately, which is why the test previously showed 0 passing.
  setUpAll(() async {
    await LibSignal.init();
  });

  test('Alice can establish a session with Bob and send an encrypted '
      'message that Bob can decrypt', () async {
    // ------------------------------------------------------------
    // Bob's identity + pre-keys (mirrors what PreKeyService/
    // IdentityKeyService generate on a real device, plus a Kyber
    // pre-key — which nothing in the app generates yet, since the
    // backend can't accept one).
    // ------------------------------------------------------------

    final bobIdentity = IdentityKeyPair.generate();
    final bobRegistrationId = 12345;

    final bobSignedPreKeyPrivate = PrivateKey.generate();
    final bobSignedPreKeyPublic = bobSignedPreKeyPrivate.getPublicKey();
    final bobIdentityPrivateForSigning = PrivateKey.deserialize(
      bytes: bobIdentity.privateKey.toList(),
    );
    final bobSignedPreKeySignature = bobIdentityPrivateForSigning.sign(
      message: bobSignedPreKeyPublic.serialize().toList(),
    );
    final bobSignedPreKeyRecord = SignedPreKeyRecord(
      id: 1,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      publicKey: bobSignedPreKeyPublic,
      privateKey: bobSignedPreKeyPrivate,
      signature: bobSignedPreKeySignature.toList(),
    );

    final bobOneTimePreKeyPrivate = PrivateKey.generate();
    final bobOneTimePreKeyPublic = bobOneTimePreKeyPrivate.getPublicKey();
    final bobOneTimePreKeyRecord = PreKeyRecord(
      id: 1,
      publicKey: bobOneTimePreKeyPublic,
      privateKey: bobOneTimePreKeyPrivate,
    );

    final bobKyberKeyPair = KyberKeyPair.generate();
    final bobKyberSignature = bobIdentityPrivateForSigning.sign(
      message: bobKyberKeyPair.getPublicKey().serialize().toList(),
    );
    final bobKyberPreKeyRecord = KyberPreKeyRecord.create(
      id: 1,
      timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch),
      keyPair: bobKyberKeyPair,
      signature: bobKyberSignature.toList(),
    );

    // ------------------------------------------------------------
    // Bob's stores — exactly what SignalStoreProvider builds, one
    // set per user (Alice and Bob each get their own, since they're
    // two separate devices in real life).
    // ------------------------------------------------------------

    final bobSessionStore = InMemorySessionStore();
    final bobPreKeyStore = InMemoryPreKeyStore();
    final bobSignedPreKeyStore = InMemorySignedPreKeyStore();
    final bobKyberPreKeyStore = InMemoryKyberPreKeyStore();
    final bobIdentityKeyStore =
        InMemoryIdentityKeyStore(bobIdentity, bobRegistrationId);

    // Bob's device must have its own private key material for these
    // on hand to respond to Alice's first (pre-key) message — this
    // mirrors uploading public halves to the backend while keeping
    // the private halves locally.
    await bobPreKeyStore.storePreKey(
      bobOneTimePreKeyRecord.id(),
      bobOneTimePreKeyRecord,
    );
    await bobSignedPreKeyStore.storeSignedPreKey(
      bobSignedPreKeyRecord.id(),
      bobSignedPreKeyRecord,
    );
    await bobKyberPreKeyStore.storeKyberPreKey(
      bobKyberPreKeyRecord.id(),
      bobKyberPreKeyRecord,
    );

    // ------------------------------------------------------------
    // Alice's identity + stores.
    // ------------------------------------------------------------

    final aliceIdentity = IdentityKeyPair.generate();
    final aliceRegistrationId = 54321;

    final aliceSessionStore = InMemorySessionStore();
    final aliceIdentityKeyStore =
        InMemoryIdentityKeyStore(aliceIdentity, aliceRegistrationId);

    final aliceAddress =
        ProtocolAddress(name: 'alice-user-id', deviceId: fixedDeviceId);
    final bobAddress =
        ProtocolAddress(name: 'bob-user-id', deviceId: fixedDeviceId);

    // ------------------------------------------------------------
    // Alice builds a PreKeyBundle from Bob's PUBLIC material only —
    // exactly what SessionService.establishSession does with a
    // fetched UserKeyBundle, just built locally instead of parsed
    // from a GET /users/:userId/keys JSON response.
    // ------------------------------------------------------------

    final bobBundle = PreKeyBundle(
      registrationId: bobRegistrationId,
      deviceId: fixedDeviceId,
      preKeyId: bobOneTimePreKeyRecord.id(),
      preKeyPublic: bobOneTimePreKeyPublic.serialize(),
      signedPreKeyId: bobSignedPreKeyRecord.id(),
      signedPreKeyPublic: bobSignedPreKeyPublic.serialize(),
      signedPreKeySignature: bobSignedPreKeyRecord.signature(),
      identityKey: bobIdentity.publicKey,
      kyberPreKeyId: bobKyberPreKeyRecord.id(),
      kyberPreKeyPublic: bobKyberKeyPair.getPublicKey().serialize(),
      kyberPreKeySignature: bobKyberPreKeyRecord.signature(),
    );

    final sessionBuilder = SessionBuilder(
      localAddress: aliceAddress,
      sessionStore: aliceSessionStore,
      identityKeyStore: aliceIdentityKeyStore,
    );

    // This is the exact call SessionService.establishSession makes.
    await sessionBuilder.processPreKeyBundle(bobAddress, bobBundle);

    final hasSession = await aliceSessionStore.containsSession(bobAddress);
    expect(hasSession, isTrue,
        reason: 'Alice should have a session with Bob after X3DH/PQXDH');

    // ------------------------------------------------------------
    // Day 3: Alice encrypts a message for Bob — exactly what
    // SessionService.encryptMessage does.
    // ------------------------------------------------------------

    final aliceCipher = SessionCipher(
      localAddress: aliceAddress,
      sessionStore: aliceSessionStore,
      identityKeyStore: aliceIdentityKeyStore,
      preKeyStore: InMemoryPreKeyStore(),
      signedPreKeyStore: InMemorySignedPreKeyStore(),
      kyberPreKeyStore: InMemoryKyberPreKeyStore(),
    );

    const plaintext = 'Hello Bob, this is Alice.';
    final ciphertextMessage = await aliceCipher.encrypt(
      bobAddress,
      Uint8List.fromList(utf8.encode(plaintext)),
    );

    // Wrap/unwrap through the actual wire format used in
    // MessageRepository's `body` field, to prove that round-trips
    // correctly too.
    final envelope = EncryptedEnvelope(
      type: ciphertextMessage.type.value,
      ciphertext: ciphertextMessage.ciphertext,
    );
    final envelopeJson = envelope.toJsonString();

    expect(EncryptedEnvelope.looksLikeEnvelope(envelopeJson), isTrue);
    expect(envelopeJson, isNot(contains(plaintext)),
        reason: 'The wire format must never contain readable plaintext');

    // ------------------------------------------------------------
    // Day 4: Bob decrypts it — exactly what
    // SessionService.decryptMessage does. Bob has no prior session
    // with Alice yet: this is the "responder" path, using Bob's own
    // stored pre-keys to establish the session and decrypt in one
    // step, which is real Signal Protocol behaviour.
    // ------------------------------------------------------------

    final receivedEnvelope = EncryptedEnvelope.fromJsonString(envelopeJson);

    final bobCipher = SessionCipher(
      localAddress: bobAddress,
      sessionStore: bobSessionStore,
      identityKeyStore: bobIdentityKeyStore,
      preKeyStore: bobPreKeyStore,
      signedPreKeyStore: bobSignedPreKeyStore,
      kyberPreKeyStore: bobKyberPreKeyStore,
    );

    final decryptedBytes = await bobCipher.decrypt(
      aliceAddress,
      CiphertextMessage(
        type: CiphertextMessageType.fromValue(receivedEnvelope.type),
        ciphertext: receivedEnvelope.ciphertext,
      ),
    );

    final decryptedText = utf8.decode(decryptedBytes);

    expect(decryptedText, equals(plaintext),
        reason: 'Bob must recover exactly what Alice sent');

    // ------------------------------------------------------------
    // Bonus: a second message proves the Double Ratchet actually
    // advances, not just that a single pre-key message works.
    // ------------------------------------------------------------

    const secondPlaintext = 'How are you?';
    final secondCiphertext = await aliceCipher.encrypt(
      bobAddress,
      Uint8List.fromList(utf8.encode(secondPlaintext)),
    );

    final secondDecrypted = await bobCipher.decrypt(
      aliceAddress,
      CiphertextMessage(
        type: secondCiphertext.type,
        ciphertext: secondCiphertext.ciphertext,
      ),
    );

    expect(utf8.decode(secondDecrypted), equals(secondPlaintext));
  });
}