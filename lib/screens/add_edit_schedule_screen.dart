import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../database_helper.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final ClassSchedule? schedule;
  final String defaultSemester;

  const AddEditScheduleScreen({
    super.key,
    this.schedule,
    required this.defaultSemester,
  });

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  // Pengendali (Controllers) untuk input teks
  final _courseController = TextEditingController();
  final _roomController = TextEditingController();
  
  // Variabel penampung state (status) formulir
  String _selectedDay = "Senin";
  late String _selectedSemester;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isMakeup = false;
  bool _isCancelled = false;

  final List<String> _days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat"];
  final List<String> _semesters = [
    "Semester 1",
    "Semester 2",
    "Semester 3",
    "Semester 4",
    "Semester 5",
    "Semester 6",
    "Semester 7",
    "Semester 8",
  ];

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.defaultSemester;

    // Jika mode edit (schedule tidak null), inisialisasi form dengan data yang sudah ada
    if (widget.schedule != null) {
      _courseController.text = widget.schedule!.course;
      _roomController.text = widget.schedule!.room;
      _selectedDay = widget.schedule!.day;
      _selectedSemester = widget.schedule!.semester;
      _isMakeup = widget.schedule!.isMakeup;
      _isCancelled = widget.schedule!.isCancelled;

      final startParts = widget.schedule!.startTime.split(":");
      _startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );

      final endParts = widget.schedule!.endTime.split(":");
      _endTime = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );
    }
  }

  /// Menampilkan dialog pemilih waktu (Time Picker) untuk jam mulai atau selesai.
  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  /// Memformat objek TimeOfDay menjadi string dengan format HH:MM.
  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return "Pilih Jam";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Jadwal" : "Tambah Jadwal"),
        actions: [
          // Menampilkan tombol hapus hanya jika dalam mode edit
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await DatabaseHelper.instance.deleteSchedule(
                  widget.schedule!.id!,
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: "Nama Mata Kuliah"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: "Ruangan"),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSemester,
                    decoration: const InputDecoration(labelText: "Semester"),
                    items: _semesters
                        .map(
                          (sem) =>
                              DropdownMenuItem(value: sem, child: Text(sem)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSemester = val!),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(labelText: "Hari"),
                    items: _days
                        .map(
                          (day) =>
                              DropdownMenuItem(value: day, child: Text(day)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDay = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Mulai",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      _formatTimeOfDay(_startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Selesai",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    subtitle: Text(
                      _formatTimeOfDay(_endTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text("Ini Kelas Pengganti?"),
              value: _isMakeup,
              onChanged: (val) => setState(() => _isMakeup = val),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.orange,
            ),

            if (isEditing)
              SwitchListTile(
                title: const Text(
                  "Dosen Kosong / Batal?",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: _isCancelled,
                onChanged: (val) => setState(() => _isCancelled = val),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: Colors.redAccent,
              ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF4A00E0),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Validasi kelengkapan form sebelum menyimpan
                if (_courseController.text.isEmpty ||
                    _startTime == null ||
                    _endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Isi formnya yang lengkap bro!"),
                    ),
                  );
                  return;
                }

                // Membangun objek jadwal berdasarkan data yang diinput
                final newSchedule = ClassSchedule(
                  id: isEditing ? widget.schedule!.id : null,
                  course: _courseController.text,
                  room: _roomController.text,
                  day: _selectedDay,
                  semester: _selectedSemester,
                  startTime: _formatTimeOfDay(_startTime),
                  endTime: _formatTimeOfDay(_endTime),
                  isMakeup: _isMakeup,
                  isCancelled: _isCancelled,
                );

                // Menyimpan atau memperbarui data ke dalam database
                if (isEditing) {
                  await DatabaseHelper.instance.updateSchedule(newSchedule);
                } else {
                  await DatabaseHelper.instance.insertSchedule(newSchedule);
                }

                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                isEditing ? "Simpan Perubahan" : "Simpan ke Database",
              ),
            ),
          ],
        ),
      ),
    );
  }
}