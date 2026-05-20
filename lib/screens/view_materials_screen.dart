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
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Slide', 'Catatan', 'Latihan', 'Lainnya'];

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
      body: Column(
        children: [
          // Widget Filter Kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text("Kategori: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // List Materi
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _materialsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Belum ada materi offline yang disimpan."));
                }

                // Logic filternya disini
                final allMaterials = snapshot.data!;
                final materials = _selectedCategory == 'Semua' 
                    ? allMaterials 
                    : allMaterials.where((m) => m['category'] == _selectedCategory).toList();

                if (materials.isEmpty) {
                  return Center(child: Text("Tidak ada materi untuk kategori $_selectedCategory."));
                }

                return ListView.builder(
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Color(0xFF4A00E0)),
                        title: Text(material['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${material['course']} • ${material['category']}"),
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
          ),
        ],
      ),
    );
  }
}