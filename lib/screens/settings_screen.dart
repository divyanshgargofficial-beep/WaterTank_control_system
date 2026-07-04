import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_tank_controller/models/app_settings.dart';
import 'package:water_tank_controller/models/app_user.dart';
import 'package:water_tank_controller/providers/app_providers.dart';
import 'package:water_tank_controller/widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _ipController;
  late final TextEditingController _cloudController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    _ipController = TextEditingController(text: settings.controllerIp);
    _cloudController = TextEditingController(text: settings.cloudUrl);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final auth = ref.watch(authControllerProvider);

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
              _SectionTitle(
                icon: Icons.hub_rounded,
                title: 'Connectivity',
                subtitle: settings.connectionPreference.description,
              ),
              const SizedBox(height: 16),
              SegmentedButton<ConnectionPreference>(
                segments: const [
                  ButtonSegment(
                    value: ConnectionPreference.auto,
                    label: Text('Auto'),
                    icon: Icon(Icons.hub_rounded),
                  ),
                  ButtonSegment(
                    value: ConnectionPreference.local,
                    label: Text('Local'),
                    icon: Icon(Icons.router_rounded),
                  ),
                  ButtonSegment(
                    value: ConnectionPreference.cloud,
                    label: Text('Cloud'),
                    icon: Icon(Icons.cloud_rounded),
                  ),
                ],
                selected: {settings.connectionPreference},
                onSelectionChanged: (value) => _save(
                  settings.copyWith(connectionPreference: value.first),
                  refreshController: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Controller Local IP',
                  prefixIcon: Icon(Icons.router_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _cloudController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Cloud URL',
                  prefixIcon: Icon(Icons.cloud_rounded),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _save(
                  settings.copyWith(
                    controllerIp: _ipController.text.trim(),
                    cloudUrl: _cloudController.text.trim(),
                  ),
                ),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Endpoints'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await _save(
                    settings.copyWith(
                      controllerIp: _ipController.text.trim(),
                      cloudUrl: _cloudController.text.trim(),
                    ),
                    refreshController: true,
                  );
                  await ref
                      .read(controllerControllerProvider.notifier)
                      .refresh(reason: 'test connection');
                },
                icon: const Icon(Icons.network_ping_rounded),
                label: const Text('Test Connection'),
              ),
              const SizedBox(height: 14),
              _InfoLine(
                label: 'Firmware Version',
                value:
                    ref
                        .watch(controllerControllerProvider)
                        .status
                        ?.firmwareVersion ??
                    'Unknown',
              ),
              _InfoLine(
                label: 'Backend Version',
                value: settings.cloudUrl.contains('onrender.com')
                    ? 'Render production'
                    : 'Custom backend',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            children: [
              _SectionTitle(
                icon: Icons.tune_rounded,
                title: 'Application',
                subtitle: 'Polling, timeout, theme, and notifications.',
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Polling Interval'),
                subtitle: Text('${settings.refreshIntervalSeconds} seconds'),
                leading: const Icon(Icons.sync_rounded),
              ),
              Slider(
                min: 3,
                max: 60,
                divisions: 57,
                value: settings.refreshIntervalSeconds.toDouble(),
                label: '${settings.refreshIntervalSeconds}s',
                onChanged: (value) => _save(
                  settings.copyWith(refreshIntervalSeconds: value.round()),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Connection Timeout'),
                subtitle: Text('${settings.connectionTimeoutSeconds} seconds'),
                leading: const Icon(Icons.timer_rounded),
              ),
              Slider(
                min: 2,
                max: 20,
                divisions: 18,
                value: settings.connectionTimeoutSeconds.toDouble(),
                label: '${settings.connectionTimeoutSeconds}s',
                onChanged: (value) => _save(
                  settings.copyWith(connectionTimeoutSeconds: value.round()),
                ),
              ),
              DropdownButtonFormField<AppThemeMode>(
                initialValue: settings.themeMode,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  prefixIcon: Icon(Icons.contrast_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text('Dark'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text('System'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) _save(settings.copyWith(themeMode: value));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifications'),
                subtitle: const Text('Master notification switch'),
                value: settings.notificationsEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(notificationsEnabled: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Administrator Notifications'),
                subtitle: const Text('Pump, tank, lockout, and connection'),
                value: settings.adminNotificationsEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(adminNotificationsEnabled: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Family Notifications'),
                subtitle: const Text('Informational alerts only'),
                value: settings.familyNotificationsEnabled,
                onChanged: (value) =>
                    _save(settings.copyWith(familyNotificationsEnabled: value)),
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
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.manage_accounts_rounded,
                title: 'Users',
                subtitle: 'Local secure profiles; ready for cloud auth later.',
              ),
              const SizedBox(height: 8),
              for (final user in auth.users)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    user.role == UserRole.administrator
                        ? Icons.admin_panel_settings_rounded
                        : Icons.home_rounded,
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.role.label),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Change password',
                        onPressed: () => _changePassword(user),
                        icon: const Icon(Icons.password_rounded),
                      ),
                      if (user.id != 'admin' && user.id != 'family')
                        IconButton(
                          tooltip: 'Remove user',
                          onPressed: () => _removeUser(user),
                          icon: const Icon(Icons.person_remove_rounded),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addFutureUser,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Future User'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(
    AppSettings settings, {
    bool refreshController = false,
  }) async {
    await ref.read(settingsControllerProvider.notifier).update(settings);
    ref.read(connectionManagerProvider).resetRouting();
    ref.read(controllerControllerProvider.notifier).prepareForModeChange();
    if (refreshController) {
      await ref
          .read(controllerControllerProvider.notifier)
          .refresh(reason: 'settings updated');
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  Future<void> _changePassword(AppUser user) async {
    final password = await _passwordDialog('Change ${user.name} Password');
    if (password == null || password.length < 6) return;
    await ref
        .read(authControllerProvider.notifier)
        .changePassword(user.id, password);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    }
  }

  Future<void> _addFutureUser() async {
    final result = await showDialog<_NewUserDraft>(
      context: context,
      builder: (context) => const _AddUserDialog(),
    );
    if (result == null) return;
    await ref
        .read(authControllerProvider.notifier)
        .addUser(
          name: result.name,
          role: result.role,
          password: result.password,
        );
  }

  Future<void> _removeUser(AppUser user) async {
    await ref.read(authControllerProvider.notifier).removeUser(user.id);
  }

  Future<String?> _passwordDialog(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewUserDraft {
  const _NewUserDraft({
    required this.name,
    required this.role,
    required this.password,
  });

  final String name;
  final UserRole role;
  final String password;
}

class _AddUserDialog extends StatefulWidget {
  const _AddUserDialog();

  @override
  State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.familyMember;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Future User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(
                value: UserRole.familyMember,
                child: Text('Family Member'),
              ),
              DropdownMenuItem(
                value: UserRole.administrator,
                child: Text('Administrator'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _role = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _NewUserDraft(
              name: _name.text,
              role: _role,
              password: _password.text,
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
