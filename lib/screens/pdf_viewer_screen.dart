import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart'; 
import '../models/student_task.dart'; // Wajib di-import biar StudentTask jalan

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

  // Form Controller untuk Popup
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  String _selectedCategory = 'Slide'; 
  final List<String> _categories = ['Slide', 'Catatan', 'Latihan', 'Lainnya'];

  Future<void> _downloadAndSavePdf(String type) async {
    if (widget.pdfUrl == null || widget.cookie == null) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      // Bikin nama file dari inputan user biar rapi, buang spasi
      String cleanTitle = _titleController.text.replaceAll(' ', '_');
      String fileName = "${cleanTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      String savePath = "${dir.path}/$fileName";

      var dio = Dio();
      await dio.download(
        widget.pdfUrl!,
        savePath,
        options: Options(headers: {'Cookie': widget.cookie}),
      );

      if (type == 'tugas') {
        // Bikin deadline default (H+7) kalau di-download dari eLOK
        DateTime defaultDeadline = DateTime.now().add(const Duration(days: 7));
        
        final newTask = StudentTask(
          title: _titleController.text,
          course: _courseController.text,
          deadline: defaultDeadline,
          filePath: savePath, // Path PDF yang baru di-download diselipin di sini
        );
        
        await DatabaseHelper.instance.insertTask(newTask);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Tugas disimpan! Deadline diset H+7 (Bisa diedit nanti).")),
           );
        }

      } else if (type == 'materi') {
        // Masukin ke SQLite Material dengan Kategori
        await DatabaseHelper.instance.insertMaterial(
          _titleController.text, 
          _courseController.text, 
          _selectedCategory, 
          savePath
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Materi berhasil disimpan!")),
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

  // --- POPUP FORM SEBELUM DOWNLOAD ---
  void _showDownloadDialog(String type) {
    // Clear form tiap kali popup dibuka
    _titleController.clear();
    _courseController.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // User gabisa nutup modal sembarangan 
      builder: (context) => AlertDialog(
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
              
              // Dropdown Kategori cuma muncul kalau simpan sebagai Materi
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
                Navigator.pop(context); // Tutup dialog
                _downloadAndSavePdf(type); // Gas download
              }
            },
            child: const Text('Download'),
          ),
        ],
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
                _showDownloadDialog('tugas'); // Panggil Dialog Form
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Simpan sebagai Materi'),
              onTap: () {
                Navigator.pop(context);
                _showDownloadDialog('materi'); // Panggil Dialog Form
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