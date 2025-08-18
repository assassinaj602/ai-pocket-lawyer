import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/case_models.dart';

class AttachmentPicker extends StatelessWidget {
  final List<CaseAttachment> attachments;
  final ValueChanged<List<CaseAttachment>> onChanged;
  const AttachmentPicker({
    super.key,
    required this.attachments,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final now = DateTime.now();
    final newItems = result.files.map(
      (f) => CaseAttachment(
        id: const Uuid().v4(),
        name: f.name,
        path: f.path ?? f.identifier ?? f.name,
        addedAt: now,
      ),
    );
    onChanged([...attachments, ...newItems]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Attachments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.attach_file),
              label: const Text('Add'),
            ),
          ],
        ),
        if (attachments.isEmpty) const Text('No attachments yet.'),
        ...attachments.map(
          (a) => ListTile(
            dense: true,
            leading: const Icon(Icons.insert_drive_file),
            title: Text(a.name),
            subtitle: Text(a.path),
          ),
        ),
      ],
    );
  }
}
