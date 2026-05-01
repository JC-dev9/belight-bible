import 'dart:async';
import 'package:flutter/material.dart';

import '../data/bible_search_service.dart';
import '../utils/theme.dart';

/// Ecrã de pesquisa textual nos versículos da Bíblia.
/// Devolve, via [Navigator.pop], um [BibleSearchResult] selecionado.
class BibleSearchScreen extends StatefulWidget {
  final String version;
  final ReadingTheme currentTheme;

  const BibleSearchScreen({
    super.key,
    required this.version,
    required this.currentTheme,
  });

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool _loading = true;
  bool _searching = false;
  String _query = '';
  List<BibleSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await BibleSearchService.ensureLoaded(widget.version);
    } catch (_) {
      // Mesmo que o load falhe, o estado de loading é desligado para mostrar ecrã vazio.
    }
    if (!mounted) return;
    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _runSearch(value);
    });
  }

  void _runSearch(String value) {
    setState(() {
      _query = value;
      _searching = true;
    });
    final results = BibleSearchService.search(value);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark:
        return AppColors.darkBg;
      case ReadingTheme.sepia:
        return AppColors.sepiaBg;
      default:
        return Colors.white;
    }
  }

  Color get _textColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark:
        return Colors.grey.shade300;
      case ReadingTheme.sepia:
        return AppColors.sepiaText;
      default:
        return Colors.grey.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _textColor;
    final bgColor = _bgColor;
    final accent = AppTheme.accentGold;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(color: textColor, fontSize: 16),
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            _runSearch(v);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar nos versículos...',
            hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: textColor.withOpacity(0.6)),
                    onPressed: () {
                      _controller.clear();
                      _runSearch('');
                      _focusNode.requestFocus();
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildBody(textColor, accent),
    );
  }

  Widget _buildBody(Color textColor, Color accent) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    if (_query.trim().length < 2) {
      return _buildEmptyHint(textColor);
    }
    if (_searching && _results.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accent));
    }
    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Nenhum versículo corresponde a "${_query.trim()}".',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                '${_results.length} resultado${_results.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            itemCount: _results.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: textColor.withOpacity(0.06),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final r = _results[index];
              return _ResultTile(
                result: r,
                query: _query,
                textColor: textColor,
                accent: accent,
                onTap: () => Navigator.pop(context, r),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHint(Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 56, color: textColor.withOpacity(0.25)),
            const SizedBox(height: 14),
            Text(
              'Escreva pelo menos 2 letras para pesquisar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final BibleSearchResult result;
  final String query;
  final Color textColor;
  final Color accent;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.query,
    required this.textColor,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.reference,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            _HighlightedText(
              text: result.text,
              query: query.trim(),
              baseStyle: TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.45,
                fontFamily: 'Georgia',
              ),
              accent: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final Color accent;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      final idx = lowerText.indexOf(lowerQuery, i);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(i)));
        break;
      }
      if (idx > i) {
        spans.add(TextSpan(text: text.substring(i, idx)));
      }
      final end = idx + lowerQuery.length;
      spans.add(TextSpan(
        text: text.substring(idx, end),
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          backgroundColor: accent.withOpacity(0.12),
        ),
      ));
      i = end;
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }
}
