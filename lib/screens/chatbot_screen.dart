
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';
import '../data/user_data_model.dart';
import 'note_editor_screen.dart';

class ChatBotScreen extends StatefulWidget {
  final String? initialPrompt;
  final Function(String, int, int)? onNavigateToVerse;

  // Contexto de versículo de origem (quando o chat é aberto a partir da Bíblia).
  // Usado para ancorar a nota ao guardar uma resposta da IA.
  final String? sourceBook;
  final int? sourceChapter;
  final int? sourceVerse;
  final String? sourceVerseText;

  // Modo embutido: usado dentro do painel de estudo (bottom sheet) sobre a
  // Bíblia. Esconde o Scaffold/AppBar próprios e mostra um cabeçalho compacto.
  final bool embedded;
  final VoidCallback? onOpenFull;

  const ChatBotScreen({
    super.key,
    this.initialPrompt,
    this.onNavigateToVerse,
    this.sourceBook,
    this.sourceChapter,
    this.sourceVerse,
    this.sourceVerseText,
    this.embedded = false,
    this.onOpenFull,
  });

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

  // Id da conversa actual no Supabase (null = ainda não persistida / nova).
  String? _conversationId;
  // Nº de mensagens já gravadas (para append incremental).
  int _persistedCount = 0;
  // Activado quando uma edição altera mensagens já gravadas: força reescrita.
  bool _needsFullResync = false;

  static const _suggestions = <({IconData icon, String text})>[
    (icon: Icons.self_improvement_rounded, text: 'O que a Bíblia diz sobre ansiedade?'),
    (icon: Icons.menu_book_rounded, text: 'Explique o Salmos 23'),
    (icon: Icons.local_fire_department_rounded, text: 'Como ter mais fé no dia a dia?'),
    (icon: Icons.favorite_rounded, text: 'Versículos sobre amor'),
  ];

  // Cor de marca usada em todo o chat (amarelo sólido, sem gradientes).
  Color get _accent => Colors.yellow.shade700;

  /// Tempo relativo legível para o histórico ("agora", "há 2 h", "ontem"…).
  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    final d = local;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

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

  // API pública usada pela vista de estudo para transferir a conversa para a
  // aba IA em ecrã completo.
  String? get conversationId => _conversationId;
  Future<void> ensureSaved() => _persistConversation();
  Future<void> loadConversation(String id) => _loadConversation(id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.embedded) {
      return _buildEmbedded(theme, isDark);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chat Bíblico',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Conversas',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'Nova conversa',
            onPressed: _messages.isEmpty ? null : _startNewConversation,
          ),
        ],
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
  // VISTA EMBUTIDA (painel de estudo sobre a Bíblia)
  // =========================================================================

  Widget _buildEmbedded(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Cabeçalho compacto com pega + acções
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.auto_awesome, size: 18, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    'Estudo com IA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  if (_messages.isNotEmpty)
                    IconButton(
                      onPressed: _startNewConversation,
                      icon: const Icon(Icons.add_comment_rounded, size: 20),
                      tooltip: 'Nova conversa',
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  TextButton.icon(
                    onPressed: widget.onOpenFull,
                    icon: const Icon(Icons.open_in_full_rounded, size: 16),
                    label: const Text('Abrir completo'),
                    style: TextButton.styleFrom(foregroundColor: _accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _messages.isEmpty && !_isSending
              ? _buildWelcomeContent(theme)
              : _buildMessageList(theme),
        ),
        const Divider(height: 1),
        _buildInputArea(theme, isDark),
      ],
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
          const SizedBox(height: 36),
          Text(
            'Olá, $greetName',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 360 ? 24 : 30,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 15, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
              const SizedBox(width: 6),
              Text(
                'SUGESTÕES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_suggestions.length, (i) => _buildSuggestionChip(theme, _suggestions[i])),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'A IA pode cometer erros. Confirme sempre com as Escrituras.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static const _chipRadius = BorderRadius.all(Radius.circular(16));

  Widget _buildSuggestionChip(ThemeData theme, ({IconData icon, String text}) item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardColor,
        borderRadius: _chipRadius,
        child: InkWell(
          onTap: () {
            _controller.text = item.text;
            _sendMessage();
          },
          borderRadius: _chipRadius,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _chipRadius,
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 19, color: _accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(fontSize: 15, color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_outward_rounded,
                    size: 16,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
              ],
            ),
          ),
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
    // Indicador de "a escrever".
    if (!msg.isUser && msg.text.isEmpty && _isSending) {
      return RepaintBoundary(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
            ),
            child: const _TypingIndicator(),
          ),
        ),
      );
    }

    final iconColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3) ?? Colors.grey;
    final isUser = msg.isUser;

    // Balão da mensagem.
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
      decoration: BoxDecoration(
        color: isUser ? _accent : theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 18 : 4),
          topRight: Radius.circular(isUser ? 4 : 18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
        border: isUser ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: isUser
          ? Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4))
          : MarkdownBody(
              data: msg.text,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 16, height: 1.45),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                blockSpacing: 8,
                a: TextStyle(
                  color: _accent,
                  decoration: TextDecoration.underline,
                  decorationColor: _accent,
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
    );

    // Ações fora do balão (copiar / editar / guardar como nota).
    final actions = msg.text.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionIcon(Icons.content_copy_rounded, iconColor, () => _copyMessage(msg.text)),
                if (isUser && !_isSending) ...[
                  const SizedBox(width: 2),
                  _actionIcon(Icons.edit_rounded, iconColor, () => _editMessage(index)),
                ],
                if (!isUser) ...[
                  const SizedBox(width: 2),
                  _actionIcon(Icons.bookmark_add_rounded, iconColor, () => _saveMessageAsNote(msg.text)),
                ],
              ],
            ),
          );

    final followUps = (!isUser &&
            msg.suggestions.isNotEmpty &&
            index == _messages.length - 1 &&
            !_isSending)
        ? _buildFollowUpSuggestions(theme, msg.suggestions)
        : const SizedBox.shrink();

    if (isUser) {
      return RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [bubble, actions],
          ),
        ),
      );
    }

    // Mensagem da IA: balão e ações alinhados à esquerda.
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [bubble, actions, followUps],
        ),
      ),
    );
  }

  Widget _buildFollowUpSuggestions(ThemeData theme, List<String> suggestions) {
    final accent = _accent;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return Material(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => sendPrompt(s),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: accent),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        s,
                        style: TextStyle(fontSize: 13.5, color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
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

    // A edição mexeu no histórico já gravado: força reescrita no próximo save.
    if (_conversationId != null) _needsFullResync = true;
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
                          color: _accent,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _accent,
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

    _persistConversation();
  }

  // =========================================================================
  // PERSISTÊNCIA DE CONVERSAS
  // =========================================================================

  /// Persiste a conversa no Supabase, em background.
  /// Caso comum: append só das mensagens novas. Após uma edição: reescrita total.
  Future<void> _persistConversation() async {
    final turns = _messages
        .where((m) => m.text.trim().isNotEmpty)
        .map((m) => ChatTurn(role: m.isUser ? 'user' : 'assistant', content: m.text))
        .toList();
    if (turns.isEmpty) return;

    final firstUser = _messages.firstWhere((m) => m.isUser, orElse: () => _messages.first);
    var title = firstUser.text.trim().replaceAll('\n', ' ');
    if (title.length > 48) title = '${title.substring(0, 48)}…';

    // Garantir que a conversa existe.
    if (_conversationId == null) {
      final id = await _supabaseService.createConversation(title);
      if (id == null) return;
      _conversationId = id;
      _persistedCount = 0;
    } else {
      await _supabaseService.touchConversation(_conversationId!, title);
    }

    if (_needsFullResync) {
      await _supabaseService.replaceMessages(_conversationId!, turns);
      _persistedCount = turns.length;
      _needsFullResync = false;
    } else if (turns.length > _persistedCount) {
      await _supabaseService.appendMessages(_conversationId!, turns.sublist(_persistedCount));
      _persistedCount = turns.length;
    }
  }

  /// Começa uma conversa nova (não apaga a guardada, só limpa o ecrã).
  void _startNewConversation() {
    setState(() {
      _messages.clear();
      _conversationId = null;
      _persistedCount = 0;
      _needsFullResync = false;
      _controller.clear();
    });
  }

  /// Abre a lista de conversas guardadas.
  Future<void> _openHistory() async {
    final theme = Theme.of(context);
    var conversations = await _supabaseService.getConversations();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      // Pega de arrastar.
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Cabeçalho com título + botão "Nova".
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 20, color: _accent),
                            const SizedBox(width: 8),
                            Text(
                              'Conversas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                _startNewConversation();
                              },
                              icon: const Icon(Icons.add_comment_rounded, size: 18),
                              label: const Text('Nova'),
                              style: TextButton.styleFrom(
                                foregroundColor: _accent,
                                backgroundColor: _accent.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: conversations.isEmpty
                            ? _historyEmptyState(theme)
                            : ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                                itemCount: conversations.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (_, i) {
                                  final c = conversations[i];
                                  return _conversationCard(
                                    theme,
                                    c,
                                    active: c.id == _conversationId,
                                    onTap: () {
                                      Navigator.pop(sheetContext);
                                      _loadConversation(c.id);
                                    },
                                    onDelete: () async {
                                      final ok = await _confirmDelete(sheetContext);
                                      if (ok != true) return;
                                      await _supabaseService.deleteConversation(c.id);
                                      if (_conversationId == c.id) _startNewConversation();
                                      setSheetState(() {
                                        conversations = conversations
                                            .where((x) => x.id != c.id)
                                            .toList();
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _historyEmptyState(ThemeData theme) {
    final faint = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 48, color: faint),
          const SizedBox(height: 12),
          Text(
            'Ainda não tens conversas guardadas.',
            style: TextStyle(color: faint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _conversationCard(
    ThemeData theme,
    ChatConversation c, {
    required bool active,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final title = c.title?.isNotEmpty == true ? c.title! : 'Conversa';
    final time = _relativeTime(c.updatedAt);
    final radius = BorderRadius.circular(16);

    return Material(
      color: active ? _accent.withValues(alpha: 0.1) : theme.cardColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active ? _accent.withValues(alpha: 0.6) : theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.chat_bubble_rounded, size: 18, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)),
                tooltip: 'Apagar',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Apagar conversa?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  /// Carrega uma conversa guardada para o ecrã.
  Future<void> _loadConversation(String id) async {
    final convo = await _supabaseService.getConversation(id);
    if (convo == null || !mounted) return;
    setState(() {
      _conversationId = convo.id;
      _persistedCount = convo.messages.length;
      _needsFullResync = false;
      _messages
        ..clear()
        ..addAll(convo.messages.map((t) => _ChatMessage(
              text: t.role == 'user' ? t.content : _formatBibleLinks(t.content),
              isUser: t.role == 'user',
            )));
    });
    _scrollToBottom();
  }

  // =========================================================================
  // BIBLE LINK FORMATTER
  // =========================================================================

  String _formatBibleLinks(String text) {
    final regex = RegExp(r'(?:\[([^\]]*)\])?\(?(bible:\/\/([^\/\)]+)\/(\d+)\/([0-9\-]+))\)?');
    return text.replaceAllMapped(regex, (match) {
      final existingTitle = match.group(1);
      String book = match.group(3)!;
      final chapter = match.group(4)!;
      final verse = match.group(5)!;

      try {
        if (book.contains('%')) {
          book = Uri.decodeComponent(book);
        }
      } catch (_) {}

      book = book.trim();

      final title = (existingTitle != null && existingTitle.isNotEmpty)
          ? existingTitle
          : '$book $chapter:$verse';

      return '[$title](bible://${Uri.encodeComponent(book)}/$chapter/$verse)';
    });
  }

  // =========================================================================
  // SEND TO EDGE FUNCTION
  // =========================================================================

  Future<void> _sendWithFallback(String pergunta, _ChatMessage botMessage) async {
    try {
      final client = Supabase.instance.client;

      // Build message history for the Edge Function
      final mensagensValidas = _messages.where((m) => m != botMessage).toList();
      final historicoRecente = mensagensValidas.length > 6
          ? mensagensValidas.sublist(mensagensValidas.length - 6)
          : mensagensValidas;

      final messages = historicoRecente.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final response = await client.functions.invoke(
        'chat',
        body: {'messages': messages},
      );

      final data = response.data;

      if (response.status == 429) {
        setState(() {
          botMessage.text = (data is Map && data['message'] is String)
              ? data['message'] as String
              : 'Atingiste o limite diário de perguntas. Volta amanhã.';
        });
        return;
      }

      if (data != null && data['response'] != null) {
        final rawSuggestions = data['suggestions'];
        final suggestions = rawSuggestions is List
            ? rawSuggestions.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : <String>[];
        setState(() {
          botMessage.text = _formatBibleLinks(data['response'] as String);
          botMessage.suggestions = suggestions;
        });
        _scrollToBottom();
      } else {
        setState(() {
          botMessage.text = 'Desculpe, não consegui conectar ao serviço. Tente novamente em alguns instantes.';
        });
      }
    } on FunctionException catch (e) {
      final details = e.details;
      String message = 'Desculpe, não consegui conectar ao serviço. Tente novamente em alguns instantes.';
      if (e.status == 429 && details is Map && details['message'] is String) {
        message = details['message'] as String;
      }
      setState(() {
        botMessage.text = message;
      });
    } catch (e) {
      setState(() {
        botMessage.text = 'Desculpe, não consegui conectar ao serviço. Tente novamente em alguns instantes.';
      });
    }
  }

  // =========================================================================
  // GUARDAR RESPOSTA DA IA COMO NOTA
  // =========================================================================

  Future<void> _saveMessageAsNote(String aiText) async {
    // 1. Determinar a âncora (book/chapter/verse): contexto de origem ou
    //    primeira referência citada na resposta.
    String? book = widget.sourceBook;
    int? chapter = widget.sourceChapter;
    int? verse = widget.sourceVerse;
    final String verseText = widget.sourceVerseText ?? '';

    if (book == null || chapter == null || verse == null) {
      final ref = _extractFirstReference(aiText);
      if (ref != null) {
        book = ref.$1;
        chapter = ref.$2;
        verse = ref.$3;
      }
    }

    if (book == null || chapter == null || verse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta resposta não cita um versículo para ancorar a nota.')),
        );
      }
      return;
    }

    // 2. Converter o markdown da IA para Quill Delta.
    var deltaJson = _markdownToQuillDelta(aiText);
    String? initialTitle = 'Estudo: $book $chapter:$verse';

    // 3. Proteger nota existente nesse versículo: se já houver, anexar em vez
    //    de substituir (a tabela é única por book/chapter/verse).
    final existing = await _supabaseService.getNotes(book, chapter);
    UserNote? existingNote;
    for (final n in existing) {
      if (n.verse == verse) {
        existingNote = n;
        break;
      }
    }
    if (existingNote != null && existingNote.content.trim().isNotEmpty) {
      deltaJson = _mergeDeltas(existingNote.content, deltaJson);
      if (existingNote.title != null && existingNote.title!.isNotEmpty) {
        initialTitle = existingNote.title;
      }
    }

    if (!mounted) return;
    final theme = Theme.of(context);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          book: book!,
          chapter: chapter!,
          verseNumber: verse!,
          verseText: verseText,
          initialNote: deltaJson,
          initialTitle: initialTitle,
          backgroundColor: theme.scaffoldBackgroundColor,
          textColor: theme.textTheme.bodyLarge?.color ?? Colors.black,
          accentColor: Colors.yellow.shade700,
        ),
      ),
    );

    if (result is Map && mounted) {
      await _supabaseService.saveNote(UserNote(
        book: book,
        chapter: chapter,
        verse: verse,
        content: (result['content'] as String?) ?? deltaJson,
        title: result['title'] as String?,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota guardada e sincronizada')),
        );
      }
    }
  }

  /// Extrai a primeira referência `bible://Livro/Cap/Vers` do texto.
  (String, int, int)? _extractFirstReference(String text) {
    final m = RegExp(r'bible:\/\/([^\/\)]+)\/(\d+)\/(\d+)').firstMatch(text);
    if (m == null) return null;
    String book = m.group(1)!;
    try {
      if (book.contains('%')) book = Uri.decodeComponent(book);
    } catch (_) {}
    final chapter = int.tryParse(m.group(2)!) ?? 1;
    final verse = int.tryParse(m.group(3)!) ?? 1;
    return (book.trim(), chapter, verse);
  }

  /// Junta dois documentos Quill Delta (JSON) com uma linha em branco entre eles.
  String _mergeDeltas(String existingJson, String newJson) {
    try {
      final existing = (jsonDecode(existingJson) as List).cast<dynamic>();
      final added = (jsonDecode(newJson) as List).cast<dynamic>();
      return jsonEncode([
        ...existing,
        {'insert': '\n'},
        ...added,
      ]);
    } catch (_) {
      return newJson;
    }
  }

  /// Conversor leve de markdown para Quill Delta (JSON string).
  /// Suporta títulos (#), negrito (**), listas (- / 1.) e remove a sintaxe de
  /// links mantendo o texto visível.
  String _markdownToQuillDelta(String markdown) {
    final ops = <Map<String, dynamic>>[];
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');

    for (var line in lines) {
      Map<String, dynamic>? blockAttr;

      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length.clamp(1, 3);
        line = heading.group(2)!;
        blockAttr = {'header': level};
      } else {
        final bullet = RegExp(r'^\s*[-*]\s+(.*)$').firstMatch(line);
        final numbered = RegExp(r'^\s*\d+[.)]\s+(.*)$').firstMatch(line);
        if (bullet != null) {
          line = bullet.group(1)!;
          blockAttr = {'list': 'bullet'};
        } else if (numbered != null) {
          line = numbered.group(1)!;
          blockAttr = {'list': 'ordered'};
        }
      }

      _appendInlineRuns(ops, line);
      ops.add(blockAttr != null ? {'insert': '\n', 'attributes': blockAttr} : {'insert': '\n'});
    }

    return jsonEncode(ops);
  }

  /// Acrescenta os "runs" inline de uma linha, tratando links e negrito.
  void _appendInlineRuns(List<Map<String, dynamic>> ops, String text) {
    // Links markdown -> apenas o texto visível
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1)!);
    // Remove crases de código inline
    text = text.replaceAll('`', '');

    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final m in boldRegex.allMatches(text)) {
      if (m.start > last) {
        ops.add({'insert': text.substring(last, m.start)});
      }
      ops.add({'insert': m.group(1), 'attributes': {'bold': true}});
      last = m.end;
    }
    if (last < text.length) {
      ops.add({'insert': text.substring(last)});
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
  List<String> suggestions = const [];
  _ChatMessage({required this.text, required this.isUser});
}
