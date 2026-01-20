import 'dart:convert'; // Required for jsonDecode/jsonEncode
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../data/user_data_model.dart';
import '../data/supabase_service.dart';
import '../data/bible_repository.dart';
import 'note_editor_screen.dart';
import 'package:flutter/services.dart';

class SavedDataScreen extends StatefulWidget {
  final ReadingTheme currentTheme;
  final Function(String book, int chapter, int verse) onNavigateToVerse;
  final VoidCallback? onDataChanged;

  const SavedDataScreen({
    super.key,
    required this.currentTheme,
    required this.onNavigateToVerse,
    this.onDataChanged,
  });

  @override
  State<SavedDataScreen> createState() => SavedDataScreenState();
}

class SavedDataScreenState extends State<SavedDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  final BibleRepository _bibleRepository = BibleRepository(version: 'acf'); // Default version for fetching text context
  
  List<Highlight> _highlights = [];
  List<UserNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bibleRepository.ensureLoaded(); // Ensure bible data is loaded
    _loadData();
  }

  // Método público para ser chamado pelo Pai (Auto-Refresh)
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final h = await _supabaseService.getAllHighlights();
    final n = await _supabaseService.getAllNotes();
    if (mounted) {
      setState(() {
        _highlights = h;
        _notes = n;
        _isLoading = false;
      });
    }
  }

  // --- DELETE LOGIC (Common) ---
  Future<bool> _confirmDelete(String itemType) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Apagar $itemType?', style: TextStyle(color: _textColor)),
        content: Text('Esta ação não pode ser desfeita imediatamente, mas você terá uma chance de "Desfazer".', style: TextStyle(color: _textColor.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: _textColor.withOpacity(0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteHighlight(int index) async {
    final item = _highlights[index];
    final confirmed = await _confirmDelete('Destaque');
    if (!confirmed) return;

    // Optimistic UI Update
    setState(() {
      _highlights.removeAt(index);
    });

    await _supabaseService.removeHighlight(item.book, item.chapter, item.verse);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Destaque removido'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              // Undo Logic
              await _supabaseService.saveHighlight(item);
              _loadData(); // Reload to restore correct order
              widget.onDataChanged?.call(); // Refresh bible screen
            },
          ),
        ),
      );
    }
    widget.onDataChanged?.call(); // Refresh bible screen
  }

  Future<void> _deleteNote(int index) async {
    final item = _notes[index];
    final confirmed = await _confirmDelete('Anotação');
    if (!confirmed) return;

    // Optimistic UI Update
    setState(() {
      _notes.removeAt(index);
    });

    await _supabaseService.deleteNote(item.book, item.chapter, item.verse);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anotação removida'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              // Undo Logic
              await _supabaseService.saveNote(item);
              _loadData();
              widget.onDataChanged?.call(); // Refresh bible screen
            },
          ),
        ),
      );
    }
    widget.onDataChanged?.call(); // Refresh bible screen
  }

  // --- EDIT LOGIC (Notes) ---
  Future<void> _editNote(UserNote note) async {
    // 1. Get Verse Text for Context
    String verseText = 'Texto não encontrado.';
    try {
      final verses = await _bibleRepository.getChapter(note.book, note.chapter);
      final v = verses.firstWhere((e) => e['number'] == note.verse, orElse: () => {});
      if (v.isNotEmpty) verseText = v['text'];
    } catch (e) {
      print('Erro ao buscar texto do versículo: $e');
    }

    if (!mounted) return;

    // 2. Open Editor
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
          backgroundColor: _backgroundColor,
          textColor: _textColor,
          accentColor: _accentColor,
        ),
      ),
    );

    // 3. Save if changed
    if (resultJson != null && resultJson is String) { 
      try {
        final Map<String, dynamic> data = jsonDecode(resultJson);
        // data has: 'delta' (Map), 'plainText' (String), 'title' (String?), 'hasTitle' (bool), 'updatedAt' (String)
        
        // Convert Delta Map to formatted String for storage (consistent with UserNote expectation)
        final newContent = jsonEncode(data['delta']);
        final newTitle = data['title'] as String?;
        
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
        widget.onDataChanged?.call(); // Refresh bible screen
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anotação salva com sucesso!')));
        }
      } catch (e) {
        print("Erro ao salvar nota: $e");
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar anotação.')));
        }
      }
    }
  }
  
  // Helpers de Estilo
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
  
  Color get _accentColor => AppTheme.accentGold;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text("Salvos", style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Refresh Button Removed as per request (Auto-Refresh implemented)
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accentColor,
          unselectedLabelColor: _textColor.withOpacity(0.5),
          indicatorColor: _accentColor,
          dividerColor: _textColor.withOpacity(0.1),
          tabs: const [
            Tab(text: "Destaques"),
            Tab(text: "Anotações"),
          ],
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _accentColor))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildHighlightsTab(),
              _buildNotesTab(),
            ],
          ),
    );
  }

  Widget _buildHighlightsTab() {
    if (_highlights.isEmpty) return _buildEmptyState("Nenhum destaque encontrado.");

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
          confirmDismiss: (direction) async {
             return await _confirmDelete('Destaque'); // Swipe confirm
          },
          onDismissed: (direction) {
             // Already confirmed
             _deleteHighlightSwipe(index, item); // Specialized method for swipe to avoid double dialog
          },
          child: GestureDetector(
            onTap: () => widget.onNavigateToVerse(item.book, item.chapter, item.verse),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _textColor.withOpacity(0.05),
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
                            color: _textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grifo ${item.type == 'block' ? 'em bloco' : 'de texto'}',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.6),
                            fontSize: 12
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: _textColor.withOpacity(0.3)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Swipe specific logic (since confirmDismiss handles the dialog)
  Future<void> _deleteHighlightSwipe(int index, Highlight item) async {
    // UI already removed by Dismissible
    // Just sync DB and Show Undo
    setState(() {
      _highlights.removeAt(index);
    });
    
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

  Widget _buildNotesTab() {
    if (_notes.isEmpty) return _buildEmptyState("Nenhuma anotação encontrada.");
    
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
          confirmDismiss: (direction) async {
             return await _confirmDelete('Anotação');
          },
          onDismissed: (direction) {
             _deleteNoteSwipe(index, note);
          },
          child: GestureDetector(
            onTap: () => _editNote(note), // Tap to EDIT
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _textColor.withOpacity(0.1)),
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
                           style: TextStyle(color: _accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       // Swipe indicator hint (optional, kept simple for now)
                       Icon(Icons.arrow_forward_ios, size: 12, color: _textColor.withOpacity(0.3)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   if (note.title != null && note.title!.isNotEmpty) ...[
                     Text(
                       note.title!,
                       style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 16),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 6),
                   ],
                   Text(
                     note.previewText,
                     style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 14, height: 1.5),
                     maxLines: 3,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 12),
                   Text(
                     "Editado em ${_formatDate(note.updatedAt)}",
                     style: TextStyle(color: _textColor.withOpacity(0.4), fontSize: 11),
                   ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Swipe logic for Notes
  Future<void> _deleteNoteSwipe(int index, UserNote item) async {
    setState(() {
      _notes.removeAt(index);
    });

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

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: _textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: _textColor.withOpacity(0.5))),
          // removed manual reload button
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
