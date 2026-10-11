import 'package:flutter/material.dart';

class NoteDraft {
  const NoteDraft({required this.title, required this.body});

  final String title;
  final String body;
}

class NoteEditorDialog extends StatefulWidget {
  const NoteEditorDialog({
    required this.dialogTitle,
    this.initialTitle = '',
    this.initialBody = '',
    super.key,
  });

  final String dialogTitle;
  final String initialTitle;
  final String initialBody;

  static Future<NoteDraft?> show(
    BuildContext context, {
    required String dialogTitle,
    String initialTitle = '',
    String initialBody = '',
  }) {
    return showDialog<NoteDraft>(
      context: context,
      builder: (context) => NoteEditorDialog(
        dialogTitle: dialogTitle,
        initialTitle: initialTitle,
        initialBody: initialBody,
      ),
    );
  }

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _bodyController = TextEditingController(text: widget.initialBody);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('note-title-field'),
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Judul'),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Judul wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('note-body-field'),
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Isi catatan'),
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              NoteDraft(
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
