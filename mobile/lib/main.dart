import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("Main started");

  final api = ApiClient();

  try {
    print("Calling health endpoint...");

    final response = await api.dio.get("/health");

    print("Response received");
    print(response.data);
  } catch (e) {
    print("Error:");
    print(e);
  }

  runApp(const BluLinkApp());
}