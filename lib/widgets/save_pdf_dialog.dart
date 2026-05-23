import 'package:flutter/material.dart';

class SavePdfDialog extends StatefulWidget {
  final String type;
  final Function(String title, String course, DateTime? deadline, String category) onSave;

  const SavePdfDialog({
    super.key,
    required this.type,
    required this.onSave,
  });

  @override
  State<SavePdfDialog> createState() => _SavePdfDialogState();
}

class _SavePdfDialogState extends State<SavePdfDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  String _selectedCategory = 'Slide';
  final List<String> _categories = ['Slide', 'Catatan', 'Latihan', 'Lainnya'];
  DateTime? _selectedDeadline;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Simpan sebagai ${widget.type}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: widget.type == 'tugas' ? "Judul Tugas" : "Judul Materi",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: "Nama Mata Kuliah"),
            ),
            const SizedBox(height: 10),
            if (widget.type == 'tugas')
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDeadline == null
                      ? "Pilih Deadline"
                      : "${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}",
                ),
                trailing: const Icon(Icons.calendar_month, color: Color(0xFF4A00E0)),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        _selectedDeadline = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
            if (widget.type == 'materi')
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Kategori"),
                initialValue: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  }
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _courseController.text.isNotEmpty) {
              if (widget.type == 'tugas' && _selectedDeadline == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pilih deadline-nya dulu bro!')),
                );
                return;
              }
              if (mounted) Navigator.pop(context);
              widget.onSave(
                _titleController.text,
                _courseController.text,
                _selectedDeadline,
                _selectedCategory,
              );
            } else {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Isi judul sama matkulnya dulu!')),
              );
            }
          },
          child: const Text('Download & Simpan'),
        ),
      ],
    );
  }
}
