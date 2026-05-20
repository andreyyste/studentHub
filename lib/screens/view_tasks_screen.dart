import 'package:flutter/material.dart';
import '../models/student_task.dart';
import '../database_helper.dart';
import 'pdf_viewer_screen.dart';

class ViewTasksScreen extends StatefulWidget {
  const ViewTasksScreen({super.key});

  @override
  State<ViewTasksScreen> createState() => _ViewTasksScreenState();
}

class _ViewTasksScreenState extends State<ViewTasksScreen> {
  late Future<List<StudentTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = DatabaseHelper.instance.getAllTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Tugas Anda"),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<StudentTask>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada tugas! Santai dulu gak sih?"));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${task.course}\nDeadline: ${task.deadline.toString().substring(0, 16)}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.filePath != null)
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () async {
                          if (task.id != null) {
                            await DatabaseHelper.instance.deleteTask(task.id!);
                            _refreshTasks(); // Refresh list setelah dihapus
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    if (task.filePath != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(localPath: task.filePath!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tugas ini tidak memiliki lampiran PDF.")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}