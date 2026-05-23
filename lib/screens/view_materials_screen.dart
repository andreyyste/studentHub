import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';
import '../widgets/material_card.dart';
import '../widgets/add_material_dialog.dart';
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

  /// Mengeksekusi modul pengelola file sistem (File Picker) untuk memilih dokumen dari luar lingkup aplikasi.
  Future<void> _addMaterialFromDevice() async {
    // Menggunakan alias (namespace) 'fp.' agar tidak memunculkan konflik kelas dengan elemen antarmuka Flutter
    fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
      type: fp.FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File originalFile = File(result.files.single.path!);
      String fileName = result.files.single.name;
      
      // Membuka jendela dialog interaktif untuk mendefinisikan label (judul dan matkul) dokumen
      _showMaterialDetailsDialog(originalFile, fileName);
    }
  }

  /// Menampilkan dialog popup formulir kelengkapan keterangan dari dokumen materi yang baru diunggah.
  void _showMaterialDetailsDialog(File originalFile, String fileName) {
    showDialog(
      context: context,
      builder: (context) {
        return AddMaterialDialog(
          fileName: fileName,
          onSave: (title, course, category) async {
            // 1. Menggandakan data file ke dalam penyimpanan terisolasi yang hanya dapat diakses oleh aplikasi
            Directory appDocDir = await getApplicationDocumentsDirectory();
            String newFilePath = '${appDocDir.path}/$fileName';
            await originalFile.copy(newFilePath);

            // 2. Meregistrasikan informasi struktural materi ke dalam database lokal
            await DatabaseHelper.instance.insertMaterial(
              title,
              course,
              category,
              newFilePath,
            );

            _refreshMaterials();
          },
        );
      },
    );
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
                            // Mengeksekusi delegasi penghapusan file baik dari tabel SQL maupun fisik memori lokal
                            File(material['filePath']).deleteSync(); 
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
      // Tombol Tindakan Mengambang (Floating Action Button) untuk memulai rutinitas penambahan file secara manual
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMaterialFromDevice,
        icon: const Icon(Icons.add),
        label: const Text("File PDF"),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
    );
  }
}