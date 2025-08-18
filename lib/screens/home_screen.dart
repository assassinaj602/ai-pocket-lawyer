import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/legal_analysis_provider.dart';
import '../providers/app_settings_provider.dart';
import 'results_screen.dart';
import 'saved_cases_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  List<PlatformFile> _imageFiles = [];

  @override
  void initState() {
    super.initState();
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final settingsProvider = Provider.of<AppSettingsProvider>(
      context,
      listen: false,
    );
    final analysisProvider = Provider.of<LegalAnalysisProvider>(
      context,
      listen: false,
    );

    // Convert PlatformFiles to File objects for OCR processing
    List<File>? imageFileObjects;
    if (_imageFiles.isNotEmpty) {
      try {
        imageFileObjects =
            _imageFiles
                .where((pf) => pf.path != null && pf.path!.isNotEmpty)
                .map((pf) => File(pf.path!))
                .where(
                  (file) => file.existsSync(),
                ) // Only include files that actually exist
                .toList();

        if (imageFileObjects.isEmpty) {
          // If no valid files, set to null to avoid processing
          imageFileObjects = null;
          print('Warning: No valid image files found');
        } else {
          print('Found ${imageFileObjects.length} valid image files');
        }
      } catch (e) {
        print('Error processing image files: $e');
        imageFileObjects = null; // Fallback to no images
      }
    }

    try {
      await analysisProvider.analyzeProblem(
        query: query,
        jurisdiction: settingsProvider.jurisdiction,
        userLocation: settingsProvider.userLocation,
        imageFiles: imageFileObjects,
      );

      if (mounted && analysisProvider.currentAnalysis != null) {
        FocusScope.of(context).unfocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ResultsScreen()),
          );
        });
      }
    } catch (e) {
      print('Search handling error: $e');
      // Show error to user if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pocket Lawyer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              FocusScope.of(context).unfocus();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get Legal Help',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your legal problem in plain language and get AI-powered guidance.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What\'s your legal question?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Input
                    TextField(
                      controller: _searchController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Example: My landlord entered my apartment without notice...',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Voice input',
                              icon: Icon(
                                _listening ? Icons.mic : Icons.mic_none,
                              ),
                              onPressed: _toggleListening,
                            ),
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Image attachments row
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Attach Images'),
                        ),
                        const SizedBox(width: 8),
                        if (_imageFiles.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.image, size: 18),
                            label: Text('${_imageFiles.length} selected'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    // Search Button
                    Consumer<LegalAnalysisProvider>(
                      builder: (context, provider, child) {
                        return ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _handleSearch,
                          icon:
                              provider.isLoading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.search),
                          label: Text(
                            provider.isLoading
                                ? 'Analyzing...'
                                : 'Get Legal Guidance',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current Jurisdiction
            Consumer<AppSettingsProvider>(
              builder: (context, provider, child) {
                return Card(
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Jurisdiction: ${provider.jurisdictionDisplayText}',
                    ),
                    subtitle:
                        provider.userLocation != null
                            ? Text('Location: ${provider.userLocation}')
                            : const Text('Tap to set your location'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      });
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SavedCasesScreen(),
                            ),
                          );
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            const Text('Saved Cases'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        _showLegalResourcesDialog();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            const Text('Legal Resources'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Error Display
            Consumer<LegalAnalysisProvider>(
              builder: (context, provider, child) {
                if (provider.error != null) {
                  return Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLegalResourcesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Legal Resources'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Important Disclaimer:'),
                const SizedBox(height: 8),
                const Text(
                  'This app provides general legal information only and is not a substitute for professional legal advice. Always consult with a qualified attorney for specific legal matters.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                const Text('Emergency Legal Help:'),
                const SizedBox(height: 8),
                Consumer<AppSettingsProvider>(
                  builder: (context, provider, child) {
                    if (provider.jurisdiction == 'us') {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Legal Aid: 211 (dial 2-1-1)'),
                          Text('• Emergency: 911'),
                        ],
                      );
                    } else {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• Citizens Advice: 03444 111 444'),
                          Text('• Emergency: 999'),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleListening() async {
    if (!_listening) {
      final available = await _speech.initialize();
      if (!available) return;
      setState(() => _listening = true);
      _speech.listen(
        onResult: (r) {
          setState(() {
            _searchController.text = r.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.search,
      );
    } else {
      _speech.stop();
      setState(() => _listening = false);
    }
  }

  Future<void> _pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'heic', 'webp'],
    );
    if (res == null) return;
    setState(() {
      _imageFiles = res.files;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
