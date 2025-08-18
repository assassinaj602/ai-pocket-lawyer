import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/app_settings_provider.dart';
import 'root_nav.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  void _finishOnboarding(BuildContext context) async {
    await StorageService.setFirstTimeUser(false);
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const RootNav()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = Provider.of<AppSettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.gavel,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'AI Pocket Lawyer',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Get clear, practical legal guidance in minutes.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'How this app helps you',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _bullet(
                          context,
                          'Describe your legal question in plain language.',
                        ),
                        _bullet(
                          context,
                          'Choose your jurisdiction (US or UK) in Settings.',
                        ),
                        _bullet(
                          context,
                          'Get a clear, step-by-step AI summary with helpful links.',
                        ),
                        _bullet(
                          context,
                          'Open links directly; copy or share your results easily.',
                        ),

                        const SizedBox(height: 20),
                        Divider(color: theme.dividerColor.withOpacity(0.4)),
                        const SizedBox(height: 12),

                        Text(
                          'Tips',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _tip(
                          context,
                          Icons.description,
                          'Be specific about dates, notices, and amounts.',
                        ),
                        _tip(
                          context,
                          Icons.fact_check,
                          'Use the Recommended Actions list to proceed.',
                        ),
                        _tip(
                          context,
                          Icons.info_outline,
                          'This is general information, not legal advice.',
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                final mode = app.themeMode;
                app.setThemeMode(
                  mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                );
              },
              icon: const Icon(Icons.brightness_6),
              tooltip: 'Toggle Theme',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _finishOnboarding(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '• $text',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _tip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: theme.primaryColor),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
