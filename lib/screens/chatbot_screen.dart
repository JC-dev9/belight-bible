import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/supabase_service.dart';

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
  final SupabaseService _supabaseService = SupabaseService();
  final List<_ChatMessage> _messages = [];

  bool _isSending = false;
  String _userName = '';

  static const _suggestions = [
    '🙏 O que a Bíblia diz sobre ansiedade?',
    '📖 Explique o Salmo 23',
    '💡 Como ter mais fé no dia a dia?',
    '❤️ Versículos sobre amor',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _controller.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage();
      });
    }
  }

  Future<void> _loadUserName() async {
    final profile = await _supabaseService.getProfile();
    if (mounted && profile != null) {
      setState(() {
        _userName = profile.fullName.split(' ').first;
      });
    }
  }

  void sendPrompt(String prompt) {
    if (prompt.isEmpty) return;
    setState(() { _controller.text = prompt; });
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chat Bíblico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_isSending
                ? _buildWelcomeContent(theme)
                : _buildMessageList(theme),
          ),
          const Divider(height: 1),
          _buildInputArea(theme, isDark),
        ],
      ),
    );
  }

  // =========================================================================
  // WELCOME CONTENT
  // =========================================================================

  Widget _buildWelcomeContent(ThemeData theme) {
    final greetName = _userName.isNotEmpty ? _userName : 'Amigo';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Olá, $greetName',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Como posso te ajudar hoje?',
            style: TextStyle(
              fontSize: 16,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Sugestões',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_suggestions.length, (i) => _buildSuggestionChip(theme, _suggestions[i])),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          _controller.text = text;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
            color: theme.cardColor,
          ),
          child: Text(text, style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
        ),
      ),
    );
  }

  // =========================================================================
  // MESSAGE LIST
  // =========================================================================

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageRow(theme, msg, index);
      },
    );
  }

  Widget _buildMessageRow(ThemeData theme, _ChatMessage msg, int index) {
    // Typing indicator
    if (!msg.isUser && msg.text.isEmpty && _isSending) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: const _TypingIndicator(),
        ),
      );
    }

    final iconColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3) ?? Colors.grey;

    return Column(
      crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Balão da mensagem
        Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: msg.isUser ? Colors.yellow.shade700 : theme.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                bottomRight: Radius.circular(msg.isUser ? 0 : 12),
              ),
            ),
            child: msg.isUser
                ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 16))
                : MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16),
                      strong: const TextStyle(fontWeight: FontWeight.bold),
                      blockSpacing: 8,
                      a: TextStyle(
                        color: Colors.yellow.shade700,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.yellow.shade700,
                        fontWeight: FontWeight.w600,
                      ),
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
        ),

        // Ações fora do balão (copiar / editar)
        if (msg.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: msg.isUser ? 0 : 4,
              right: msg.isUser ? 4 : 0,
              bottom: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Copiar
                _actionIcon(Icons.content_copy_rounded, iconColor, () => _copyMessage(msg.text)),
                if (msg.isUser && !_isSending) ...[
                  const SizedBox(width: 2),
                  // Editar (só mensagens do user)
                  _actionIcon(Icons.edit_outlined, iconColor, () => _editMessage(index)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem copiada'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _editMessage(int index) {
    final msg = _messages[index];
    if (!msg.isUser) return;

    // Coloca o texto de volta no campo de input
    _controller.text = msg.text;

    // Remove a mensagem do user e a resposta do bot (se existir logo depois)
    setState(() {
      // Remove a resposta do bot que veio logo a seguir
      if (index + 1 < _messages.length && !_messages[index + 1].isUser) {
        _messages.removeAt(index + 1);
      }
      // Remove a mensagem do user
      _messages.removeAt(index);
    });
  }

  // =========================================================================
  // INPUT AREA
  // =========================================================================

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
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
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.yellow.shade700,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SEND MESSAGE
  // =========================================================================

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

    await _sendWithFallback(text, botMessage);

    setState(() {
      _isSending = false;
    });
    _scrollToBottom();
  }

  // =========================================================================
  // SYSTEM PROMPT
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
    final groqSuccess = await _sendToGroq(pergunta, botMessage);
    if (groqSuccess) return;

    debugPrint('⚠️ Groq falhou. Tentando Gemini como fallback...');
    final geminiSuccess = await _sendToGemini(pergunta, botMessage);
    if (geminiSuccess) return;

    setState(() {
      botMessage.text = 'Desculpe, não consegui conectar ao serviço. Tente novamente em alguns instantes.';
    });
  }

  // =========================================================================
  // GROQ
  // =========================================================================

  List<Map<String, String>> _buildGroqMessages(_ChatMessage botMessage) {
    final messages = <Map<String, String>>[];
    messages.add({"role": "system", "content": _systemPrompt});

    final mensagensValidas = _messages.where((m) => m != botMessage).toList();
    final historicoRecente = mensagensValidas.length > 3
        ? mensagensValidas.sublist(mensagensValidas.length - 3)
        : mensagensValidas;

    for (var msg in historicoRecente) {
      messages.add({"role": msg.isUser ? "user" : "assistant", "content": msg.text});
    }
    return messages;
  }

  Future<bool> _sendToGroq(String pergunta, _ChatMessage botMessage) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) return false;

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
      }
      return false;
    } catch (e) {
      debugPrint('Groq erro: $e');
      return false;
    }
  }

  // =========================================================================
  // GEMINI
  // =========================================================================

  Future<bool> _sendToGemini(String pergunta, _ChatMessage botMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) return false;

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
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "system_instruction": {"parts": [{"text": _systemPrompt}]},
          "contents": contents,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(utf8.decode(response.bodyBytes));
        final text = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        setState(() { botMessage.text = text; });
        _scrollToBottom();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Gemini erro: $e');
      return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// =========================================================================
// TYPING INDICATOR (3 pontinhos animados)
// =========================================================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
    });

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4) ?? Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(0, _animations[i].value),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}
