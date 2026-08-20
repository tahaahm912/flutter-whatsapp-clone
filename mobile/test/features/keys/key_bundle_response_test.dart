import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/keys/data/models/key_bundle_response.dart';

void main() {
  group('UserKeyBundle.fromJson', () {
    test('parses a device with a one-time prekey', () {
      final json = {
        'user_id': 'user-123',
        'devices': [
          {
            'device_id': 'device-abc',
            'identity_key': {
              'public_key': 'aWRlbnRpdHlrZXk=',
              'registration_id': 4321,
            },
            'signed_prekey': {
              'key_id': 1,
              'public_key': 'c2lnbmVka2V5',
              'signature': 'c2lnbmF0dXJl',
            },
            'one_time_prekey': {
              'key_id': 7,
              'public_key': 'b25ldGltZWtleQ==',
            },
          },
        ],
      };

      final bundle = UserKeyBundle.fromJson(json);

      expect(bundle.userId, 'user-123');
      expect(bundle.devices, hasLength(1));

      final device = bundle.devices.first;
      expect(device.deviceId, 'device-abc');
      expect(device.identityKey.registrationId, 4321);
      expect(device.signedPrekey.keyId, 1);
      expect(device.oneTimePrekey?.keyId, 7);
      expect(device.kyberPrekey, isNull); // not sent by today's backend
    });

    test('handles a null one_time_prekey (device ran out)', () {
      final json = {
        'user_id': 'user-123',
        'devices': [
          {
            'device_id': 'device-abc',
            'identity_key': {'public_key': 'a2V5', 'registration_id': 1},
            'signed_prekey': {
              'key_id': 1,
              'public_key': 'a2V5',
              'signature': 'c2ln',
            },
            'one_time_prekey': null,
          },
        ],
      };

      final bundle = UserKeyBundle.fromJson(json);

      expect(bundle.devices.first.oneTimePrekey, isNull);
    });

    test('handles zero devices (NO_KEYS_AVAILABLE shape)', () {
      final bundle = UserKeyBundle.fromJson({
        'user_id': 'user-123',
        'devices': [],
      });

      expect(bundle.devices, isEmpty);
    });
  });
}