class RegisterResponse {
  final String message;
  
  const RegisterResponse({
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json){
    return RegisterResponse(
      message: json["message"] ?? "",
    );
  }
}