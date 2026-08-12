class UploadKeysRequest {
  final String identityKey;
  final Map<String, dynamic> signedPreKey;
  final List<Map<String, dynamic>> oneTimePreKeys;

  UploadKeysRequest({
    required this.identityKey,
    required this.signedPreKey,
    required this.oneTimePreKeys,
  });

  Map<String, dynamic> toJson() {
    return {
      'identityKey': identityKey,
      'signedPreKey': signedPreKey,
      'oneTimePreKeys': oneTimePreKeys,
    };
  }
}