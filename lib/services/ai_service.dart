import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_helper.dart';

class GeminiService {
  // Mengambil API Key dari environment variables (.env)
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static final String _githubToken = dotenv.env['GITHUB_TOKEN'] ?? '';

  /// Mengirim pertanyaan ke model AI dengan menyertakan konteks data lokal (jadwal dan tugas).
  Future<String> askGeminiWithContext(String userPrompt, String modelName) async {
    try {
      // Mengambil data jadwal dan tugas secara asinkron dari database lokal
      final tasks = await DatabaseHelper.instance.getAllTasks();
      final schedules = await DatabaseHelper.instance.getAllSchedules();

      // Membangun string konteks berdasarkan data dari database
      String dbContext = "Berikut adalah data jadwal dan tugas kuliah mahasiswa:\n\n";
      
      dbContext += "--- JADWAL KULIAH ---\n";
      if (schedules.isEmpty) {
        dbContext += "Tidak ada jadwal.\n";
      } else {
        for (var s in schedules) {
          dbContext += "- ${s.course} (${s.day} jam ${s.startTime}-${s.endTime} di ${s.room})\n";
        }
      }

      dbContext += "\n--- TUGAS AKTIF ---\n";
      if (tasks.isEmpty) {
        dbContext += "Tidak ada tugas.\n";
      } else {
        for (var t in tasks) {
          dbContext += "- ${t.title} (Matkul: ${t.course}, Deadline: ${t.deadline})\n";
        }
      }

      // Menggabungkan instruksi sistem (system prompt), konteks database, dan pertanyaan pengguna
      final finalPrompt = """
Anda adalah asisten AI cerdas untuk mahasiswa. Konteks utama Anda adalah membantu mengingatkan jadwal dan tugas berdasarkan data berikut:
$dbContext

PENTING: Meskipun fokus Anda adalah jadwal, Anda JUGA SEORANG ASISTEN SERBAGUNA yang ahli dalam pemrograman (termasuk Python), matematika, dan ilmu pengetahuan umum. 
Jika pengguna bertanya tentang hal di luar jadwal (seperti membuat game Tic Tac Toe, rumus, dll), JAWABLAH DENGAN AKURAT DAN LENGKAP tanpa beralasan bahwa Anda hanya asisten jadwal.
Gunakan bahasa Indonesia yang santai, informal, dan ramah.

Pertanyaan Pengguna: $userPrompt
""";

      // Menentukan layanan AI yang akan dipanggil berdasarkan nama model yang direkues
      if (modelName == 'llama3') {
        return await _askOllama(finalPrompt);
      } else if (modelName.contains('/')) {
        // Mengarahkan ke layanan GitHub Models jika nama model mengandung karakter '/'
        return await _askGitHubModels(finalPrompt, modelName);
      } else {
        // Pilihan default (fallback) menggunakan layanan Google Gemini
        return await _askGemini(finalPrompt, modelName);
      }
      
    } catch (e) {
      return 'Waduh, error bro pas manggil AI: $e';
    }
  }

  /// Mengirim permintaan ke layanan cloud Google Gemini menggunakan SDK resmi.
  Future<String> _askGemini(String prompt, String modelName) async {
    final model = GenerativeModel(model: modelName, apiKey: _apiKey);
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? 'Google AI nggak ngasih jawaban nih, bro.';
  }

  /// Mengirim permintaan ke server Ollama lokal melalui endpoint REST API.
  Future<String> _askOllama(String prompt) async {
    final url = Uri.parse('http://localhost:11434/api/generate'); // Pastikan Ollama server sudah jalan di port ini

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'llama3',
        'prompt': prompt,
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']; 
    } else {
      return 'Ollama error bro: Server lokal nolak koneksi. (Status: ${response.statusCode})';
    }
  }

  /// Mengirim permintaan ke layanan GitHub Models Inference API.
  Future<String> _askGitHubModels(String prompt, String modelId) async {
    final url = Uri.parse('https://models.github.ai/inference/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $_githubToken',
      },
      body: jsonEncode({
        'model': modelId,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Mengekstrak konten jawaban dari struktur JSON GitHub Models (standar OpenAI)
      return data['choices'][0]['message']['content'];
    } else {
      return 'Error GitHub Models bro: ${response.statusCode} - ${response.body}';
    }
  }
}