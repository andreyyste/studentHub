import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../database_helper.dart'; // Sesuaikan path-nya

class PdfViewerScreen extends StatefulWidget {
  final String? pdfUrl;
  final String? cookie;
  final String? localPath; // Tambahan properti buat file lokal

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

  Future<void> _downloadAndSavePdf(String type) async {
    if (widget.pdfUrl == null || widget.cookie == null) return;

    setState(() {
      isDownloading = true;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      String fileName = "studenthub_${DateTime.now().millisecondsSinceEpoch}.pdf";
      String savePath = "${dir.path}/$fileName";

      var dio = Dio();
      await dio.download(
        widget.pdfUrl!,
        savePath,
        options: Options(headers: {'Cookie': widget.cookie}),
      );

      // Dummy data mata kuliah & judul, nanti bisa lu kembangin pake input dialog / Gemini
      String dummyCourse = "Algoritme dan Struktur Data"; 
      String dummyTitle = "Materi eLOK - ${DateTime.now().day}/${DateTime.now().month}";

      if (type == 'tugas') {
        // Taruh logic insertTask ke SQLite di sini
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil diunduh! Jangan lupa set deadline di List Tugas.")),
        );
      } else if (type == 'materi') {
        await DatabaseHelper.instance.insertMaterial(dummyTitle, dummyCourse, savePath);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Berhasil disimpan ke daftar $type!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal download: $e")),
      );
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
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
                _downloadAndSavePdf('tugas');
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Simpan sebagai Materi'),
              onTap: () {
                Navigator.pop(context);
                _downloadAndSavePdf('materi');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah ngebuka file lokal atau url network
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
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      // Tombol download cuma muncul kalau bukanya dari eLOK (Network URL)
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