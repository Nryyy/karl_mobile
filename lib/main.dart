import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseInitialized = true;
  String? initErrorMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error, stackTrace) {
    firebaseInitialized = false;
    initErrorMessage = error.toString();
    developer.log(
      'Firebase initialization failed.',
      name: 'karl.firebase',
      error: error,
      stackTrace: stackTrace,
    );
  }

  if (!firebaseInitialized) {
    runApp(MaterialApp(
      title: 'Karl - Initialization Error',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 72, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Помилка ініціалізації Firebase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initErrorMessage ?? 'Невідома помилка. Перевірте логи.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Keep minimal: advise user to restart the app after fixing
                    },
                    child: const Text('Закрити додаток'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Karl',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
    );
  }
}
