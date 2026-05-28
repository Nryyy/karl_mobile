import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage.dart';

class LocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final code = await LocalStorage.loadLocale();
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncValue.data(locale);
    await LocalStorage.saveLocale(locale?.languageCode ?? '');
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale?>(
  () => LocaleNotifier(),
);
