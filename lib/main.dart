import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:karl_mobile/generated/app_localizations.dart';
import 'core/providers/locale_provider.dart';

import 'core/providers/theme_provider.dart';

import 'config/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseInitialized = true;
  String? initErrorMessage;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // enable network for Firestore
    await FirebaseFirestore.instance.enableNetwork();
    developer.log('Firestore initialized successfully', name: 'karl.firestore');
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
    runApp(
      MaterialApp(
        title: 'Karl - Initialization Error',
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('uk'), Locale('pl')],
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Builder(
                  builder: (context) {
                    final loc = AppLocalizations.of(context);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 72,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc?.firebaseInitError ??
                              'Firebase initialization error',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          initErrorMessage ??
                              loc?.unknownError ??
                              'Unknown error. Check logs.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Keep minimal: advise user to restart the app after fixing
                          },
                          child: Text(loc?.closeApp ?? 'Close app'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.asData?.value;
    return MaterialApp.router(
      title: AppLocalizations.of(context)?.appTitle ?? 'Karl',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('uk'), Locale('pl')],
    );
  }
}
