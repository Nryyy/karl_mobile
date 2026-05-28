import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../../../core/providers/locale_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.asData?.value;

    Widget _localeTile(String label, String code) {
      final selected = (currentLocale == null && code == 'system') || (currentLocale?.languageCode == code);
      return RadioListTile<String>(
        value: code,
        groupValue: currentLocale?.languageCode ?? (code == 'system' ? 'system' : null),
        onChanged: (v) async {
          Locale? locale;
          if (v == null || v == 'system') locale = null;
          else locale = Locale(v);
          await ref.read(localeProvider.notifier).setLocale(locale);
        },
        title: Text(label),
        selected: selected,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.settings ?? 'Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)?.language ?? 'Language', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _localeTile(AppLocalizations.of(context)?.help ?? 'System', 'system'),
                _localeTile('English', 'en'),
                _localeTile('Українська', 'uk'),
                _localeTile('Polski', 'pl'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
