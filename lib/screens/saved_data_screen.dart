import 'package:flutter/material.dart';

import '../data/user_data_model.dart';
import '../data/models/dynamic_models.dart';
import '../data/supabase_service.dart';
import '../data/bible_repository.dart';
import '../services/note_export_service.dart';
import 'note_editor_screen.dart';
import 'devotional_reader_screen.dart';

/// Tela de dados salvos — usa o tema do sistema (light/dark) em vez do tema da Bíblia.
class SavedDataScreen extends StatefulWidget {
  final Function(String book, int chapter, int verse) onNavigateToVerse;
  final VoidCallback? onDataChanged;

  const SavedDataScreen({
    super.key,
    required this.onNavigateToVerse,
    this.onDataChanged,
  });

  @override
  State<SavedDataScreen> createState() => SavedDataScreenState();
}

class SavedDataScreenState extends State<SavedDataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  final BibleRepository _bibleRepository = BibleRepository(version: 'acf');

  List<Highlight> _highlights = [];
  List<UserNote> _notes = [];
  List<Devotional> _savedDevotionals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bibleRepository.ensureLoaded();
    _loadData();
  }

  Future<void> refreshData() async => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _supabaseService.getAllHighlights(),
      _supabaseService.getAllNotes(),
      _supabaseService.getSavedDevotionals(),
    ]);
    if (mounted) {
      setState(() {
        _highlights = results[0] as List<Highlight>;
        _notes = results[1] as List<UserNote>;
        _savedDevotionals = results[2] as List<Devotional>;
        _isLoading = false;
      });
    }
  }

  // --- Cores derivadas do tema do sistema ---
  Color _backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color _textColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
  }

  Color get _accentColor => Colors.amber.shade700;

  // --- DELETE ---
  Future<bool> _confirmDelete(String itemType) async {
    final bg = _backgroundColor(context);
    final txt = _textColor(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: bg,
            title: Text('Apagar $itemType?', style: TextStyle(color: txt)),
            content: Text(
              'Esta ação não pode ser desfeita imediatamente.',
              style: TextStyle(color: txt.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar',
                    style: TextStyle(color: txt.withValues(alpha: 0.6))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apagar',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // --- EDIT NOTE ---
  Future<void> _editNote(UserNote note) async {
    String verseText = 'Texto não encontrado.';
    try {
      final verses =
          await _bibleRepository.getChapter(note.book, note.chapter);
      final v = verses.firstWhere((e) => e['number'] == note.verse,
          orElse: () => {});
      if (v.isNotEmpty) verseText = v['text'];
    } catch (e) {
      debugPrint('Erro ao buscar texto do versículo: $e');
    }

    if (!mounted) return;

    final bg = _backgroundColor(context);
    final txt = _textColor(context);

    final resultJson = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          book: note.book,
          chapter: note.chapter,
          verseNumber: note.verse,
          verseText: verseText,
          initialNote: note.content,
          initialTitle: note.title,
          backgroundColor: bg,
          textColor: txt,
          accentColor: _accentColor,
        ),
      ),
    );

    if (resultJson != null && resultJson is Map) {
      try {
        final newContent = resultJson['content'] as String;
        final newTitle = resultJson['title'] as String?;

        final updatedNote = UserNote(
          id: note.id,
          book: note.book,
          chapter: note.chapter,
          verse: note.verse,
          content: newContent,
          title: newTitle,
          createdAt: note.createdAt,
          updatedAt: DateTime.now(),
        );

        await _supabaseService.saveNote(updatedNote);
        await refreshData();
        widget.onDataChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anotação salva com sucesso!')));
        }
      } catch (e) {
        debugPrint("Erro ao salvar nota: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao salvar anotação.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _backgroundColor(context);
    final txt = _textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text("Salvos",
            style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Botão só visível na tab de Anotações
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index != 1 || _notes.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Exportar todas as anotações',
                onPressed: () => NoteExportService.exportAllNotes(_notes),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accentColor,
          unselectedLabelColor: txt.withValues(alpha: 0.5),
          indicatorColor: _accentColor,
          dividerColor: txt.withValues(alpha: 0.1),
          tabs: const [
            Tab(text: "Destaques"),
            Tab(text: "Anotações"),
            Tab(text: "Devocionais"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _accentColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHighlightsTab(txt),
                _buildNotesTab(txt),
                _buildDevotionalsTab(txt),
              ],
            ),
    );
  }

  Widget _buildHighlightsTab(Color txt) {
    if (_highlights.isEmpty) return _buildEmptyState("Nenhum destaque encontrado.", txt);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _highlights.length,
      itemBuilder: (context, index) {
        final item = _highlights[index];
        final color = Color(item.color);

        return Dismissible(
          key: Key('highlight_${item.book}_${item.chapter}_${item.verse}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) => _confirmDelete('Destaque'),
          onDismissed: (_) => _deleteHighlightSwipe(index, item),
          child: GestureDetector(
            onTap: () => widget.onNavigateToVerse(item.book, item.chapter, item.verse),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: txt.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.book} ${item.chapter}:${item.verse}',
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grifo ${item.type == 'block' ? 'em bloco' : 'de texto'}',
                          style: TextStyle(
                            color: txt.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: txt.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteHighlightSwipe(int index, Highlight item) async {
    setState(() => _highlights.removeAt(index));
    await _supabaseService.removeHighlight(item.book, item.chapter, item.verse);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Destaque removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await _supabaseService.saveHighlight(item);
              _loadData();
              widget.onDataChanged?.call();
            },
          ),
        ),
      );
    }
    widget.onDataChanged?.call();
  }

  Widget _buildNotesTab(Color txt) {
    if (_notes.isEmpty) return _buildEmptyState("Nenhuma anotação encontrada.", txt);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];

        return Dismissible(
          key: Key('note_${note.book}_${note.chapter}_${note.verse}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) => _confirmDelete('Anotação'),
          onDismissed: (_) => _deleteNoteSwipe(index, note),
          child: GestureDetector(
            onTap: () => _editNote(note),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: txt.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: txt.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark, size: 14, color: _accentColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${note.book} ${note.chapter}:${note.verse}',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Botão de partilhar nota individual
                      InkWell(
                        onTap: () => NoteExportService.exportNote(note),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.ios_share_rounded,
                            size: 16,
                            color: txt.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 12, color: txt.withValues(alpha: 0.3)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (note.title != null && note.title!.isNotEmpty) ...[
                    Text(
                      note.title!,
                      style: TextStyle(
                        color: txt,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    note.previewText,
                    style: TextStyle(
                      color: txt.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Editado em ${_formatDate(note.updatedAt)}",
                    style: TextStyle(
                      color: txt.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNoteSwipe(int index, UserNote item) async {
    setState(() => _notes.removeAt(index));
    await _supabaseService.deleteNote(item.book, item.chapter, item.verse);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anotação removida'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              await _supabaseService.saveNote(item);
              _loadData();
              widget.onDataChanged?.call();
            },
          ),
        ),
      );
    }
    widget.onDataChanged?.call();
  }

  Widget _buildEmptyState(String msg, Color txt) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: txt.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: txt.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  Widget _buildDevotionalsTab(Color txt) {
    if (_savedDevotionals.isEmpty) {
      return _buildEmptyState(
          'Nenhum devocional salvo.\nSalve devocionais tocando no ícone 🔖', txt);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedDevotionals.length,
      itemBuilder: (context, index) {
        final devotional = _savedDevotionals[index];
        return Dismissible(
          key: Key('devotional_${devotional.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
          ),
          confirmDismiss: (_) => _confirmDelete('Devocional salvo'),
          onDismissed: (_) async {
            final removed = _savedDevotionals.removeAt(index);
            setState(() {});
            final messenger = ScaffoldMessenger.of(context);
            await _supabaseService.unsaveDevotional(removed.id);
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Devocional removido dos salvos'),
                  action: SnackBarAction(
                    label: 'Desfazer',
                    onPressed: () async {
                      await _supabaseService.saveDevotional(removed.id);
                      _loadData();
                    },
                  ),
                ),
              );
            }
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DevotionalReaderScreen(
                    title: devotional.title,
                    content: devotional.content,
                    readingTimeMin: devotional.readingTimeMin,
                    publishDate: devotional.publishDate,
                    devotionalId: devotional.id,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: txt.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: txt.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.coffee,
                        color: Colors.brown.shade400, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          devotional.title,
                          style: TextStyle(
                            color: txt,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(devotional.publishDate)} • ${devotional.readingTimeMin} min',
                          style: TextStyle(
                            color: txt.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: txt.withValues(alpha: 0.3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
