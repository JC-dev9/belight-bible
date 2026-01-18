import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_data_model.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // --- HIGHLIGHTS ---

  Future<List<Highlight>> getHighlights(String book, int chapter) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('highlights')
          .select()
          .eq('user_id', userId)
          .eq('book', book)
          .eq('chapter', chapter);

      return (response as List).map((e) => Highlight.fromJson(e)).toList();
    } catch (e) {
      // Fail silently or log error
      print('Error fetching highlights: $e');
      return [];
    }
  }

  Future<List<Highlight>> getAllHighlights() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      // Limit to 500 latest highlights for performance
      final response = await _client
          .from('highlights')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(500);

      return (response as List).map((e) => Highlight.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching all highlights: $e');
      return [];
    }
  }

  Future<void> saveHighlight(Highlight highlight) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('highlights').upsert({
        ...highlight.toJson(),
        'user_id': userId,
      }, onConflict: 'user_id, book, chapter, verse');
    } catch (e) {
      print('Error saving highlight: $e');
    }
  }

  Future<void> removeHighlight(String book, int chapter, int verse) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('highlights')
          .delete()
          .eq('user_id', userId)
          .eq('book', book)
          .eq('chapter', chapter)
          .eq('verse', verse);
    } catch (e) {
      print('Error deleting highlight: $e');
    }
  }

  // --- NOTES ---

  Future<List<UserNote>> getNotes(String book, int chapter) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .eq('book', book)
          .eq('chapter', chapter);

      return (response as List).map((e) => UserNote.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching notes: $e');
      return [];
    }
  }

  Future<List<UserNote>> getAllNotes() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(200);

      return (response as List).map((e) => UserNote.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching all notes: $e');
      return [];
    }
  }

  Future<void> saveNote(UserNote note) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('notes').upsert({
        ...note.toJson(),
        'user_id': userId,
      }, onConflict: 'user_id, book, chapter, verse');
    } catch (e) {
      print('Error saving note: $e');
    }
  }
  
    Future<void> deleteNote(String book, int chapter, int verse) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('notes')
          .delete()
          .eq('user_id', userId)
          .eq('book', book)
          .eq('chapter', chapter)
          .eq('verse', verse);
    } catch (e) {
      print('Error deleting note: $e');
    }
  }
}
