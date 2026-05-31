import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';

/// Settings page with Material 3 design for language and theme settings.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeProvider);
    final currentLocale = localeAsync.asData?.value;
    final themeMode = ref.watch(themeNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Зовнішній вигляд',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ThemeTile(
                  label: 'Системна',
                  icon: Icons.brightness_auto,
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.system),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeTile(
                  label: 'Світла',
                  icon: Icons.light_mode,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                _ThemeTile(
                  label: 'Темна',
                  icon: Icons.dark_mode,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeNotifierProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language Section
          _SectionHeader(
            icon: Icons.language,
            title: AppLocalizations.of(context)?.language ?? 'Language',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _LocaleTile(
                  label: 'Системна за замовчуванням',
                  code: 'system',
                  currentLocale: currentLocale,
                  onChanged: (v) => _setLocale(ref, v),
                ),
                const Divider(height: 1, indent: 56),
                _LocaleTile(
                  label: 'English',
                  code: 'en',
                  currentLocale: currentLocale,
                  onChanged: (v) => _setLocale(ref, v),
                ),
                const Divider(height: 1, indent: 56),
                _LocaleTile(
                  label: 'Українська',
                  code: 'uk',
                  currentLocale: currentLocale,
                  onChanged: (v) => _setLocale(ref, v),
                ),
                const Divider(height: 1, indent: 56),
                _LocaleTile(
                  label: 'Polski',
                  code: 'pl',
                  currentLocale: currentLocale,
                  onChanged: (v) => _setLocale(ref, v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _SectionHeader(
            icon: Icons.info_outline,
            title: 'Про додаток',
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(Icons.app_shortcut, color: colorScheme.primary),
              title: Text('Karl Mobile'),
              subtitle: Text('v1.0.0'),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocale(WidgetRef ref, String code) async {
    Locale? locale;
    if (code == 'system') {
      locale = null;
    } else {
      locale = Locale(code);
    }
    await ref.read(localeProvider.notifier).setLocale(locale);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.circle_outlined, color: colorScheme.outline),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
    );
  }
}

class _LocaleTile extends StatelessWidget {
  const _LocaleTile({
    required this.label,
    required this.code,
    required this.currentLocale,
    required this.onChanged,
  });

  final String label;
  final String code;
  final Locale? currentLocale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = (currentLocale == null && code == 'system') ||
        (currentLocale?.languageCode == code);

    return ListTile(
      leading: SizedBox(
        width: 24,
        child: Center(
          child: Text(
            code == 'system' ? 'A' : code.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : null,
      onTap: () => onChanged(code),
      selected: isSelected,
      selectedTileColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
    );
  }
}
