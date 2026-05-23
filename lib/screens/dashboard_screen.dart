import 'package:flutter/material.dart';
import '../models/student_task.dart';
import '../models/class_schedule.dart';
import '../services/database_helper.dart';
import '../utils/schedule_helper.dart';
import '../widgets/dashboard_banner.dart';
import '../widgets/menu_card.dart';
import 'add_task_screen.dart';
import 'view_tasks_screen.dart';
import 'view_materials_screen.dart';
import 'schedule_screen.dart';
import 'elok_portal_screen.dart';
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<StudentTask> _tasks = [];
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

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

  @override
  Widget build(BuildContext context) {
    final nearestTask = getNearestTask(_tasks);
    final nearestSchedule = getNearestSchedule(_schedules);

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
                    DashboardBanner(
                      nearestTask: nearestTask,
                      nearestSchedule: nearestSchedule,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Fitur Utama",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.1,
                      children: [
                        MenuCard(
                          title: "Tambah Tugas",
                          icon: Icons.add_task,
                          color: Colors.orange,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddTaskScreen()),
                            );
                            _refreshData();
                          },
                        ),
                        MenuCard(
                          title: "Liat Tugas",
                          icon: Icons.list_alt_rounded,
                          color: Colors.green,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ViewTasksScreen()),
                            );
                            _refreshData();
                          },
                        ),
                        MenuCard(
                          title: "Materi Offline",
                          icon: Icons.library_books,
                          color: Colors.purple,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ViewMaterialsScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: "Jadwal Kuliah",
                          icon: Icons.calendar_today_rounded,
                          color: Colors.blue,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ScheduleScreen()),
                            );
                            _refreshData();
                          },
                        ),
                        MenuCard(
                          title: "Portal eLOK",
                          icon: Icons.language_rounded,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ElokPortalScreen()),
                            );
                          },
                        ),
                        MenuCard(
                          title: "Tanya AI",
                          icon: Icons.auto_awesome,
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
