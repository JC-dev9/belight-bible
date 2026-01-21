import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../utils/theme.dart';
import '../data/bible_repository.dart';
import '../data/supabase_service.dart';
import '../data/user_data_model.dart';

import '../widgets/bible/bible_types.dart';
import '../widgets/bible/bible_header.dart';
import '../widgets/bible/bible_bottom_controls.dart';
import '../widgets/bible/verse_list.dart';
import '../widgets/bible/selection_panel.dart';
import '../widgets/bible/bible_settings_modal.dart';
import '../widgets/bible/bible_navigation_modals.dart';

import 'chatbot_screen.dart';
import 'note_editor_screen.dart';

/// Tela responsável por exibir o texto da Bíblia, lidar com navegação,
/// destaques, notas e interações do utilizador.
class BibleReaderScreen extends StatefulWidget {
  final ReadingTheme currentTheme;
  final Function(ReadingTheme) onThemeChanged;
  final Function(String)? onAskAI;

  const BibleReaderScreen({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.onAskAI,
  });

  @override
  State<BibleReaderScreen> createState() => BibleReaderScreenState();
}

class BibleReaderScreenState extends State<BibleReaderScreen> {
  // Dependências de Serviço
  late BibleRepository _bibleRepository;
  final SupabaseService _supabaseService = SupabaseService();

  // Estado de Dados
  String _selectedBook = 'Gênesis';
  int _selectedChapter = 1;
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  // Estado da UI
  HighlightStyle _selectedHighlightStyle = HighlightStyle.fundoVersiculo;
  double _fontSize = 18.0;
  int? _focusedVerseIndex;
  
  // Estado de Seleção
  final Set<int> _selectedVerses = {};
  
  // Controlador de Scroll
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // Constantes
  final List<Color> _availableColors = [
    AppTheme.accentGold,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.pink.shade300,
    Colors.purple.shade300,
    Colors.orange.shade300,
    Colors.teal.shade300,
    Colors.brown.shade300,
  ];

  // ===========================================================================
  // Ciclo de Vida e Métodos Públicos
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _bibleRepository = BibleRepository(version: 'acf');
    _loadInitialData();
  }

  /// Recarrega os dados do capítulo atual. Útil para sincronizar mudanças externas.
  Future<void> refreshData() async {
    await _loadChapter();
  }

  /// Navega para um versículo específico, lidando com mudanças de Livro/Capítulo se necessário.
  Future<void> jumpToVerse(String book, int chapter, int verse) async {
    final bool needsNavigation = _selectedBook != book || _selectedChapter != chapter;

    if (needsNavigation) {
      setState(() {
        _selectedBook = book;
        _selectedChapter = chapter;
        _selectedVerses.clear();
      });
      await _loadChapter();
    } else {
      // Limpara a seleção se estivermos apenas a saltar dentro do mesmo capítulo vindo de fora
      setState(() => _selectedVerses.clear());
    }

    // Scroll para o versículo após renderização do frame para garantir que a lista está pronta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verses.isNotEmpty && verse > 0 && verse <= _verses.length) {
        setState(() => _focusedVerseIndex = verse - 1);
        
        _itemScrollController.scrollTo(
          index: verse - 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.3,
        );
      }
    });
  }

  // ===========================================================================
  // Carregamento de Dados
  // ===========================================================================

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await _bibleRepository.ensureLoaded();
      await _loadChapter();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erro ao carregar dados. Verifique a versão.', isError: true);
      }
    }
  }

  Future<void> _loadChapter() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final newVerses = await _bibleRepository.getChapter(_selectedBook, _selectedChapter);
      
      // Carregar Dados do Utilizador (Destaques e Notas) concorrentemente
      // Usar Future.wait poderia ser mais rápido, mas serial é mais seguro para lógica de erro simples aqui
      final highlights = await _supabaseService.getHighlights(_selectedBook, _selectedChapter);
      final notes = await _supabaseService.getNotes(_selectedBook, _selectedChapter);

      _mergeUserDataIntoVerses(newVerses, highlights, notes);

      setState(() {
        _verses = newVerses;
        _isLoading = false;
      });

      // Resetar posição do scroll
      if (_verses.isNotEmpty) {
        try {
          _itemScrollController.jumpTo(index: 0);
        } catch (_) {
          // O controlador pode ainda não estar anexado
        }
      }

    } catch (e) {
      debugPrint("Erro ao carregar capítulo: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _verses = [];
        });
        _showSnackBar('Erro ao carregar capítulo.', isError: true, action: _loadChapter);
      }
    }
  }

  void _mergeUserDataIntoVerses(
    List<Map<String, dynamic>> verses,
    List<Highlight> highlights,
    List<UserNote> notes
  ) {
    for (var verse in verses) {
      final vNum = verse['number'];

      // Merge Highlights
      final highlight = highlights.firstWhere(
        (h) => h.verse == vNum,
        orElse: () => Highlight(book: '', chapter: 0, verse: -1, color: 0, type: ''),
      );
      
      if (highlight.verse != -1) {
        verse['highlighted'] = Color(highlight.color);
      }

      // Merge Notes
      final note = notes.firstWhere(
        (n) => n.verse == vNum,
        orElse: () => UserNote(book: '', chapter: 0, verse: -1, content: ''),
      );
      
      if (note.verse != -1) {
        verse['note'] = note.content;
        verse['note_title'] = note.title;
      }
    }
  }

  // ===========================================================================
  // Lógica de Navegação
  // ===========================================================================

  void _navigateChapter(int delta) {
    final maxChapters = _bibleRepository.chaptersPerBook[_selectedBook] ?? 1;
    final newChapter = _selectedChapter + delta;

    if (newChapter >= 1 && newChapter <= maxChapters) {
      setState(() {
        _selectedChapter = newChapter;
        _selectedVerses.clear();
      });
      _loadChapter();
    } else if (newChapter > maxChapters) {
      _showSnackBar('Último capítulo de $_selectedBook.');
    }
  }

  // ===========================================================================
  // Helpers de Tema
  // ===========================================================================

  Color get _backgroundColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark: return AppColors.darkBg;
      case ReadingTheme.sepia: return AppColors.sepiaBg;
      default: return Colors.white;
    }
  }

  Color get _textColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark: return Colors.grey.shade300;
      case ReadingTheme.sepia: return AppColors.sepiaText;
      default: return Colors.grey.shade900;
    }
  }

  Color get _verseNumColor {
    switch (widget.currentTheme) {
      case ReadingTheme.dark: return Colors.grey.shade600;
      case ReadingTheme.sepia: return AppColors.sepiaAccent;
      default: return Colors.grey.shade500;
    }
  }

  Color get _activeColor => AppTheme.accentGold;

  // ===========================================================================
  // Tratamento de Ações
  // ===========================================================================

  void _handleVerseTap(int index) {
    if (_selectedVerses.isNotEmpty) {
      setState(() {
        if (_selectedVerses.contains(index)) {
          _selectedVerses.remove(index);
        } else {
          _selectedVerses.add(index);
        }
      });
    } else {
      setState(() {
        _selectedVerses.add(index);
      });
    }
  }

  void _handleVerseLongPress(int index) {
    setState(() {
      _selectedVerses.add(index);
    });
  }

  Future<void> _handleColorSelected(Color color) async {
    setState(() {
      for (var i in _selectedVerses) {
        _verses[i]['highlighted'] = color;
        final dbColor = color.value.toSigned(32);
        
        _supabaseService.saveHighlight(Highlight(
          book: _selectedBook,
          chapter: _selectedChapter,
          verse: _verses[i]['number'],
          color: dbColor,
          type: _selectedHighlightStyle == HighlightStyle.fundoTexto ? 'text' : 'block',
        ));
      }
      _selectedVerses.clear();
    });
  }

  Future<void> _handleResetHighlight() async {
    setState(() {
      for (var i in _selectedVerses) {
        _verses[i]['highlighted'] = null;
        _supabaseService.removeHighlight(_selectedBook, _selectedChapter, _verses[i]['number']);
      }
      _selectedVerses.clear();
    });
  }

  void _handleCopy() {
    final text = _getSelectedText();
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() => _selectedVerses.clear());
      _showSnackBar('Copiado');
    }
  }

  Future<void> _handleShare() async {
    final text = _getSelectedText();
    await Share.share(text);
    if (mounted) {
      setState(() => _selectedVerses.clear());
    }
  }

  Future<void> _handleAskAI() async {
    final text = _getSelectedText();
    final prompt = "Explique: \"$text\"";
    
    if (mounted) {
      setState(() => _selectedVerses.clear());
      if (widget.onAskAI != null) {
        widget.onAskAI!(prompt);
      } else {
         Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatBotScreen(initialPrompt: prompt),
            ),
          );
      }
    }
  }

  void _handleNoteTapInMenu() {
    if (_selectedVerses.length == 1) {
      final index = _selectedVerses.first;
      setState(() => _selectedVerses.clear());
      _showNoteEditor(index);
    } else {
      _showSnackBar('Selecione apenas 1 para anotar');
    }
  }

  Future<void> _showNoteEditor(int index) async {
    final note = _verses[index]['note'];
    final noteTitle = _verses[index]['note_title'];
    final verseNumber = _verses[index]['number'];
    final verseText = _verses[index]['text'];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          book: _selectedBook,
          chapter: _selectedChapter,
          verseNumber: verseNumber,
          verseText: verseText,
          initialNote: note,
          initialTitle: noteTitle,
          backgroundColor: _backgroundColor,
          textColor: _textColor,
          accentColor: _activeColor,
        ),
      ),
    );

    if (result != null && result is Map) {
      _saveNoteResult(index, result, verseNumber);
    }
  }

  Future<void> _saveNoteResult(int index, Map result, int verseNumber) async {
      String? title = result['title'];
      String contentToSave = result['content'] ?? '';
      // Color might be used in the future or stored in content
      
      // Update local state
      setState(() {
        _verses[index]['note'] = contentToSave;
        _verses[index]['note_title'] = title;
      });

      await _supabaseService.saveNote(UserNote(
        book: _selectedBook,
        chapter: _selectedChapter,
        verse: verseNumber,
        content: contentToSave,
        title: title,
      ));

      _showSnackBar('Anotação salva e sincronizada');
  }

  String _getSelectedText() {
    final sortedIndices = _selectedVerses.toList()..sort();
    final buffer = StringBuffer();
    for (var i in sortedIndices) {
      final v = _verses[i];
      buffer.write('${v['text']} ($_selectedBook $_selectedChapter:${v['number']})\n');
    }
    return buffer.toString().trim();
  }

  // ===========================================================================
  // Modais e Diálogos
  // ===========================================================================

  void _showDisplaySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Usar StatefulBuilder se quisermos redesenhar apenas o modal em mudanças internas,
        // mas como passamos callbacks que chamam setState no pai, o pai reconstrói.
        // Reconstruir o pai reconstrói o modal. Isto está ok.
        return BibleSettingsSheet(
          currentTheme: widget.currentTheme,
          fontSize: _fontSize,
          onFontSizeChanged: (val) => setState(() => _fontSize = val),
          onThemeChanged: (theme) => widget.onThemeChanged(theme),
        );
      },
    );
  }

  void _showAdvancedColorPicker(BuildContext context) {
    Color tempColor = Colors.orange.shade200;
    final List<Color> presets = [
      ...Colors.primaries.map((c) => c.shade200),
      ...Colors.accents.map((c) => c.withOpacity(0.5)),
    ];
    
    // We use the first selected verse for preview
    final int previewVerseIndex = _selectedVerses.isNotEmpty ? _selectedVerses.first : 0;
    final String previewText = _verses.isNotEmpty ? _verses[previewVerseIndex]['text'] : "Texto de exemplo";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) => AlertDialog(
          backgroundColor: _backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nova Cor e Preview', style: TextStyle(color: _textColor, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_selectedHighlightStyle == HighlightStyle.fundoVersiculo)
                      ? tempColor.withOpacity(widget.currentTheme == ReadingTheme.dark ? 0.3 : 0.4)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tempColor),
                ),
                child: Text(
                  previewText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    backgroundColor: (_selectedHighlightStyle == HighlightStyle.fundoTexto)
                        ? tempColor.withOpacity(0.5)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Color Grid
              SizedBox(
                width: double.maxFinite,
                height: 200,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: presets.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setPickerState(() => tempColor = presets[i]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: presets[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tempColor == presets[i] ? _textColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: _textColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _activeColor),
              onPressed: () {
                _handleColorSelected(tempColor);
                Navigator.pop(context);
              },
              child: const Text('Aplicar', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false, VoidCallback? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        action: action != null
            ? SnackBarAction(label: 'Tentar', onPressed: action, textColor: _activeColor)
            : null,
      ),
    );
  }

  // ===========================================================================
  // Build Method
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      tween: ColorTween(begin: Colors.white, end: _backgroundColor),
      builder: (context, animatedBgColor, child) {
        return TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          tween: ColorTween(begin: Colors.black, end: _textColor),
          builder: (context, animatedTextColor, _) {
            final bgColor = animatedBgColor ?? Colors.white;
            final txtColor = animatedTextColor ?? Colors.black;

            return Scaffold(
              backgroundColor: bgColor,
              body: SafeArea(
                child: Column(
                  children: [
                    BibleHeader(
                      backgroundColor: bgColor,
                      textColor: txtColor,
                      book: _selectedBook,
                      version: _bibleRepository.version,
                      activeColor: _activeColor,
                      onVersionTap: () => BibleModals.showVersionSelector(
                        context,
                        backgroundColor: bgColor,
                        textColor: txtColor,
                        activeColor: _activeColor,
                        currentVersion: _bibleRepository.version,
                        availableVersions: BibleRepository.availableVersions,
                        onVersionSelected: (version) async {
                          _bibleRepository.version = version;
                          await _loadInitialData();
                        },
                      ),
                      onBookTap: () => BibleModals.showBookSelector(
                        context,
                        backgroundColor: bgColor,
                        textColor: txtColor,
                        activeColor: _activeColor,
                        allBooks: _bibleRepository.allBooks,
                        selectedBook: _selectedBook,
                        onBookSelected: (book) {
                          setState(() {
                            _selectedBook = book;
                            _selectedChapter = 1;
                            _selectedVerses.clear();
                          });
                          _loadChapter();
                        },
                      ),
                      onSettingsTap: _showDisplaySettings,
                    ),
                    
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: _activeColor))
                          : _verses.isEmpty
                              ? _buildErrorState(txtColor)
                              : VerseList(
                                  verses: _verses,
                                  itemScrollController: _itemScrollController,
                                  itemPositionsListener: _itemPositionsListener,
                                  baseTextColor: txtColor,
                                  fontSize: _fontSize,
                                  selectedHighlightStyle: _selectedHighlightStyle,
                                  focusedVerseIndex: _focusedVerseIndex,
                                  selectedVerses: _selectedVerses,
                                  verseNumColor: _verseNumColor,
                                  activeColor: _activeColor,
                                  currentTheme: widget.currentTheme,
                                  onClearFocus: () {
                                    if (_focusedVerseIndex != null) {
                                      setState(() => _focusedVerseIndex = null);
                                    }
                                  },
                                  onVerseTap: _handleVerseTap,
                                  onVerseLongPress: _handleVerseLongPress,
                                  onNoteTap: (index) => _showNoteEditor(index),
                                ),
                    ),

                    if (_selectedVerses.isNotEmpty)
                      SelectionPanel(
                        backgroundColor: bgColor,
                        textColor: txtColor,
                        activeColor: _activeColor,
                        selectedVerses: _selectedVerses,
                        availableColors: _availableColors,
                        currentHighlightStyle: _selectedHighlightStyle,
                        onClose: () => setState(() => _selectedVerses.clear()),
                        onResetHighlight: _handleResetHighlight,
                        onColorSelected: _handleColorSelected,
                        onStyleToggle: (style) => setState(() => _selectedHighlightStyle = style),
                        onAdvancedColorTap: _showAdvancedColorPicker,
                        onCopy: _handleCopy,
                        onShare: _handleShare,
                        onNote: _handleNoteTapInMenu,
                        onAskAI: _handleAskAI,
                      )
                    else
                      BibleBottomControls(
                        backgroundColor: bgColor,
                        textColor: txtColor,
                        currentChapter: _selectedChapter,
                        isFirstChapter: _selectedChapter == 1,
                        isLastChapter: _selectedChapter == (_bibleRepository.chaptersPerBook[_selectedBook] ?? 1),
                        onPrevious: () => _navigateChapter(-1),
                        onNext: () => _navigateChapter(1),
                        onChapterTap: () => BibleModals.showChapterSelector(
                          context,
                          backgroundColor: bgColor,
                          textColor: txtColor,
                          activeColor: _activeColor,
                          selectedBook: _selectedBook,
                          selectedChapter: _selectedChapter,
                          maxChapters: _bibleRepository.chaptersPerBook[_selectedBook] ?? 1,
                          onChapterSelected: (chapter) {
                            setState(() {
                              _selectedChapter = chapter;
                              _selectedVerses.clear();
                            });
                            _loadChapter();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: textColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Não foi possível carregar os dados.', style: TextStyle(color: textColor)),
          TextButton(
            onPressed: _loadInitialData,
            style: TextButton.styleFrom(foregroundColor: _activeColor),
            child: const Text('Tentar Novamente'),
          )
        ],
      ),
    );
  }
}