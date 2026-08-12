import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/crypto/identity_key_service.dart';
import 'core/crypto/pre_key_service.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('===== DAY 4 CRYPTO TEST =====');

  try {
    // 1. Initialize LibSignal
    await IdentityKeyService.initialize();
    print('1. LibSignal initialized');

    // 2. Create services
    final storage = SecureStorage();
    final identityService = IdentityKeyService(storage);
    final preKeyService = PreKeyService(identityService);

    // 3. Generate identity key pair
    final identity = await identityService.generateIdentityKeyPair();
    print('2. Identity key generated');

    // 4. Get identity public key
    final publicKey = identityService.getPublicKey(identity);

    print('3. Identity public key: $publicKey');

    // 5. Generate Signed Pre-Key
    final signedPreKey = await preKeyService.generateSignedPreKey(
      id: 1,
    );

    print('4. Signed Pre-Key generated');
    print('   Signed Pre-Key ID: ${signedPreKey.id}');

    // 6. Convert Signed Pre-Key public information to JSON
    final signedPreKeyJson =
        preKeyService.signedPreKeyToJson(signedPreKey);

    print('5. Signed Pre-Key JSON created');
    print('   $signedPreKeyJson');

    // 7. Generate 100 One-Time Pre-Keys
    final oneTimePreKeys =
        await preKeyService.generateOneTimePreKeys(
      startId: 1,
      count: 100,
    );

    print('6. One-Time Pre-Keys generated');
    print('   Count: ${oneTimePreKeys.length}');

    // 8. Test first One-Time Pre-Key JSON conversion
    final firstPreKeyJson =
        preKeyService.preKeyToJson(oneTimePreKeys.first);

    print('7. First One-Time Pre-Key JSON created');
    print('   $firstPreKeyJson');

    // 9. Verify count
    if (oneTimePreKeys.length == 100) {
      print('8. PASS: Exactly 100 One-Time Pre-Keys generated');
    } else {
      print(
        '8. FAIL: Expected 100 keys, got ${oneTimePreKeys.length}',
      );
    }

    print('===== DAY 4 CRYPTO TEST COMPLETE =====');
  } catch (e, stackTrace) {
    print('===== DAY 4 CRYPTO TEST FAILED =====');
    print('ERROR: $e');
    print(stackTrace);
  }

  runApp(const BluLinkApp());
}