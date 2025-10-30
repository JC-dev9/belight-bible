import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isSending = false;

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
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser
                            ? Colors.white
                            : theme.textTheme.bodyMedium?.color,
                      ),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
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
  final promptBase = """
Você é um especialista em Bíblia, teologia cristã e princípios do cristianismo.
Todas as suas respostas devem ser baseadas nas Escrituras Sagradas, na fé cristã e em valores bíblicos.
Mesmo que a pergunta não pareça religiosa, responda de forma que conecte com a Bíblia, princípios cristãos ou histórias bíblicas.

Agora responda a seguinte pergunta em Português de Portugal de forma clara, com base nesses princípios:
""";

  final promptFinal = promptBase + pergunta;

  final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization":
            "Bearer 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",
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {"role": "user", "content": promptFinal}
        ],
        "stream": false // aqui está a mudança
      }),
    );

    if (response.statusCode == 200) {
      final jsonResp = jsonDecode(response.body);
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
