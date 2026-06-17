import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_data_model.dart';
import 'models/dynamic_models.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ===========================================================================
  // HIGHLIGHTS
  // ===========================================================================

  Future<List<Highlight>> getHighlights(String book, int chapter) async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('highlights')
          .select()
          .eq('user_id', _userId!)
          .eq('book', book)
          .eq('chapter', chapter);
      return (response as List).map((e) => Highlight.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching highlights: $e');
      return [];
    }
  }

  Future<List<Highlight>> getAllHighlights() async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('highlights')
          .select()
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(500);
      return (response as List).map((e) => Highlight.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching all highlights: $e');
      return [];
    }
  }

  Future<void> saveHighlight(Highlight highlight) async {
    try {
      if (_userId == null) return;
      await _client.from('highlights').upsert({
        ...highlight.toJson(),
        'user_id': _userId,
      }, onConflict: 'user_id, book, chapter, verse');
    } catch (e) {
      debugPrint('Error saving highlight: $e');
    }
  }

  Future<void> removeHighlight(String book, int chapter, int verse) async {
    try {
      if (_userId == null) return;
      await _client
          .from('highlights')
          .delete()
          .eq('user_id', _userId!)
          .eq('book', book)
          .eq('chapter', chapter)
          .eq('verse', verse);
    } catch (e) {
      debugPrint('Error deleting highlight: $e');
    }
  }

  // ===========================================================================
  // NOTES
  // ===========================================================================

  Future<List<UserNote>> getNotes(String book, int chapter) async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', _userId!)
          .eq('book', book)
          .eq('chapter', chapter);
      return (response as List).map((e) => UserNote.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching notes: $e');
      return [];
    }
  }

  Future<List<UserNote>> getAllNotes() async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', _userId!)
          .order('updated_at', ascending: false)
          .limit(200);
      return (response as List).map((e) => UserNote.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching all notes: $e');
      return [];
    }
  }

  Future<void> saveNote(UserNote note) async {
    try {
      if (_userId == null) return;
      await _client.from('notes').upsert({
        ...note.toJson(),
        'user_id': _userId,
      }, onConflict: 'user_id, book, chapter, verse');
    } catch (e) {
      debugPrint('Error saving note: $e');
    }
  }

  Future<void> deleteNote(String book, int chapter, int verse) async {
    try {
      if (_userId == null) return;
      await _client
          .from('notes')
          .delete()
          .eq('user_id', _userId!)
          .eq('book', book)
          .eq('chapter', chapter)
          .eq('verse', verse);
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }

  // ===========================================================================
  // CHAT CONVERSATIONS (schema normalizado: chat_conversations + chat_messages)
  // ===========================================================================

  /// Lista as conversas do utilizador (só metadados, para a lista ser leve).
  Future<List<ChatConversation>> getConversations({int limit = 50}) async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('chat_conversations')
          .select('id, title, updated_at')
          .eq('user_id', _userId!)
          .order('updated_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  /// Carrega uma conversa completa (metadados + mensagens, por ordem cronológica).
  Future<ChatConversation?> getConversation(String id) async {
    try {
      if (_userId == null) return null;
      final meta = await _client
          .from('chat_conversations')
          .select()
          .eq('id', id)
          .eq('user_id', _userId!)
          .maybeSingle();
      if (meta == null) return null;

      final rows = await _client
          .from('chat_messages')
          .select('role, content')
          .eq('conversation_id', id)
          .order('created_at', ascending: true);
      final messages = (rows as List)
          .map((e) => ChatTurn.fromJson(e as Map<String, dynamic>))
          .toList();

      return ChatConversation.fromJson(meta, messages: messages);
    } catch (e) {
      debugPrint('Error fetching conversation: $e');
      return null;
    }
  }

  /// Cria uma conversa nova e devolve o id gerado.
  Future<String?> createConversation(String title) async {
    try {
      if (_userId == null) return null;
      final response = await _client
          .from('chat_conversations')
          .insert({'user_id': _userId, 'title': title})
          .select('id')
          .single();
      return response['id'] as String?;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Actualiza o título e o updated_at de uma conversa existente.
  Future<void> touchConversation(String id, String title) async {
    try {
      if (_userId == null) return;
      await _client
          .from('chat_conversations')
          .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _userId!);
    } catch (e) {
      debugPrint('Error updating conversation: $e');
    }
  }

  /// Insere novas mensagens numa conversa (append incremental).
  Future<void> appendMessages(String conversationId, List<ChatTurn> turns) async {
    if (turns.isEmpty) return;
    try {
      await _client
          .from('chat_messages')
          .insert(turns.map((t) => t.toInsert(conversationId)).toList());
    } catch (e) {
      debugPrint('Error appending messages: $e');
    }
  }

  /// Substitui todas as mensagens de uma conversa (usado após edições).
  Future<void> replaceMessages(String conversationId, List<ChatTurn> turns) async {
    try {
      await _client.from('chat_messages').delete().eq('conversation_id', conversationId);
      await appendMessages(conversationId, turns);
    } catch (e) {
      debugPrint('Error replacing messages: $e');
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      if (_userId == null) return;
      // As mensagens são removidas em cascata (FK on delete cascade).
      await _client
          .from('chat_conversations')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId!);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  /// Busca o perfil do utilizador autenticado.
  Future<UserProfile?> getProfile() async {
    try {
      if (_userId == null) return null;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', _userId!)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  /// Atualiza o nome e/ou avatar do perfil. Devolve true se bem-sucedido.
  Future<bool> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      if (_userId == null) return false;
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) data['full_name'] = fullName;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      await _client.from('profiles').update(data).eq('id', _userId!);
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // ===========================================================================
  // ACCOUNT DELETION
  // ===========================================================================

  /// Apaga todos os dados e o registo de autenticação via RPC SECURITY DEFINER.
  Future<bool> deleteAccount() async {
    try {
      if (_userId == null) return false;
      await _client.rpc('delete_my_account');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  // ===========================================================================
  // READING PROGRESS
  // ===========================================================================

  /// Busca o progresso de leitura do utilizador.
  Future<ReadingProgress?> getReadingProgress() async {
    try {
      if (_userId == null) return null;
      final response = await _client
          .from('reading_progress')
          .select()
          .eq('user_id', _userId!)
          .maybeSingle();
      if (response == null) return null;
      return ReadingProgress.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching reading progress: $e');
      return null;
    }
  }

  /// Atualiza a posição de leitura e calcula o streak.
  Future<void> updateReadingProgress(String book, int chapter, int verse) async {
    try {
      if (_userId == null) return;

      // Buscar progresso atual para calcular streak
      final current = await getReadingProgress();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      int newStreak = 1;
      if (current != null && current.lastReadDate != null) {
        final lastDate = DateTime(
          current.lastReadDate!.year,
          current.lastReadDate!.month,
          current.lastReadDate!.day,
        );
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 0) {
          // Mesmo dia — mantém streak
          newStreak = current.currentStreak;
        } else if (diff == 1) {
          // Dia seguinte — incrementa streak
          newStreak = current.currentStreak + 1;
        }
        // diff > 1 → streak resetado para 1
      }

      await _client.from('reading_progress').upsert({
        'user_id': _userId,
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'current_streak': newStreak,
        'last_read_date': todayDate.toIso8601String().substring(0, 10),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error updating reading progress: $e');
    }
  }

  // ===========================================================================
  // DAILY VERSE
  // ===========================================================================

  /// Busca o versículo do dia baseado no dia do ano.
  Future<DailyVerse?> getDailyVerse() async {
    try {
      final dayOfYear = _dayOfYear(DateTime.now());
      final response = await _client
          .from('daily_verses')
          .select()
          .eq('day_of_year', dayOfYear)
          .maybeSingle();
      if (response == null) {
        // Fallback: buscar dia 1 se o dia atual não existir
        final fallback = await _client
            .from('daily_verses')
            .select()
            .eq('day_of_year', 1)
            .maybeSingle();
        if (fallback == null) return null;
        return DailyVerse.fromJson(fallback);
      }
      return DailyVerse.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching daily verse: $e');
      return null;
    }
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  // ===========================================================================
  // DEVOTIONALS
  // ===========================================================================

  /// Busca o devocional de hoje.
  Future<Devotional?> getTodayDevotional() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _client
          .from('devotionals')
          .select()
          .eq('publish_date', today)
          .maybeSingle();
      if (response == null) {
        // Fallback: buscar o mais recente
        final fallback = await _client
            .from('devotionals')
            .select()
            .order('publish_date', ascending: false)
            .limit(1)
            .maybeSingle();
        if (fallback == null) return null;
        return Devotional.fromJson(fallback);
      }
      return Devotional.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching devotional: $e');
      return null;
    }
  }

  // ===========================================================================
  // READING PLANS
  // ===========================================================================

  /// Busca todos os planos de leitura disponíveis.
  Future<List<ReadingPlan>> getReadingPlans() async {
    try {
      final response = await _client
          .from('reading_plans')
          .select()
          .order('created_at');
      return (response as List).map((e) => ReadingPlan.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching reading plans: $e');
      return [];
    }
  }

  /// Busca os planos do utilizador com join nos dados do plano.
  Future<List<UserReadingPlan>> getUserPlans() async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('user_reading_plans')
          .select('*, reading_plans(*)')
          .eq('user_id', _userId!)
          .order('started_at', ascending: false);
      return (response as List).map((e) => UserReadingPlan.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching user plans: $e');
      return [];
    }
  }

  /// Inscreve o utilizador num plano.
  Future<void> enrollInPlan(String planId) async {
    try {
      if (_userId == null) return;
      await _client.from('user_reading_plans').upsert({
        'user_id': _userId,
        'plan_id': planId,
        'current_day': 0,
        'started_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, plan_id');
    } catch (e) {
      debugPrint('Error enrolling in plan: $e');
    }
  }

  /// Atualiza o progresso de um plano do utilizador.
  Future<void> updatePlanProgress(String userPlanId, int newDay, {bool completed = false}) async {
    try {
      final data = <String, dynamic>{'current_day': newDay};
      if (completed) {
        data['completed_at'] = DateTime.now().toIso8601String();
      }
      await _client.from('user_reading_plans').update(data).eq('id', userPlanId);
    } catch (e) {
      debugPrint('Error updating plan progress: $e');
    }
  }

  /// Remove a inscrição do utilizador num plano.
  Future<void> leavePlan(String userPlanId) async {
    try {
      await _client.from('user_reading_plans').delete().eq('id', userPlanId);
    } catch (e) {
      debugPrint('Error leaving plan: $e');
    }
  }

  // ===========================================================================
  // STATS (Aggregated queries for Profile)
  // ===========================================================================

  /// Conta os destaques do utilizador.
  Future<int> countHighlights() async {
    try {
      if (_userId == null) return 0;
      final response = await _client
          .from('highlights')
          .select('id')
          .eq('user_id', _userId!);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error counting highlights: $e');
      return 0;
    }
  }

  /// Conta as notas do utilizador.
  Future<int> countNotes() async {
    try {
      if (_userId == null) return 0;
      final response = await _client
          .from('notes')
          .select('id')
          .eq('user_id', _userId!);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error counting notes: $e');
      return 0;
    }
  }

  // ===========================================================================
  // SAVED DEVOTIONALS
  // ===========================================================================

  /// Verifica se um devocional está salvo.
  Future<bool> isDevotionalSaved(String devotionalId) async {
    try {
      if (_userId == null) return false;
      final response = await _client
          .from('saved_devotionals')
          .select('id')
          .eq('user_id', _userId!)
          .eq('devotional_id', devotionalId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking saved devotional: $e');
      return false;
    }
  }

  /// Salva um devocional.
  Future<void> saveDevotional(String devotionalId) async {
    try {
      if (_userId == null) return;
      await _client.from('saved_devotionals').upsert({
        'user_id': _userId,
        'devotional_id': devotionalId,
      }, onConflict: 'user_id, devotional_id');
    } catch (e) {
      debugPrint('Error saving devotional: $e');
    }
  }

  /// Remove um devocional salvo.
  Future<void> unsaveDevotional(String devotionalId) async {
    try {
      if (_userId == null) return;
      await _client
          .from('saved_devotionals')
          .delete()
          .eq('user_id', _userId!)
          .eq('devotional_id', devotionalId);
    } catch (e) {
      debugPrint('Error unsaving devotional: $e');
    }
  }

  /// Busca todos os devocionais salvos com os dados completos.
  Future<List<Devotional>> getSavedDevotionals() async {
    try {
      if (_userId == null) return [];
      final response = await _client
          .from('saved_devotionals')
          .select('devotional_id, devotionals(*)')
          .eq('user_id', _userId!)
          .order('saved_at', ascending: false);
      return (response as List)
          .where((e) => e['devotionals'] != null)
          .map((e) => Devotional.fromJson(e['devotionals']))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved devotionals: $e');
      return [];
    }
  }
}
