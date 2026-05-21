import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../database_helper.dart';
import 'add_edit_schedule_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ClassSchedule> mySchedule = [];
  bool _isLoading = true;
  String _activeSemester = "Semester 2";

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
    _refreshSchedules();
  }

  /// Mengambil data jadwal kelas terbaru dari database berdasarkan semester yang sedang aktif.
  Future<void> _refreshSchedules() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getSchedulesBySemester(
      _activeSemester,
    );
    setState(() {
      mySchedule = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Membangun navigasi berbasis tab (TabBar) yang menampung 5 hari kerja (Senin - Jumat)
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _activeSemester,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              items: _semesters.map((String sem) {
                return DropdownMenuItem<String>(value: sem, child: Text(sem));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _activeSemester = newValue);
                  _refreshSchedules();
                }
              },
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Senin"),
              Tab(text: "Selasa"),
              Tab(text: "Rabu"),
              Tab(text: "Kamis"),
              Tab(text: "Jumat"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildDaySchedule("Senin"),
                  _buildDaySchedule("Selasa"),
                  _buildDaySchedule("Rabu"),
                  _buildDaySchedule("Kamis"),
                  _buildDaySchedule("Jumat"),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddEditScheduleScreen(defaultSemester: _activeSemester),
              ),
            );
            _refreshSchedules();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Membangun antarmuka representasi daftar jadwal berdasarkan input hari (Senin, Selasa, dsb.).
  Widget _buildDaySchedule(String day) {
    // Memfilter data jadwal keseluruhan dengan kecocokan pada variabel "hari" yang spesifik
    final todaySchedule = mySchedule.where((s) => s.day == day).toList();

    if (todaySchedule.isEmpty) {
      return Center(
        child: Text(
          "Kosong nih hari $day, gas ngopi!",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: todaySchedule.length,
      itemBuilder: (context, index) {
        final item = todaySchedule[index];
        final isBatal = item.isCancelled;

        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditScheduleScreen(
                  schedule: item,
                  defaultSemester: _activeSemester,
                ),
              ),
            );
            _refreshSchedules();
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            // Mengubah palet warna elemen antarmuka apabila kelas bersifat dibatalkan atau kelas pengganti
            color: isBatal
                ? Colors.grey.shade200
                : (item.isMakeup ? Colors.orange.shade50 : Colors.white),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Text(
                        item.startTime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isBatal
                              ? Colors.grey
                              : const Color(0xFF4A00E0),
                          decoration: isBatal
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const Text("|", style: TextStyle(color: Colors.grey)),
                      Text(
                        item.endTime,
                        style: TextStyle(
                          color: Colors.grey,
                          decoration: isBatal
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.course,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isBatal ? Colors.grey : Colors.black,
                            decoration: isBatal
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: isBatal
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              item.room,
                              style: TextStyle(
                                color: isBatal
                                    ? Colors.grey.shade400
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        // Render badge visual (label penanda) terkait status operasional jadwal khusus
                        if (isBatal || item.isMakeup) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (isBatal)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "DIBATALKAN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (isBatal && item.isMakeup)
                                const SizedBox(width: 5),
                              if (item.isMakeup)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "KELAS PENGGANTI",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}