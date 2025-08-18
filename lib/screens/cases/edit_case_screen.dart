import 'package:flutter/material.dart';
import '../../models/case_models.dart';
import '../../widgets/attachment_picker.dart';
import 'package:uuid/uuid.dart';

class EditCaseScreen extends StatefulWidget {
  final CaseRecord initial;
  const EditCaseScreen({super.key, required this.initial});

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  late TextEditingController _title;
  late TextEditingController _category;
  late TextEditingController _description;
  late TextEditingController _notes;
  late List<CaseAttachment> _attachments;
  late List<CaseDeadline> _deadlines;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _category = TextEditingController(text: widget.initial.category);
    _description = TextEditingController(text: widget.initial.description);
    _notes = TextEditingController(text: widget.initial.notes);
    _attachments = List.of(widget.initial.attachments);
    _deadlines = List.of(widget.initial.deadlines);
  }

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.initial.copyWith(
      title: _title.text.trim().isEmpty ? 'Untitled Case' : _title.text.trim(),
      category:
          _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
      description: _description.text.trim(),
      notes: _notes.text.trim(),
      attachments: _attachments,
      deadlines: _deadlines,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, updated);
  }

  Future<void> _addDeadlineDialog() async {
    final titleCtrl = TextEditingController();
    DateTime? due;
    final added = await showDialog<CaseDeadline>(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('Add deadline'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              due == null
                                  ? 'Pick due date'
                                  : due!.toLocal().toString(),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: now.subtract(
                                  const Duration(days: 3650),
                                ),
                                lastDate: now.add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setStateDialog(() => due = picked);
                              }
                            },
                            child: const Text('Choose'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        if (t.isEmpty || due == null) return;
                        Navigator.pop(
                          context,
                          CaseDeadline(
                            id: const Uuid().v4(),
                            title: t,
                            dueDate: due!,
                            completed: false,
                          ),
                        );
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
    if (added != null) {
      setState(() => _deadlines = [..._deadlines, added]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Case'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Category (e.g., Housing, Employment, Consumer)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Short description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 8,
          ),
          const SizedBox(height: 16),
          AttachmentPicker(
            attachments: _attachments,
            onChanged: (list) => setState(() => _attachments = list),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Deadlines',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addDeadlineDialog,
                icon: const Icon(Icons.add_alert),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_deadlines.isEmpty) const Text('No deadlines yet.'),
          ..._deadlines.map(
            (d) => CheckboxListTile(
              value: d.completed,
              onChanged: (v) {
                setState(() {
                  final idx = _deadlines.indexWhere((e) => e.id == d.id);
                  if (idx >= 0) {
                    _deadlines[idx] = d.copyWith(completed: v ?? d.completed);
                  }
                });
              },
              title: Text(d.title),
              subtitle: Text('Due ${d.dueDate.toLocal()}'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
