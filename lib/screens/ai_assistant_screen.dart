import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../widgets/chat_bubble.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _promptController = TextEditingController();
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Menyimpan referensi model AI yang saat ini dipilih oleh pengguna
  String _selectedModel = 'gemini-2.5-flash';
  
  // Daftar koleksi model inferensi AI yang terintegrasi di dalam aplikasi
  final List<String> _availableModels = [
    'gemini-2.5-flash',
    'gemini-3.5-flash',
    'llama3',
    'openai/gpt-5',
    'openai/gpt-5-chat',
    'deepseek/deepseek-r1',
    'microsoft/phi-4'
  ];

  /// Mengirimkan pesan pengguna ke layanan AI dan memperbarui antarmuka dengan respons.
  void _sendMessage() async {
    if (_promptController.text.trim().isEmpty) return;

    final userText = _promptController.text;
    
    setState(() {
      _messages.add({"role": "user", "text": userText});
      _isLoading = true;
      _promptController.clear();
    });

    // Meneruskan teks instruksi pengguna dan model AI spesifik yang dipilih ke berkas layanan
    final aiResponse = await _geminiService.askGeminiWithContext(userText, _selectedModel);

    setState(() {
      _messages.add({"role": "ai", "text": aiResponse});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanya AI"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Menu tarik-turun (Dropdown) yang berfungsi untuk melakukan transisi model bahasa AI
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedModel,
              dropdownColor: Colors.teal[700],
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              items: _availableModels.map((String model) {
                // Memformat representasi string model bahasa agar lebih rapi secara visual
                String displayName = model;
                if (model.contains('/')) {
                  displayName = model.split('/').last;
                }
                displayName = displayName.replaceAll('gemini-', '').toUpperCase();
                if (displayName.startsWith('LLAMA')) {
                  displayName = 'LLAMA 3 (LOKAL)';
                }
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(displayName),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return ChatBubble(message: msg, isUser: isUser);
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: "Tanya jadwal, tugas, materi, atau coding...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}