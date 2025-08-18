import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/case_models.dart';
import '../../providers/case_provider.dart';
import 'edit_case_screen.dart';
import '../pdf_share_screen.dart';

class CaseDetailScreen extends StatelessWidget {
  final CaseRecord caseRecord;
  const CaseDetailScreen({super.key, required this.caseRecord});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(caseRecord.title),
        actions: [
          IconButton(
            tooltip: 'Share PDF Summary',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfShareScreen(caseRecord: caseRecord),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<CaseRecord?>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCaseScreen(initial: caseRecord),
                ),
              );
              if (updated != null) {
                await context.read<CaseProvider>().addOrUpdateCase(updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Delete case?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );
              if (confirm == true) {
                await context.read<CaseProvider>().deleteCase(caseRecord.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kv('Category', caseRecord.category),
          const SizedBox(height: 8),
          _kv(
            'Description',
            caseRecord.description.isEmpty ? '—' : caseRecord.description,
          ),
          const SizedBox(height: 8),
          _kv('Notes', caseRecord.notes.isEmpty ? '—' : caseRecord.notes),
          const SizedBox(height: 16),
          Text(
            'Deadlines',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (caseRecord.deadlines.isEmpty) const Text('No deadlines added.'),
          ...caseRecord.deadlines.map(
            (d) => ListTile(
              leading: Icon(d.completed ? Icons.check_circle : Icons.schedule),
              title: Text(d.title),
              subtitle: Text('${d.dueDate.toLocal()}'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Attachments',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (caseRecord.attachments.isEmpty) const Text('No attachments yet.'),
          ...caseRecord.attachments.map(
            (a) => ListTile(
              leading: const Icon(Icons.attachment),
              title: Text(a.name),
              subtitle: Text(a.path),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(v),
      ],
    );
  }
}
