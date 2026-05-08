import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'pdf_viewer_screen.dart';

class ViewMaterialsScreen extends StatefulWidget {
  const ViewMaterialsScreen({super.key});

  @override
  State<ViewMaterialsScreen> createState() => _ViewMaterialsScreenState();
}

class _ViewMaterialsScreenState extends State<ViewMaterialsScreen> {
  late Future<List<Map<String, dynamic>>> _materialsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMaterials();
  }

  void _refreshMaterials() {
    setState(() {
      _materialsFuture = DatabaseHelper.instance.getAllMaterials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materi Kuliah Terunduh"),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _materialsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada materi offline yang disimpan."));
          }

          final materials = snapshot.data!;
          return ListView.builder(
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Color(0xFF4A00E0)),
                  title: Text(material['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(material['course']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () async {
                      await DatabaseHelper.instance.deleteMaterial(material['id']);
                      _refreshMaterials();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(localPath: material['filePath']),
                      ),
                    );
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