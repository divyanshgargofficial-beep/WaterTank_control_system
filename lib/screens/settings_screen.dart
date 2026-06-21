import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: ref.read(settingsControllerProvider).controllerIp,
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Controller',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Controller IP',
                  prefixIcon: Icon(Icons.router_rounded),
                ),
                onSubmitted: (value) =>
                    _save(settings.copyWith(controllerIp: value.trim())),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _save(
                  settings.copyWith(controllerIp: _ipController.text.trim()),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Controller IP'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Refresh Interval'),
                subtitle: Text('${settings.refreshIntervalSeconds} seconds'),
                leading: const Icon(Icons.sync_rounded),
              ),
              Slider(
                min: 1,
                max: 10,
                divisions: 9,
                value: settings.refreshIntervalSeconds.toDouble(),
                label: '${settings.refreshIntervalSeconds}s',
                onChanged: (value) => _save(
                  settings.copyWith(refreshIntervalSeconds: value.round()),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text(
                  'Pump, tank, lockout, and connection alerts',
                ),
                value: settings.notificationsEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(notificationsEnabled: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High Contrast Cards'),
                subtitle: const Text('Reduce glass transparency'),
                value: settings.highContrast,
                onChanged: (value) =>
                    _save(settings.copyWith(highContrast: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppSettings settings) async {
    await ref.read(settingsControllerProvider.notifier).update(settings);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }
}
