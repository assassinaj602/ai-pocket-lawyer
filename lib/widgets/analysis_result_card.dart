import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

class AnalysisResultCard extends StatelessWidget {
  final LegalAnalysisResult analysis;
  final VoidCallback? onTap;

  const AnalysisResultCard({super.key, required this.analysis, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with jurisdiction and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(analysis.jurisdiction.toUpperCase()),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                  ),
                  Text(
                    _formatDate(analysis.timestamp),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Query
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildStatItem(
                    context,
                    Icons.list_alt,
                    '${analysis.stepByStepActions.length} Actions',
                  ),
                  const SizedBox(width: 16),
                  if (analysis.generatedLetter != null)
                    _buildStatItem(context, Icons.description, 'Letter'),
                  const SizedBox(width: 16),
                  if (analysis.relevantContacts.isNotEmpty)
                    _buildStatItem(
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

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
