import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/legal_analysis_provider.dart';
import '../models/analysis_result.dart';
import 'results_screen.dart';

class SavedCasesScreen extends StatelessWidget {
  const SavedCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Cases'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<LegalAnalysisProvider>(
            builder: (context, provider, child) {
              if (provider.savedAnalyses.isNotEmpty) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear_all') {
                      _showClearAllDialog(context, provider);
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'clear_all',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Clear All',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<LegalAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.savedAnalyses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No saved cases yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your legal analyses will be saved here automatically',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.savedAnalyses.length,
            itemBuilder: (context, index) {
              final analysis = provider.savedAnalyses[index];
              return _buildCaseCard(context, analysis, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildCaseCard(
    BuildContext context,
    LegalAnalysisResult analysis,
    LegalAnalysisProvider provider,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          provider.setCurrentAnalysis(analysis);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ResultsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and jurisdiction
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(analysis.jurisdiction.toUpperCase()),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                  ),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(analysis.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteDialog(context, analysis, provider);
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        child: const Icon(Icons.more_vert),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Query preview
              Text(
                analysis.userQuery,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Rights summary preview
              Text(
                analysis.rightsSummary,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Quick stats
              Row(
                children: [
                  _buildStatChip(
                    context,
                    Icons.list_alt,
                    '${analysis.stepByStepActions.length} Actions',
                  ),
                  const SizedBox(width: 8),
                  if (analysis.generatedLetter != null)
                    _buildStatChip(
                      context,
                      Icons.description,
                      'Letter Template',
                    ),
                  const SizedBox(width: 8),
                  if (analysis.relevantContacts.isNotEmpty)
                    _buildStatChip(
                      context,
                      Icons.contact_phone,
                      '${analysis.relevantContacts.length} Contacts',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    LegalAnalysisResult analysis,
    LegalAnalysisProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Case'),
            content: const Text(
              'Are you sure you want to delete this saved case? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  provider.deleteAnalysis(analysis.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Case deleted')));
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    LegalAnalysisProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Cases'),
            content: const Text(
              'Are you sure you want to delete all saved cases? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  provider.clearAllAnalyses();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All cases cleared')),
                  );
                },
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
