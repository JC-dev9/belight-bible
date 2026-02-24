import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBotScreen extends StatefulWidget {
  final String? initialPrompt;
  final Function(String, int, int)? onNavigateToVerse;

  const ChatBotScreen({super.key, this.initialPrompt, this.onNavigateToVerse});

  @override
  ChatBotScreenState createState() => ChatBotScreenState();
}

class ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _controller.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage();
      });
    }
  }

  // Novo método público para ser chamado externamente (pela Home/Bíblia)
  void sendPrompt(String prompt) {
    if (prompt.isEmpty) return;
    
    setState(() {
      _controller.text = prompt;
    });

    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chat Bíblico',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? Colors.yellow.shade700
                          : theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                      ),
                    ),
                    child: msg.isUser 
                      ? Text(
                          msg.text,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        )
                      : MarkdownBody(
                          data: msg.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                            blockSpacing: 8,
                            a: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                          ),
                          onTapLink: (text, href, title) {
                            if (href != null && href.startsWith('bible://')) {
                              final safePath = href.replaceFirst('bible://', '');
                              final parts = safePath.split('/');
                              
                              if (parts.length >= 3) {
                                final book = Uri.decodeComponent(parts[0]);
                                final chapter = int.tryParse(parts[1]) ?? 1;
                                final verseString = parts[2].split('-')[0];
                                final verse = int.tryParse(verseString) ?? 1;
                                
                                if (widget.onNavigateToVerse != null) {
                                  widget.onNavigateToVerse!(book, chapter, verse);
                                }
                              }
                            }
                          },
                        ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Digite sua pergunta...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const CircularProgressIndicator()
              : CircleAvatar(
                  backgroundColor: Colors.yellow.shade700,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
      _controller.clear();
    });

    _scrollToBottom();

    final botMessage = _ChatMessage(text: '', isUser: false);
    setState(() {
      _messages.add(botMessage);
    });
    _scrollToBottom();

    // Sistema de fallback: tenta Groq primeiro, depois Gemini
    await _sendWithFallback(text, botMessage);

    setState(() {
      _isSending = false;
    });
    _scrollToBottom();
  }

  // =========================================================================
  // SYSTEM PROMPT (compartilhado entre Groq e Gemini)
  // =========================================================================
  static const _systemPrompt = """
Você é um especialista em Bíblia, teologia cristã e princípios do cristianismo.
Todas as suas respostas devem ser baseadas nas Escrituras Sagradas, na fé cristã e em valores bíblicos.
Responda sempre em Português de Portugal.

IMPORTANTE: 
Sempre que citar um versículo, formate-o EXATAMENTE como um link Markdown da seguinte forma:
[Livro Capítulo:Versículo](bible://Livro/Capítulo/Versículo)

Exemplos:
- [João 3:16](bible://João/3/16)
- [Gênesis 1:1](bible://Gênesis/1/1)

Não use abreviações nos links. O nome do livro deve estar completo.
""";

  // =========================================================================
  // FALLBACK: Groq → Gemini
  // =========================================================================

  Future<void> _sendWithFallback(String pergunta, _ChatMessage botMessage) async {
    // 1. Tenta Groq (principal — grátis e ultra rápido)
    final groqSuccess = await _sendToGroq(pergunta, botMessage);
    if (groqSuccess) return;

    // 2. Fallback: Gemini Flash (backup gratuito)
    debugPrint('⚠️ Groq falhou. Tentando Gemini como fallback...');
    final geminiSuccess = await _sendToGemini(pergunta, botMessage);
    if (geminiSuccess) return;

    // 3. Ambos falharam
    setState(() {
      botMessage.text = 'Desculpe, não consegui conectar ao serviço. Tente novamente em alguns instantes.';
    });
  }

  // =========================================================================
  // GROQ (Principal)
  // =========================================================================

  List<Map<String, String>> _buildGroqMessages(_ChatMessage botMessage) {
    final messages = <Map<String, String>>[];
    messages.add({"role": "system", "content": _systemPrompt});

    final mensagensValidas = _messages.where((m) => m != botMessage).toList();
    final historicoRecente = mensagensValidas.length > 3
        ? mensagensValidas.sublist(mensagensValidas.length - 3)
        : mensagensValidas;

    for (var msg in historicoRecente) {
      messages.add({
        "role": msg.isUser ? "user" : "assistant",
        "content": msg.text
      });
    }
    return messages;
  }

  Future<bool> _sendToGroq(String pergunta, _ChatMessage botMessage) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ GROQ_API_KEY não encontrada no .env');
      return false;
    }

    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "meta-llama/llama-4-scout-17b-16e-instruct",
          "messages": _buildGroqMessages(botMessage),
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(utf8.decode(response.bodyBytes));
        final text = jsonResp['choices']?[0]?['message']?['content'] ?? '';
        setState(() { botMessage.text = text; });
        _scrollToBottom();
        return true;
      } else {
        debugPrint('Groq erro: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Groq conexão erro: $e');
      return false;
    }
  }

  // =========================================================================
  // GEMINI (Fallback)
  // =========================================================================

  Future<bool> _sendToGemini(String pergunta, _ChatMessage botMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY não encontrada no .env');
      return false;
    }

    final contents = <Map<String, dynamic>>[];
    final mensagensValidas = _messages.where((m) => m != botMessage).toList();
    final historicoRecente = mensagensValidas.length > 3
        ? mensagensValidas.sublist(mensagensValidas.length - 3)
        : mensagensValidas;

    for (var msg in historicoRecente) {
      contents.add({
        "role": msg.isUser ? "user" : "model",
        "parts": [{"text": msg.text}]
      });
    }

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "system_instruction": {
            "parts": [{"text": _systemPrompt}]
          },
          "contents": contents,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(utf8.decode(response.bodyBytes));
        final text = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        setState(() { botMessage.text = text; });
        _scrollToBottom();
        return true;
      } else {
        debugPrint('Gemini erro: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Gemini conexão erro: $e');
      return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
