import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../data/user_data_model.dart';
import '../data/supabase_service.dart';
import 'package:flutter/services.dart';

class SavedDataScreen extends StatefulWidget {
  final ReadingTheme currentTheme;
  final Function(String book, int chapter, int verse) onNavigateToVerse;

  const SavedDataScreen({
    super.key,
    required this.currentTheme,
    required this.onNavigateToVerse,
  });

  @override
  State<SavedDataScreen> createState() => _SavedDataScreenState();
}

class _SavedDataScreenState extends State<SavedDataScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Highlight> _highlights = [];
  List<UserNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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
  
  // Helpers de Estilo (mesmos da HomeScreen/Bible para consistência)
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
        title: Text("Meus Dados", style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: _textColor),
            onPressed: _loadData,
          )
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
        
        return GestureDetector(
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
        );
      },
    );
  }

  Widget _buildNotesTab() {
    if (_notes.isEmpty) return _buildEmptyState("Nenhuma anotação encontrada.");
    
    // Grid View para notas parece mais bonito
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85
      ),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return GestureDetector(
          onTap: () => widget.onNavigateToVerse(note.book, note.chapter, note.verse),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
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
                         style: TextStyle(color: _accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                         overflow: TextOverflow.ellipsis,
                       ),
                     )
                   ],
                 ),
                 const SizedBox(height: 8),
                 Text(
                   note.title ?? 'Sem título',
                   style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 15),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 8),
                 Expanded(
                   child: Text(
                     note.previewText,
                     style: TextStyle(color: _textColor.withOpacity(0.7), fontSize: 12, height: 1.4),
                     overflow: TextOverflow.fade,
                   ),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   _formatDate(note.updatedAt),
                   style: TextStyle(color: _textColor.withOpacity(0.4), fontSize: 10),
                 ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: _textColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: _textColor.withOpacity(0.5))),
          TextButton(onPressed: _loadData, child: Text('Recarregar', style: TextStyle(color: _accentColor)))
        ],
      ),
    );
  }
  
  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
