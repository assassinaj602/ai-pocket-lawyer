import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/case_provider.dart';
import '../../models/case_models.dart';
import 'edit_case_screen.dart';
import 'case_detail_screen.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cases')),
      body: Consumer<CaseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.cases.isEmpty) {
            return Center(
              child: Text(
                'No cases yet. Tap + to create one.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: provider.cases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final c = provider.cases[index];
              return Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle: Text(
                    '${c.category} • Updated ${_ago(c.updatedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CaseDetailScreen(caseRecord: c),
                        ),
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<CaseProvider>();
          final created = await Navigator.push<CaseRecord?>(
            context,
            MaterialPageRoute(
              builder: (_) => EditCaseScreen(initial: provider.newBlankCase()),
            ),
          );
          if (created != null) {
            await context.read<CaseProvider>().addOrUpdateCase(created);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
