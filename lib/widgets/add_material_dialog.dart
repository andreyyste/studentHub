import 'package:flutter/material.dart';

class AddMaterialDialog extends StatefulWidget {
  final String fileName;
  final Function(String title, String course, String category) onSave;

  const AddMaterialDialog({
    super.key,
    required this.fileName,
    required this.onSave,
  });

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  late final TextEditingController _titleController;
  final TextEditingController _courseController = TextEditingController();
  String _dialogCategory = 'Slide';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.fileName.replaceAll('.pdf', ''));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Detail Materi Baru"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Judul Materi"),
            ),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: "Mata Kuliah"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _dialogCategory,
              items: ['Slide', 'Catatan', 'Latihan', 'Lainnya']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _dialogCategory = val!),
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _courseController.text.isNotEmpty) {
              Navigator.pop(context);
              widget.onSave(_titleController.text, _courseController.text, _dialogCategory);
            }
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }
}
