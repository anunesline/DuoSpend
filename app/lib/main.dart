import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("1 - Widgets");

  try {
    print("2 - Antes do Firebase");

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("3 - Firebase OK");
  } catch (e, s) {
    print("ERRO FIREBASE:");
    print(e);
    print(s);
  }

  print("4 - Antes do runApp");

  runApp(const DuoSpendApp());

  print("5 - Depois do runApp");
}