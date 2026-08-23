import 'package:flutter/material.dart';
import 'package:libsignal/libsignal.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LibSignal.init();

  runApp(const BluLinkApp());
}