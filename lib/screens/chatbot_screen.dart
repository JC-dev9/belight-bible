import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    
    // Limpa mensagens anteriores se quiser um chat fresco, ou mantém o histórico.
    // Aqui vou manter o histórico, mas focar na nova pergunta.
    setState(() {
      _controller.text = prompt;
    });

    // Envia automaticamente
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
                              final uri = Uri.parse(href);
                              // bible://Book/Chapter/Verse -> segments: [Book, Chapter, Verse]
                              // Atenção: Uri.parse pode normalizar os path segments.
                              // Vamos fazer um split manual mais seguro se o Uri falhar com acentos
                              
                              final safePath = href.replaceFirst('bible://', '');
                              final parts = safePath.split('/');
                              
                              if (parts.length >= 3) {
                                final book = Uri.decodeComponent(parts[0]);
                                final chapter = int.tryParse(parts[1]) ?? 1;
                                
                                // Fix: Handle ranges like "11-21" by taking the first part
                                final verseString = parts[2].split('-')[0]; // "11-21" -> "11"
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Ajuste vertical
              ),
              minLines: 1,
              maxLines: 5, // Cresce até 5 linhas
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

    // Cria a bolha do bot vazia
    final botMessage = _ChatMessage(text: '', isUser: false);
    setState(() {
      _messages.add(botMessage);
    });
    _scrollToBottom();

    await _sendToGroq(text, botMessage);

    setState(() {
      _isSending = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendToGroq(String pergunta, _ChatMessage botMessage) async {
  const systemPrompt = """
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

  List<Map<String, String>> messagesToSend = [];

  // 1. Sempre adiciona o System Prompt primeiro (ele é obrigatório e não conta na janela)
  messagesToSend.add({"role": "system", "content": systemPrompt});

  // 2. Define o limite de mensagens
  int limiteDeHistorico = 3;
  
  // Filtra a lista para pegar apenas as últimas N mensagens, excluindo a mensagem atual do bot (que está vazia)
  final mensagensValidas = _messages.where((m) => m != botMessage).toList();
  
  final historicoRecente = mensagensValidas.length > limiteDeHistorico
      ? mensagensValidas.sublist(mensagensValidas.length - limiteDeHistorico)
      : mensagensValidas;

  // 3. Adiciona o histórico filtrado
  for (var msg in historicoRecente) {
    messagesToSend.add({
      "role": msg.isUser ? "user" : "assistant",
      "content": msg.text
    });
  }

  final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",

        "Authorization": "Bearer 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", 
      },
      body: jsonEncode({
        "model": "meta-llama/llama-4-scout-17b-16e-instruct",
        "messages": messagesToSend, // Enviamos a lista completa aqui
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(utf8.decode(response.bodyBytes)); // utf8 para corrigir acentuação
      final text = jsonResp['choices']?[0]?['message']?['content'] ?? '';
      
      setState(() {
        botMessage.text = text;
      });
      _scrollToBottom();
    } else {
      setState(() {
        botMessage.text =
            "Erro na API: ${response.statusCode} ${response.reasonPhrase}";
      });
    }
  } catch (e) {
    setState(() {
      botMessage.text = "Erro ao conectar com a API: $e";
    });
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
