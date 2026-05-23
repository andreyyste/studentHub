import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';
import '../widgets/save_pdf_dialog.dart'; 
import '../models/student_task.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? pdfUrl;
  final String? cookie;
  final String? localPath; 

  const PdfViewerScreen({
    super.key,
    this.pdfUrl,
    this.cookie,
    this.localPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool isDownloading = false;

  // Status internal
  double _downloadProgress = 0.0;

  /// Mengelola proses pengunduhan PDF ke memori fisik (Storage) dan menyimpan rekamannya di basis data
  Future<void> _downloadAndSavePdf(String type, String title, String course, DateTime? deadline, String category) async {
    if (widget.pdfUrl == null || widget.cookie == null) return;

    setState(() {
      isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      String cleanTitle = title.replaceAll(' ', '_');
      String fileName = "${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      String savePath = "${dir.path}/$fileName";

      var dio = Dio();
      await dio.download(
        widget.pdfUrl!,
        savePath,
        options: Options(headers: {'Cookie': widget.cookie}),
      );

      if (type == 'tugas') {
        // Mewariskan detail entitas 'tugas' ke database dengan lampiran berkas lokal dan tenggat waktu
        final newTask = StudentTask(
          title: _titleController.text,
          course: _courseController.text,
          deadline: _selectedDeadline!, 
          filePath: savePath, 
        );
        
        await DatabaseHelper.instance.insertTask(newTask);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Tugas beserta PDF berhasil disimpan!")),
           );
        }

      } else if (type == 'materi') {
        await DatabaseHelper.instance.insertMaterial(
          _titleController.text, 
          _courseController.text, 
          _selectedCategory, 
          savePath
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Materi offline berhasil disimpan!")),
          );
        }
      }

    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Gagal download: $e")),
         );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // --- ANTARMUKA DIALOG FORMULIR PENYIMPANAN PDF ---
  void _showDownloadDialog(String type) {
    // Mereset variabel inputan dan logika form setiap kali jendela dialog terbuka
    _titleController.clear();
    _courseController.clear();
    _selectedDeadline = null; 

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Simpan sebagai $type"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: type == 'tugas' ? "Judul Tugas" : "Judul Materi",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _courseController,
                    decoration: const InputDecoration(labelText: "Nama Mata Kuliah"),
                  ),
                  const SizedBox(height: 10),
                  
                  // Secara dinamis memunculkan selektor tenggat waktu jika pengklasifikasiannya adalah 'Tugas'
                  if (type == 'tugas')
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
                            // Memicu rendering antarmuka internal dialog agar tenggat waktu baru tertampilkan
                            setStateDialog(() {
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

                  // Secara dinamis memunculkan opsi turunan 'Kategori' jika pengklasifikasiannya adalah 'Materi'
                  if (type == 'materi')
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Kategori"),
                      value: _selectedCategory,
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setStateDialog(() {
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
                    // Validasi khusus: Formulir pengisian tidak boleh kosong saat menampung status penugasan
                    if (type == 'tugas' && _selectedDeadline == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih deadline-nya dulu bro!')),
                      );
                      return;
                    }
                    Navigator.pop(context); 
                    _downloadAndSavePdf(type); 
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Isi judul sama matkulnya dulu!')),
                      );
                  }
                },
                child: const Text('Download & Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showSaveOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Simpan sebagai Tugas'),
              onTap: () {
                Navigator.pop(context);
                _showDownloadDialog('tugas'); 
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Simpan sebagai Materi'),
              onTap: () {
                Navigator.pop(context);
                _showDownloadDialog('materi'); 
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = widget.localPath != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLocal ? "Dokumen Lokal" : "Materi eLOK", style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF4A00E0),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          isLocal
              ? SfPdfViewer.file(File(widget.localPath!))
              : SfPdfViewer.network(widget.pdfUrl!, headers: {'Cookie': widget.cookie!}),
          if (isDownloading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isLocal
          ? null
          : FloatingActionButton(
              onPressed: isDownloading ? null : _showSaveOptions,
              backgroundColor: const Color(0xFF4A00E0),
              child: const Icon(Icons.download, color: Colors.white),
            ),
    );
  }
}