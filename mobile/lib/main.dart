import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/crypto/identity_key_service.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Main started');

  try {
    // Initialize LibSignal
    await IdentityKeyService.initialize();
    print('LibSignal initialized');

    // Create storage + identity service
    final storage = SecureStorage();
    final identityService = IdentityKeyService(storage);

    // Generate identity key pair
    final identity = await identityService.generateIdentityKeyPair();

    print('Identity key generated');

    // Get public key
    final publicKey = await identityService.getPublicKey(identity);

    print('Public key: $publicKey');

    // Test backend
    final api = ApiClient();

    print('Calling health endpoint...');

    final response = await api.dio.get('/health');

    print('Backend response: ${response.data}');
  } catch (e, stackTrace) {
    print('ERROR: $e');
    print(stackTrace);
  }

  runApp(const BluLinkApp());
}