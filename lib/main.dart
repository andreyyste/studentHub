import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async { 
  // Memastikan binding Flutter telah diinisialisasi sebelum menjalankan fungsi asinkron.
  WidgetsFlutterBinding.ensureInitialized();

  // Memuat konfigurasi variabel lingkungan dari file .env.
  await dotenv.load(fileName: ".env");

  // Inisialisasi SQLite FFI secara spesifik untuk lingkungan desktop (Windows/Linux).
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// Enumerasi untuk melacak status ekspansi kartu pada dashboard.
enum ExpandedCard { none, task, schedule }

// ==========================================
// TAMPILAN DASHBOARD
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<StudentTask> _tasks = [];
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;

  ExpandedCard _currentExpanded = ExpandedCard.none;

  // Mengatur animasi ekspansi kartu informasi (Tugas atau Jadwal).
  void _toggleExpand(ExpandedCard card) {
    setState(() {
      if (_currentExpanded == card) {
        _currentExpanded = ExpandedCard.none;
      } else {
        _currentExpanded = card;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Mengambil data terbaru untuk tugas dan jadwal dari database lokal (SQLite).
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final tasks = await DatabaseHelper.instance.getAllTasks();
    final schedules = await DatabaseHelper.instance.getAllSchedules();
    setState(() {
      _tasks = tasks;
      _schedules = schedules;
      _isLoading = false;
    });
  }

  // Mengambil tugas dengan tenggat waktu paling dekat.
  StudentTask? getNearestTask() {
    if (_tasks.isEmpty) return null;
    return _tasks.first;
  }

  // Mencari jadwal kelas terdekat yang akan datang pada hari ini.
  ClassSchedule? getNearestSchedule() {
    if (_schedules.isEmpty) return null;

    List<String> hari = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    String hariIni = hari[DateTime.now().weekday - 1];

    // Memfilter jadwal berdasarkan hari ini dan status pembatalan.
    var jadwalHariIni = _schedules
        .where((s) => s.day == hariIni && !s.isCancelled)
        .toList();
    if (jadwalHariIni.isEmpty) return null;

    // Mengurutkan jadwal berdasarkan waktu mulai terawal.
    jadwalHariIni.sort((a, b) => a.startTime.compareTo(b.startTime));

    final now = TimeOfDay.now();
    final nowInMinutes = (now.hour * 60) + now.minute;

    // Menentukan kelas yang sedang berjalan atau akan datang.
    for (var jadwal in jadwalHariIni) {
      final endParts = jadwal.endTime.split(":");
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      final endInMinutes = (endHour * 60) + endMinute;
      if (nowInMinutes <= endInMinutes) {
        return jadwal;
      }
    }

    return null;
  }

  // Memformat representasi string tenggat waktu berdasarkan selisih hari.
  String _formatWaktu(DateTime deadline) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final hariTugas = DateTime(deadline.year, deadline.month, deadline.day);

    final selisihHari = hariTugas.difference(hariIni).inDays;

    final jam =
        "${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}";

    if (selisihHari == 0) {
      return "Hari ini jam $jam";
    } else if (selisihHari == 1) {
      return "Besok jam $jam";
    } else if (selisihHari == 2) {
      return "Lusa jam $jam";
    } else {
      return "Tanggal ${deadline.day}/${deadline.month} jam $jam";
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearestTask = getNearestTask();
    final nearestSchedule = getNearestSchedule();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Utama (Greeting & Ringkasan)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hi, Bro!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ------------------------------------------
                              // Kartu Informasi: Tugas Mendesak
                              // ------------------------------------------
                              Expanded(
                                flex: _currentExpanded == ExpandedCard.task
                                    ? 3
                                    : 1,
                                child: GestureDetector(
                                  onTap: () => _toggleExpand(ExpandedCard.task),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.yellowAccent,
                                              size: 16,
                                            ),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                "Tugas Mepet",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                _currentExpanded ==
                                                    ExpandedCard.task
                                                ? 16
                                                : 13,
                                          ),
                                          child: Text(
                                            nearestTask?.title ??
                                                "Aman no tugas!",
                                            maxLines:
                                                _currentExpanded ==
                                                    ExpandedCard.task
                                                ? 3
                                                : 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (nearestTask != null)
                                          Text(
                                            _formatWaktu(nearestTask.deadline),
                                            style: const TextStyle(
                                              color: Colors.yellowAccent,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: _currentExpanded != ExpandedCard.none
                                    ? 0
                                    : 5,
                              ),

                              // ------------------------------------------
                              // Kartu Informasi: Jadwal Kelas Terdekat
                              // ------------------------------------------
                              Expanded(
                                flex: _currentExpanded == ExpandedCard.schedule
                                    ? 3
                                    : 1,
                                child: GestureDetector(
                                  onTap: () =>
                                      _toggleExpand(ExpandedCard.schedule),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                    margin: const EdgeInsets.only(left: 0),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.class_,
                                              color: Colors.lightBlueAccent,
                                              size: 16,
                                            ),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                "Next Kelas",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                _currentExpanded ==
                                                    ExpandedCard.schedule
                                                ? 16
                                                : 13,
                                          ),
                                          child: Text(
                                            nearestSchedule?.course ??
                                                "Free Class!",
                                            maxLines:
                                                _currentExpanded ==
                                                    ExpandedCard.schedule
                                                ? 3
                                                : 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (nearestSchedule != null)
                                          Text(
                                            "${nearestSchedule.startTime} di ${nearestSchedule.room}",
                                            style: const TextStyle(
                                              color: Colors.lightBlueAccent,
                                              fontSize: 11,
                                            ),
                                            maxLines:
                                                _currentExpanded ==
                                                    ExpandedCard.schedule
                                                ? 2
                                                : 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Fitur Utama",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Grid Menu Navigasi
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                      children: [
                        _buildMenuCard(
                          context,
                          "Tambah Tugas",
                          Icons.add_task,
                          Colors.orange,
                        ),
                        _buildMenuCard(
                          context,
                          "Liat Tugas",
                          Icons.list_alt_rounded,
                          Colors.green,
                        ),
                        _buildMenuCard(
                          context,
                          "Materi Offline", 
                          Icons.library_books,
                          Colors.purple,
                        ),
                        _buildMenuCard(
                          context,
                          "Jadwal Kuliah",
                          Icons.calendar_today_rounded,
                          Colors.blue,
                        ),
                        _buildMenuCard(
                          context,
                          "Portal eLOK",
                          Icons.language_rounded,
                          Colors.indigo,
                        ),
                        _buildMenuCard(
                          context,
                          "Tanya AI",
                          Icons.auto_awesome,
                          Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // Widget pembantu (helper) untuk membuat kartu menu dan logika navigasinya.
  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () async {
        // Melakukan rute navigasi berdasarkan judul kartu menu yang ditekan.
        if (title == "Tambah Tugas") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
          _refreshData();
        } else if (title == "Liat Tugas") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewTasksScreen()),
          );
          _refreshData();
        } else if (title == "Materi Offline") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewMaterialsScreen()),
          );
        } else if (title == "Jadwal Kuliah") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleScreen()),
          );
          _refreshData();
        } else if (title == "Portal eLOK") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ElokPortalScreen()),
          );
        } else if (title == "Tanya AI") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}