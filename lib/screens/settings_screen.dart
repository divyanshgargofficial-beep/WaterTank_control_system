import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Routing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Controller Local IP'),
                  subtitle: Text(settings.controllerIp),
                  trailing: const Icon(Icons.edit),
                ),
                ListTile(
                  title: const Text('Render Cloud URL'),
                  subtitle: Text(settings.cloudUrl),
                  trailing: const Icon(Icons.cloud),
                ),
                ListTile(
                  title: const Text('Preference'),
                  subtitle: Text(settings.connectionPreference.label),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Push Alerts & Notifications'),
                  value: settings.notificationsEnabled,
                  onChanged: (val) => notifier.update(
                    settings.copyWith(notificationsEnabled: val),
                  ),
                ),
                SwitchListTile(
                  title: const Text('High Contrast Theme'),
                  value: settings.highContrast,
                  onChanged: (val) => notifier.update(
                    settings.copyWith(highContrast: val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
