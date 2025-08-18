import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/app_settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // AI Configuration: API Key
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI Configuration',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide your OpenRouter API key if the app cannot read .env (common on web hosting). The key is stored only on this device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final saved = StorageService.getApiKey();
                          final masked =
                              (saved == null || saved.isEmpty)
                                  ? 'Not set'
                                  : '${saved.substring(0, 8)}•••${saved.substring(saved.length - 4)}';
                          return Row(
                            children: [
                              Expanded(child: Text('OpenRouter Key: $masked')),
                              TextButton.icon(
                                onPressed: () async {
                                  final ctrl = TextEditingController(
                                    text: saved,
                                  );
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (_) => AlertDialog(
                                          title: const Text(
                                            'Set OpenRouter API Key',
                                          ),
                                          content: TextField(
                                            controller: ctrl,
                                            decoration: const InputDecoration(
                                              labelText: 'sk-or-…',
                                            ),
                                            obscureText: true,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                  );
                                  if (ok == true) {
                                    await StorageService.setApiKey(
                                      ctrl.text.trim(),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('API key saved.'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Set/Update'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Jurisdiction Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Legal Jurisdiction',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select your country to get relevant legal information',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...provider.availableJurisdictions.map((jurisdiction) {
                        return RadioListTile<String>(
                          title: Text(jurisdiction['name']!),
                          value: jurisdiction['code']!,
                          groupValue: provider.jurisdiction,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setJurisdiction(value);
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Settings Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'App Settings',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Theme Mode Selection
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Theme Mode',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Theme Mode Options
                      Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: const Text('Light Mode'),
                            subtitle: const Text('Always use light theme'),
                            value: ThemeMode.light,
                            groupValue: provider.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                provider.setThemeMode(value);
                              }
                            },
                            dense: true,
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Always use dark theme'),
                            value: ThemeMode.dark,
                            groupValue: provider.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                provider.setThemeMode(value);
                              }
                            },
                            dense: true,
                          ),
                          RadioListTile<ThemeMode>(
                            title: const Text('System Mode'),
                            subtitle: const Text('Follow system preference'),
                            value: ThemeMode.system,
                            groupValue: provider.themeMode,
                            onChanged: (ThemeMode? value) {
                              if (value != null) {
                                provider.setThemeMode(value);
                              }
                            },
                            dense: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AI Status Section (showing it's always enabled)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI Features',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI Enhanced Legal Guidance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Powered by advanced AI with real-time legal information',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // About Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'About',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.app_registration),
                        title: const Text('AI Pocket Lawyer'),
                        subtitle: const Text('Version 1.0.0'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Powered by'),
                        subtitle: const Text(
                          'OpenRouter AI & Real-time Legal Data',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Legal Disclaimer
              Card(
                elevation: 2,
                child: ExpansionTile(
                  leading: Icon(Icons.warning, color: Colors.orange[600]),
                  title: const Text('Important Legal Disclaimer'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Educational Purpose Only',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This app provides general legal information for educational purposes only and is NOT a substitute for professional legal advice.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Important Notes:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Information may not be current or complete\n'
                            '• Laws vary by jurisdiction and change frequently\n'
                            '• Individual circumstances affect legal outcomes\n'
                            '• This app does not create an attorney-client relationship\n'
                            '• ALWAYS consult with a qualified attorney for specific legal advice',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
