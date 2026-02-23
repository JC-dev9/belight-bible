import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class BibleModals {
  
  /// Modal principal de navegação: Livro → Capítulo → Versículo
  /// Ao clicar num livro, expande os capítulos como grid abaixo.
  /// Ao clicar num capítulo, abre modal bottom com os versículos.
  /// Ao clicar num versículo, navega diretamente.
  static void showBookSelector(
      BuildContext context, {
      required Color backgroundColor,
      required Color textColor,
      required Color activeColor,
      required List<String> allBooks,
      required String selectedBook,
      required Map<String, int> chaptersPerBook,
      required Future<int> Function(String book, int chapter) getVerseCount,
      required Function(String book, int chapter, int verse) onNavigationComplete,
    }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookChapterVersePicker(
        backgroundColor: backgroundColor,
        textColor: textColor,
        activeColor: activeColor,
        allBooks: allBooks,
        selectedBook: selectedBook,
        chaptersPerBook: chaptersPerBook,
        getVerseCount: getVerseCount,
        onNavigationComplete: onNavigationComplete,
      ),
    );
  }

  static void showChapterSelector(
    BuildContext context, {
    required Color backgroundColor,
    required Color textColor,
    required Color activeColor,
    required String selectedBook,
    required int selectedChapter,
    required int maxChapters,
    required Function(int) onChapterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Capítulos de $selectedBook',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: maxChapters,
                itemBuilder: (context, index) {
                  final chapter = index + 1;
                  final isSelected = chapter == selectedChapter;
                  return InkWell(
                    onTap: () {
                      onChapterSelected(chapter);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor
                            : textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? null
                            : Border.all(color: textColor.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          '$chapter',
                          style: TextStyle(
                            color: isSelected ? Colors.black : textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showVersionSelector(
    BuildContext context, {
    required Color backgroundColor,
    required Color textColor,
    required Color activeColor,
    required String currentVersion,
    required Map<String, String> availableVersions,
    required Function(String) onVersionSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Versão da Bíblia',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: availableVersions.entries.map((entry) {
                      final isSelected = currentVersion == entry.key;
                      return ListTile(
                        title: Text(entry.value,
                            style: TextStyle(
                                color: textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(Icons.check, color: activeColor)
                            : null,
                        onTap: () {
                          if (!isSelected) {
                              onVersionSelected(entry.key);
                          }
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget statefull para o picker de Livro → Capítulo → Versículo
class _BookChapterVersePicker extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color activeColor;
  final List<String> allBooks;
  final String selectedBook;
  final Map<String, int> chaptersPerBook;
  final Future<int> Function(String book, int chapter) getVerseCount;
  final Function(String book, int chapter, int verse) onNavigationComplete;

  const _BookChapterVersePicker({
    required this.backgroundColor,
    required this.textColor,
    required this.activeColor,
    required this.allBooks,
    required this.selectedBook,
    required this.chaptersPerBook,
    required this.getVerseCount,
    required this.onNavigationComplete,
  });

  @override
  State<_BookChapterVersePicker> createState() => _BookChapterVersePickerState();
}

class _BookChapterVersePickerState extends State<_BookChapterVersePicker> {
  String _searchQuery = '';
  String? _expandedBook;
  final ScrollController _scrollController = ScrollController();

  List<String> get _filteredBooks {
    if (_searchQuery.isEmpty) return widget.allBooks;
    final query = _searchQuery.toLowerCase();
    return widget.allBooks
        .where((book) => book.toLowerCase().contains(query))
        .toList();
  }

  void _onChapterTap(String book, int chapter) {
    // Abre modal bottom com os versículos
    _showVerseModal(book, chapter);
  }

  Future<void> _showVerseModal(String book, int chapter) async {
    // Buscar quantidade de versículos
    final verseCount = await widget.getVerseCount(book, chapter);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.5,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$book $chapter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: verseCount,
                itemBuilder: (ctx2, index) {
                  final verse = index + 1;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      // Fechar o modal de versículos
                      Navigator.pop(ctx);
                      // Fechar o modal de livros/capítulos
                      Navigator.pop(context);
                      // Navegar
                      widget.onNavigationComplete(book, chapter, verse);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.textColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: widget.textColor.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Text(
                          '$verse',
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sheetController) => Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Livros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
            ),

            // Campo de busca
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                style: TextStyle(color: widget.textColor),
                decoration: InputDecoration(
                  hintText: 'Buscar livro...',
                  hintStyle: TextStyle(color: widget.textColor.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.search, color: widget.textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: widget.textColor.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.activeColor, width: 1.5),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    // Limpar expansão ao buscar
                    if (value.isNotEmpty) _expandedBook = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 8),

            // Lista de livros com capítulos expansíveis
            Expanded(
              child: ListView.builder(
                controller: sheetController,
                itemCount: _filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = _filteredBooks[index];
                  final isExpanded = _expandedBook == book;
                  final isSelected = book == widget.selectedBook;
                  final maxChapters = widget.chaptersPerBook[book] ?? 1;

                  return Column(
                    children: [
                      // Livro
                      ListTile(
                        title: Text(
                          book,
                          style: TextStyle(
                            color: isSelected ? widget.activeColor : widget.textColor,
                            fontWeight: isSelected || isExpanded
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(Icons.check, color: widget.activeColor, size: 18),
                              ),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: widget.textColor.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _expandedBook = isExpanded ? null : book;
                          });
                        },
                      ),

                      // Grid de Capítulos (só constrói quando expandido)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Container(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: maxChapters,
                                  itemBuilder: (context, chIndex) {
                                    final chapter = chIndex + 1;
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => _onChapterTap(book, chapter),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: widget.activeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: widget.activeColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$chapter',
                                            style: TextStyle(
                                              color: widget.textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Divider sutil
                      if (!isExpanded)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: widget.textColor.withOpacity(0.06),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
