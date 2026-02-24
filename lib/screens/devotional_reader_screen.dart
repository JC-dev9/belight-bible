import 'package:flutter/material.dart';
import '../data/supabase_service.dart';

/// Tela de leitura do devocional — experiência tipo leitor de livro.
class DevotionalReaderScreen extends StatefulWidget {
  final String title;
  final String content;
  final int readingTimeMin;
  final DateTime? publishDate;
  final String? devotionalId;

  static const _months = [
    '', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];

  const DevotionalReaderScreen({
    super.key,
    required this.title,
    required this.content,
    this.readingTimeMin = 3,
    this.publishDate,
    this.devotionalId,
  });

  @override
  State<DevotionalReaderScreen> createState() => _DevotionalReaderScreenState();
}

class _DevotionalReaderScreenState extends State<DevotionalReaderScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isSaved = false;
  bool _isCheckingState = true;

  @override
  void initState() {
    super.initState();
    _checkSavedState();
  }

  Future<void> _checkSavedState() async {
    if (widget.devotionalId == null) {
      setState(() => _isCheckingState = false);
      return;
    }
    final saved = await _service.isDevotionalSaved(widget.devotionalId!);
    if (mounted) {
      setState(() {
        _isSaved = saved;
        _isCheckingState = false;
      });
    }
  }

  Future<void> _toggleSave() async {
    if (widget.devotionalId == null) return;

    setState(() => _isSaved = !_isSaved);

    if (_isSaved) {
      await _service.saveDevotional(widget.devotionalId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devocional salvo!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await _service.unsaveDevotional(widget.devotionalId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devocional removido dos salvos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF6F0);
    final textColor = isDark ? const Color(0xFFE8E0D4) : const Color(0xFF2C2417);
    final subtitleColor = isDark ? const Color(0xFF9E9589) : const Color(0xFF7A6E5D);

    final dateFormatted = widget.publishDate != null
        ? '${widget.publishDate!.day} de ${DevotionalReaderScreen._months[widget.publishDate!.month]} de ${widget.publishDate!.year}'
        : '';

    // Dividir conteúdo em parágrafos
    final paragraphs = widget.content
        .split(RegExp(r'\. (?=[A-ZÁÉÍÓÚÂÊÎÔÛÃÕÇ"])'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final displayParagraphs = paragraphs.length <= 1
        ? _splitIntoReadableParagraphs(widget.content)
        : paragraphs.map((p) => p.endsWith('.') ? p : '$p.').toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: subtitleColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 14, color: subtitleColor),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.readingTimeMin} min de leitura',
                          style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Botão Salvar
                  _isCheckingState
                      ? const SizedBox(width: 40)
                      : IconButton(
                          icon: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: _isSaved ? Colors.amber.shade700 : subtitleColor,
                            size: 24,
                          ),
                          onPressed: _toggleSave,
                          tooltip: _isSaved ? 'Remover dos salvos' : 'Salvar devocional',
                        ),
                ],
              ),
            ),

            // Conteúdo scrollable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Ícone decorativo
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.brown.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.coffee, size: 28, color: Colors.brown.shade400),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Label
                    Center(
                      child: Text(
                        'DEVOCIONAL DIÁRIO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Data
                    if (dateFormatted.isNotEmpty)
                      Center(
                        child: Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtitleColor.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),

                    // Divisor decorativo
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 30, height: 1, color: subtitleColor.withValues(alpha: 0.3)),
                          const SizedBox(width: 8),
                          Icon(Icons.auto_awesome, size: 12, color: subtitleColor.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Container(width: 30, height: 1, color: subtitleColor.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Título
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Parágrafos do conteúdo
                    ...displayParagraphs.map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        paragraph,
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor.withValues(alpha: 0.85),
                          height: 1.8,
                          fontFamily: 'Serif',
                          letterSpacing: 0.2,
                        ),
                      ),
                    )),

                    const SizedBox(height: 24),

                    // Divisor final
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 20, height: 1, color: subtitleColor.withValues(alpha: 0.3)),
                          const SizedBox(width: 6),
                          Container(
                            width: 6, height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: subtitleColor.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 20, height: 1, color: subtitleColor.withValues(alpha: 0.3)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _splitIntoReadableParagraphs(String text) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.isNotEmpty).toList();
    if (sentences.length <= 3) return [text];

    final paragraphs = <String>[];
    final buffer = StringBuffer();
    int count = 0;

    for (final sentence in sentences) {
      buffer.write(sentence);
      if (!sentence.endsWith('.') && !sentence.endsWith('!') && !sentence.endsWith('?')) {
        buffer.write('. ');
      } else {
        buffer.write(' ');
      }
      count++;
      if (count >= 3) {
        paragraphs.add(buffer.toString().trim());
        buffer.clear();
        count = 0;
      }
    }
    if (buffer.isNotEmpty) {
      paragraphs.add(buffer.toString().trim());
    }
    return paragraphs;
  }
}
