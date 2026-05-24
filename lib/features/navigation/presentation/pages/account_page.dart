import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Акаунт')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_done_outlined),
              title: const Text('Google Drive'),
              subtitle: const Text('Підключено'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Налаштування'),
              subtitle: const Text('Профіль, безпека, параметри додатку'),
              onTap: () => context.go('/settings'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Допомога'),
              subtitle: const Text('Підтримка і FAQ'),
              onTap: () => context.go('/help'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Адмін панель'),
              subtitle: const Text('Доступно тільки адміністраторам'),
              onTap: () => context.go('/admin'),
            ),
          ),
        ],
      ),
    );
  }
}
