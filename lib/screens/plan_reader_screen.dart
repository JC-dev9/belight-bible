import 'package:flutter/material.dart';
import '../data/bible_repository.dart';

/// Leitor bíblico focado para passagens de planos de leitura.
/// Abre as passagens do dia (ex: "Mateus 1-2") e mostra apenas os capítulos relevantes.
class PlanReaderScreen extends StatefulWidget {
  final String planTitle;
  final String passage; // ex: "Mateus 1-2"
  final Color planColor;

  const PlanReaderScreen({
    super.key,
    required this.planTitle,
    required this.passage,
    required this.planColor,
  });

  @override
  State<PlanReaderScreen> createState() => _PlanReaderScreenState();
}

class _PlanReaderScreenState extends State<PlanReaderScreen> {
  late BibleRepository _bibleRepository;
  bool _isLoading = true;

  String _book = '';
  List<int> _chapters = [];
  int _currentChapterIndex = 0;
  List<Map<String, dynamic>> _verses = [];

  @override
  void initState() {
    super.initState();
    _bibleRepository = BibleRepository(version: 'acf');
    _parseAndLoad();
  }

  /// Parse "Mateus 1-2" → book = "Mateus", chapters = [1, 2]
  /// Parse "1 Coríntios 13-16" → book = "1 Coríntios", chapters = [13, 14, 15, 16]
  /// Parse "Filemom 1" → book = "Filemom", chapters = [1]
  void _parsePassage() {
    final passage = widget.passage.trim();
    
    // Remove extras like "(revisão)", "(conclusão)" etc
    final cleaned = passage.replaceAll(RegExp(r'\s*\(.*?\)\s*'), '').trim();

    // Regex: optional number prefix + book name + space + chapter or chapter range
    final regex = RegExp(r'^(\d?\s?[A-Za-zÀ-ÿ]+(?:\s[A-Za-zÀ-ÿ]+)*)\s+(\d+)(?:-(\d+))?$');
    final match = regex.firstMatch(cleaned);

    if (match != null) {
      _book = match.group(1)!.trim();
      final startChapter = int.parse(match.group(2)!);
      final endChapter = match.group(3) != null ? int.parse(match.group(3)!) : startChapter;
      _chapters = List.generate(endChapter - startChapter + 1, (i) => startChapter + i);
    } else {
      // Fallback: try to read the whole string as a book with chapter 1
      _book = cleaned;
      _chapters = [1];
    }
  }

  Future<void> _parseAndLoad() async {
    _parsePassage();
    await _bibleRepository.ensureLoaded();
    await _loadCurrentChapter();
  }

  Future<void> _loadCurrentChapter() async {
    if (_chapters.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final chapter = _chapters[_currentChapterIndex];
      final verses = await _bibleRepository.getChapter(_book, chapter);
      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _verses = [];
        _isLoading = false;
      });
    }
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= _chapters.length) return;
    setState(() => _currentChapterIndex = index);
    _loadCurrentChapter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : Colors.white;
    final txt = isDark ? Colors.grey.shade300 : Colors.grey.shade900;
    final subtxt = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final currentChapter = _chapters.isNotEmpty ? _chapters[_currentChapterIndex] : 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: txt),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.menu_book_outlined, color: widget.planColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.planTitle,
                style: TextStyle(
                  color: txt,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_chapters.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.planColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${_currentChapterIndex + 1}/${_chapters.length}',
                  style: TextStyle(
                    color: widget.planColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.planColor))
          : _verses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: subtxt, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Passagem não encontrada',
                        style: TextStyle(color: subtxt, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"${widget.passage}"',
                        style: TextStyle(color: subtxt.withAlpha(150), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Chapter title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$_book $currentChapter',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: txt,
                          ),
                        ),
                      ),
                    ),

                    // Verse list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _verses.length,
                        itemBuilder: (context, index) {
                          final verse = _verses[index];
                          final verseNum = verse['number'];
                          final verseText = verse['text'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: ' $verseNum  ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: subtxt,
                                      height: 1.8,
                                    ),
                                  ),
                                  TextSpan(
                                    text: verseText,
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: txt,
                                      height: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Bottom Navigation Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border(
                          top: BorderSide(
                            color: txt.withAlpha(20),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Previous chapter
                            IconButton(
                              onPressed: _currentChapterIndex > 0
                                  ? () => _goToChapter(_currentChapterIndex - 1)
                                  : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: _currentChapterIndex > 0 ? txt : txt.withAlpha(40),
                              ),
                            ),

                            // Current passage reference
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_book $currentChapter',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: txt,
                                  ),
                                ),
                              ),
                            ),

                            // Next chapter
                            IconButton(
                              onPressed: _currentChapterIndex < _chapters.length - 1
                                  ? () => _goToChapter(_currentChapterIndex + 1)
                                  : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color: _currentChapterIndex < _chapters.length - 1
                                    ? txt
                                    : txt.withAlpha(40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
