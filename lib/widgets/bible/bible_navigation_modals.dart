import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../data/bible_repository.dart';

class BibleModals {

  /// Modal principal de navegação: Livro → Capítulo → Versículo
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

  /// Seletor de versão com suporte a download inline (KJV, NIV, etc.)
  static void showVersionSelector(
    BuildContext context, {
    required Color backgroundColor,
    required Color textColor,
    required Color activeColor,
    required String currentVersion,
    required Map<String, String> availableVersions,
    required Function(String) onVersionSelected,
    required Future<void> Function(String, Function(double)) onDownloadVersion,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _VersionSelectorSheet(
        backgroundColor: backgroundColor,
        textColor: textColor,
        activeColor: activeColor,
        currentVersion: currentVersion,
        availableVersions: availableVersions,
        onVersionSelected: onVersionSelected,
        onDownloadVersion: onDownloadVersion,
      ),
    );
  }
}

// ===========================================================================
// _VersionSelectorSheet — modal com estados de instalação e download
// ===========================================================================

class _VersionSelectorSheet extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color activeColor;
  final String currentVersion;
  final Map<String, String> availableVersions;
  final Function(String) onVersionSelected;
  final Future<void> Function(String, Function(double)) onDownloadVersion;

  const _VersionSelectorSheet({
    required this.backgroundColor,
    required this.textColor,
    required this.activeColor,
    required this.currentVersion,
    required this.availableVersions,
    required this.onVersionSelected,
    required this.onDownloadVersion,
  });

  @override
  State<_VersionSelectorSheet> createState() => _VersionSelectorSheetState();
}

class _VersionSelectorSheetState extends State<_VersionSelectorSheet> {
  // verCode → true se instalada
  final Map<String, bool> _installed = {};
  // verCode → progresso de download (null = não está a baixar)
  final Map<String, double?> _downloadProgress = {};
  // verCode → mensagem de erro
  final Map<String, String?> _errors = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  Future<void> _checkInstalled() async {
    final results = await Future.wait(
      widget.availableVersions.keys.map(
        (code) => BibleRepository.isVersionDownloaded(code),
      ),
    );
    if (!mounted) return;
    setState(() {
      int i = 0;
      for (final code in widget.availableVersions.keys) {
        _installed[code] = results[i++];
      }
      _isLoading = false;
    });
  }

  Future<void> _startDownload(String code) async {
    setState(() {
      _downloadProgress[code] = 0.0;
      _errors[code] = null;
    });
    try {
      await widget.onDownloadVersion(code, (progress) {
        if (mounted) setState(() => _downloadProgress[code] = progress);
      });
      if (mounted) {
        setState(() {
          _installed[code] = true;
          _downloadProgress[code] = null;
        });
        // Seleccionar automaticamente após download
        widget.onVersionSelected(code);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress[code] = null;
          _errors[code] = 'Falha no download. Verifique a ligação.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = widget.availableVersions.entries
        .where((e) => _installed[e.key] == true)
        .toList();
    final notInstalled = widget.availableVersions.entries
        .where((e) => _installed[e.key] != true)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.textColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  'Versão da Bíblia',
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: widget.activeColor),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Secção: Instaladas
                  if (installed.isNotEmpty) ...[
                    _buildSectionHeader('INSTALADAS'),
                    ...installed.map((e) => _buildInstalledTile(e.key, e.value)),
                    const SizedBox(height: 8),
                  ],

                  // Secção: Disponíveis para download
                  if (notInstalled.isNotEmpty) ...[
                    _buildSectionHeader('DISPONÍVEIS PARA DOWNLOAD'),
                    ...notInstalled.map(
                      (e) => _buildDownloadTile(e.key, e.value),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: widget.textColor.withOpacity(0.45),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(String code) async {
    final name = widget.availableVersions[code] ?? code;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apagar $name?', style: TextStyle(color: widget.textColor, fontSize: 16)),
        content: Text(
          'O ficheiro será removido do dispositivo.\nPodes voltar a baixar a qualquer momento.',
          style: TextStyle(color: widget.textColor.withOpacity(0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: widget.textColor.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await BibleRepository.deleteVersion(code);

    // Se a versão ativa foi apagada, mudar para ACF
    final wasActive = widget.currentVersion.toUpperCase() == code.toUpperCase();
    if (wasActive) {
      widget.onVersionSelected('ACF');
    }

    // Atualizar a lista
    setState(() => _installed[code] = false);
  }

  Widget _buildInstalledTile(String code, String name) {
    final isSelected = widget.currentVersion.toUpperCase() == code.toUpperCase();
    final canDelete = !BibleRepository.isBundled(code);

    return _VersionTile(
      code: code,
      name: name,
      textColor: widget.textColor,
      activeColor: widget.activeColor,
      isSelected: isSelected,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canDelete)
            GestureDetector(
              onTap: () => _confirmAndDelete(code),
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: widget.textColor.withOpacity(0.35),
                ),
              ),
            ),
          isSelected
              ? Icon(Icons.check_circle_rounded, color: widget.activeColor, size: 22)
              : Icon(Icons.circle_outlined,
                  color: widget.textColor.withOpacity(0.25), size: 22),
        ],
      ),
      onTap: () {
        if (!isSelected) widget.onVersionSelected(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDownloadTile(String code, String name) {
    final progress = _downloadProgress[code];
    final isDownloading = progress != null;
    final error = _errors[code];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VersionTile(
          code: code,
          name: name,
          textColor: widget.textColor,
          activeColor: widget.activeColor,
          isSelected: false,
          trailing: isDownloading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: widget.activeColor,
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded,
                          size: 14, color: widget.activeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Baixar',
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
          onTap: isDownloading ? null : () => _startDownload(code),
        ),

        if (isDownloading && progress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: widget.textColor.withOpacity(0.08),
                    color: widget.activeColor,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.textColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tile reutilizável para uma versão da Bíblia
class _VersionTile extends StatelessWidget {
  final String code;
  final String name;
  final Color textColor;
  final Color activeColor;
  final bool isSelected;
  final Widget trailing;
  final VoidCallback? onTap;

  const _VersionTile({
    required this.code,
    required this.name,
    required this.textColor,
    required this.activeColor,
    required this.isSelected,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.08)
              : textColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? activeColor.withOpacity(0.4)
                : textColor.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.15)
                    : textColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : textColor.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? activeColor : textColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
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
