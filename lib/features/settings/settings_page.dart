import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/db/app_database.dart';
import '../../providers/app_providers.dart';
import '../../services/pin_service.dart';
import '../../theme/tokens.dart';
import '../../utils/format.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final user = ref.watch(userProvider).valueOrNull;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final settings = settingsAsync.valueOrNull ??
        const AppSetting(
          id: 0,
          pinEnabled: false,
          notificationsEnabled: true,
          reminderDays: 7,
          freeMoneyWarnPesewas: 5000,
          onboardingComplete: false,
          themeMode: 'light',
        );

    if (settingsAsync.hasError) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: SplytPalette.gold, size: 36),
                const SizedBox(height: 12),
                const Text('Settings could not load', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  settingsAsync.error?.toString() ?? 'Please try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(settingsProvider),
                  style: FilledButton.styleFrom(backgroundColor: SplytPalette.gold, foregroundColor: Colors.black),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: settingsAsync.isLoading && settingsAsync.valueOrNull == null
          ? const Center(child: CircularProgressIndicator(color: SplytPalette.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
              children: [
                const SettingsSectionTitle('Profile'),
                const SizedBox(height: 8),
                SettingsPanel(
                  child: Column(
                    children: [
                      SettingsRow(
                        title: 'Name',
                        value: user?.name ?? 'You',
                        icon: Icons.person_outline_rounded,
                        onTap: () => _editName(context, ref, user?.name ?? ''),
                      ),
                      const Divider(height: 1),
                      SettingsRow(
                        title: 'Currency',
                        value: user?.currency ?? 'GHS',
                        icon: Icons.payments_outlined,
                        onTap: () => _editCurrency(context, ref, user?.currency ?? 'GHS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SettingsSectionTitle('Appearance'),
                const SizedBox(height: 8),
                SettingsPanel(
                  child: ThemeSelector(
                    selected: settings.themeMode,
                    onSelectionChanged: (value) {
                      ref.read(databaseProvider).updateSettings(
                        AppSettingsCompanion(themeMode: Value(value)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: SettingsSectionTitle('Categories')),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: FilledButton.icon(
                        onPressed: () => _addCategory(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          backgroundColor: SplytPalette.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(inherit: true),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final category in categories)
                  CategorySettingsRow(
                    name: category.systemKey == freeMoneyKey ? 'Free money' : category.name,
                    icon: category.systemKey == freeMoneyKey ? Icons.account_balance_wallet_outlined : iconForKey(category.icon),
                    protected: category.protected,
                    system: category.isSystem,
                    onProtect: () => ref.read(databaseProvider).updateCategoryLook(category.id, protected: !category.protected),
                    onDelete: () => ref.read(databaseProvider).deleteCategoryIfAllowed(category.id),
                  ),
                const SizedBox(height: 20),
                const SettingsSectionTitle('Lock & alerts'),
                const SizedBox(height: 8),
                SettingsPanel(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('PIN lock', style: TextStyle(color: Colors.black)),
                        value: settings.pinEnabled,
                        onChanged: (enabled) async {
                          if (enabled) {
                            final pin = await _askPin(context);
                            if (pin == null) return;
                            await ref.read(databaseProvider).updateSettings(
                              AppSettingsCompanion(
                                pinEnabled: const Value(true),
                                pinHash: Value(hashPin(pin)),
                              ),
                            );
                          } else {
                            await ref.read(databaseProvider).updateSettings(
                              const AppSettingsCompanion(
                                pinEnabled: Value(false),
                                pinHash: Value(null),
                              ),
                            );
                          }
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Notifications', style: TextStyle(color: Colors.black)),
                        subtitle: const Text('Income reminder + monthly recap', style: TextStyle(color: Colors.black54)),
                        value: settings.notificationsEnabled,
                        onChanged: (enabled) async {
                          await ref.read(databaseProvider).updateSettings(
                            AppSettingsCompanion(notificationsEnabled: Value(enabled)),
                          );
                          await ref.read(notificationServiceProvider).refreshSchedules();
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remind me after', style: TextStyle(color: Colors.black)),
                        subtitle: Text('${settings.reminderDays} days without income', style: const TextStyle(color: Colors.black54)),
                        onTap: () => _pickReminderDays(context, ref, settings.reminderDays),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SettingsSectionTitle('Export'),
                const SizedBox(height: 8),
                SettingsPanel(
                  onTap: () => _exportCsv(context, ref, user?.currency ?? 'GHS'),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Share this month as CSV', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                    subtitle: Text('Export your transactions', style: TextStyle(color: Colors.black54)),
                    trailing: Icon(Icons.ios_share_rounded, color: Colors.black),
                  ),
                ),
              ],
            ),
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SplytPalette.cream),
      ),
      child: child,
    );

    if (onTap == null) {
      return panel;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: panel,
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({required this.selected, required this.onSelectionChanged, super.key});

  final String selected;
  final ValueChanged<String> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('dark', 'Dark'),
      ('light', 'Light'),
      ('system', 'System'),
    ];

    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => onSelectionChanged(options[index].$1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected == options[index].$1 ? SplytPalette.goldSoft : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected == options[index].$1 ? SplytPalette.gold : Colors.black12,
                  ),
                ),
                child: Text(
                  options[index].$2,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({required this.title, required this.value, required this.icon, required this.onTap, super.key});

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: SplytPalette.gold),
      title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: const TextStyle(color: Colors.black54)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black54),
      onTap: onTap,
    );
  }
}

class CategorySettingsRow extends StatelessWidget {
  const CategorySettingsRow({required this.name, required this.icon, required this.protected, required this.system, required this.onProtect, required this.onDelete, super.key});

  final String name;
  final IconData icon;
  final bool protected;
  final bool system;
  final VoidCallback onProtect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SplytPalette.cream),
        ),
        child: Row(
          children: [
            Icon(icon, color: SplytPalette.gold, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600))),
            if (!system) ...[
              IconButton(
                tooltip: protected ? 'Remove protection' : 'Protect bucket',
                onPressed: onProtect,
                icon: Icon(protected ? Icons.shield_rounded : Icons.shield_outlined, color: Colors.black54),
              ),
              IconButton(
                tooltip: 'Delete bucket',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: SplytPalette.gold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TextValueDialog extends StatefulWidget {
  const _TextValueDialog({required this.initialValue, super.key});

  final String initialValue;

  @override
  State<_TextValueDialog> createState() => _TextValueDialogState();
}

class _TextValueDialogState extends State<_TextValueDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Your name', style: TextStyle(color: Colors.black)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          labelText: 'Name',
          labelStyle: TextStyle(color: Colors.black54),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: FilledButton.styleFrom(backgroundColor: SplytPalette.gold, foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({super.key});

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Choose a 4-digit PIN', style: TextStyle(color: Colors.black)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pinField(_first, 'PIN'),
          _pinField(_second, 'Confirm'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _first.text.length == 4 && _first.text == _second.text
              ? () => Navigator.pop(context, _first.text)
              : null,
          style: FilledButton.styleFrom(backgroundColor: SplytPalette.gold, foregroundColor: Colors.black),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        counterStyle: const TextStyle(color: Colors.black54),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SplytPalette.gold, width: 2)),
      ),
    );
  }
}

Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => _TextValueDialog(initialValue: current),
  );

  if (newName != null) {
    await ref.read(databaseProvider).updateProfile(name: newName.trim());
  }
}

Future<void> _editCurrency(BuildContext context, WidgetRef ref, String current) async {
  final picked = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Currency'),
      children: [
        for (final code in ['GHS', 'USD', 'EUR', 'GBP', 'NGN', 'KES'])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, code),
            child: Text(code == current ? '$code (current)' : code),
          ),
      ],
    ),
  );

  if (picked != null) {
    await ref.read(databaseProvider).updateProfile(currency: picked);
  }
}

Future<void> _addCategory(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New category'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
      ],
    ),
  );

  if (confirmed == true && nameController.text.trim().isNotEmpty) {
    await ref.read(databaseProvider).createCategory(
      name: nameController.text.trim(),
      icon: 'spark',
      color: SplytPalette.categorySwatches.first,
    );
  }
}

Future<String?> _askPin(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (context) => const _PinDialog(),
  );
}

Future<void> _pickReminderDays(BuildContext context, WidgetRef ref, int current) async {
  final picked = await showDialog<int>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Remind after'),
      children: [
        for (final day in [3, 5, 7, 14, 30])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, day),
            child: Text('$day days${day == current ? ' · current' : ''}'),
          ),
      ],
    ),
  );

  if (picked != null) {
    await ref.read(databaseProvider).updateSettings(
      AppSettingsCompanion(reminderDays: Value(picked)),
    );
    await ref.read(notificationServiceProvider).refreshSchedules();
  }
}

Future<void> _exportCsv(BuildContext context, WidgetRef ref, String currency) async {
  final csv = await ref.read(monthExportProvider).csvFor(DateTime.now(), currency: currency);
  final dir = await getTemporaryDirectory();
  final file = File(p.join(dir.path, 'splytwise-${DateTime.now().year}-${DateTime.now().month}.csv'));
  await file.writeAsString(csv);
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'Splytwise ${monthLabel(DateTime.now())}',
  );
}
