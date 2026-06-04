import 'dart:convert';

class Highlight {
  final String? id;
  final String book;
  final int chapter;
  final int verse;
  final int color; // ARGB value
  final String type; // 'block' or 'text'
  final DateTime? createdAt;

  Highlight({
    this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.color,
    required this.type,
    this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      color: json['color'],
      type: json['type'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'color': color,
      'type': type,
    };
  }
}

class UserNote {
  final String? id;
  final String book;
  final int chapter;
  final int verse;
  final String content; // JSON string from Quill
  final String? title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserNote({
    this.id,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.content,
    this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      id: json['id'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      content: json['content'],
      title: json['title'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'content': content,
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
  
  // Helper to extract plain text from Quill JSON for preview
  String get previewText {
    try {
      if (content.isEmpty) return '';
      final List<dynamic> json = jsonDecode(content);
      final buffer = StringBuffer();
      for (var op in json) {
        if (op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      return content; // Fallback
    }
  }
}

/// Uma mensagem de uma conversa do chat bíblico (linha em chat_messages).
class ChatTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;

  ChatTurn({required this.role, required this.content});

  factory ChatTurn.fromJson(Map<String, dynamic> json) =>
      ChatTurn(role: json['role'] as String? ?? 'user', content: json['content'] as String? ?? '');

  /// Payload para inserir em chat_messages (sem id/created_at, gerados na BD).
  Map<String, dynamic> toInsert(String conversationId) => {
        'conversation_id': conversationId,
        'role': role,
        'content': content,
      };
}

/// Uma conversa guardada do chat bíblico (linha em chat_conversations).
/// As mensagens vivem em chat_messages e são preenchidas ao carregar uma conversa.
class ChatConversation {
  final String id;
  final String? title;
  final List<ChatTurn> messages;
  final DateTime? updatedAt;

  ChatConversation({
    required this.id,
    this.title,
    this.messages = const [],
    this.updatedAt,
  });

  /// Constrói a partir da linha de metadados (sem mensagens).
  factory ChatConversation.fromJson(Map<String, dynamic> json, {List<ChatTurn> messages = const []}) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String?,
      messages: messages,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }
}
