class VerifyOtpRequest{
  final String identifier;
  final String code;

  const VerifyOtpRequest({
    required this.identifier,
    required this.code,
  });

  Map <String, dynamic> toJson(){
    return {
      "identifier": identifier,
      "code": code,
    };
  }
}