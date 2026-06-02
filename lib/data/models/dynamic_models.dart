// Modelos para dados dinâmicos do Supabase.
// Cada classe corresponde a uma tabela no banco de dados.

/// Perfil do utilizador — tabela `profiles`
class UserProfile {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// Progresso de leitura — tabela `reading_progress`
class ReadingProgress {
  final String? id;
  final String userId;
  final String book;
  final int chapter;
  final int verse;
  final int currentStreak;
  final DateTime? lastReadDate;

  ReadingProgress({
    this.id,
    required this.userId,
    this.book = 'Gênesis',
    this.chapter = 1,
    this.verse = 1,
    this.currentStreak = 0,
    this.lastReadDate,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      id: json['id'],
      userId: json['user_id'],
      book: json['book'] ?? 'Gênesis',
      chapter: json['chapter'] ?? 1,
      verse: json['verse'] ?? 1,
      currentStreak: json['current_streak'] ?? 0,
      lastReadDate: json['last_read_date'] != null 
          ? DateTime.parse(json['last_read_date']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'book': book,
    'chapter': chapter,
    'verse': verse,
    'current_streak': currentStreak,
    'last_read_date': lastReadDate?.toIso8601String().substring(0, 10),
    'updated_at': DateTime.now().toIso8601String(),
  };
}

/// Versículo do dia — tabela `daily_verses`
class DailyVerse {
  final int id;
  final int dayOfYear;
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String reference;

  DailyVerse({
    required this.id,
    required this.dayOfYear,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.reference,
  });

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    return DailyVerse(
      id: json['id'],
      dayOfYear: json['day_of_year'],
      book: json['book'],
      chapter: json['chapter'],
      verse: json['verse'],
      text: json['text'],
      reference: json['reference'],
    );
  }
}

/// Devocional diário — tabela `devotionals`
class Devotional {
  final String id;
  final DateTime publishDate;
  final String title;
  final String content;
  final int readingTimeMin;

  Devotional({
    required this.id,
    required this.publishDate,
    required this.title,
    required this.content,
    this.readingTimeMin = 3,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'],
      publishDate: DateTime.parse(json['publish_date']),
      title: json['title'],
      content: json['content'],
      readingTimeMin: json['reading_time_min'] ?? 3,
    );
  }
}

/// Plano de leitura (template) — tabela `reading_plans`
class ReadingPlan {
  final String id;
  final String title;
  final String description;
  final int totalDays;
  final String color;
  final String icon;
  final String? goal;
  final List<Map<String, dynamic>> passages;

  ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.totalDays,
    this.color = '#2196F3',
    this.icon = 'calendar_today',
    this.goal,
    this.passages = const [],
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsedPassages = [];
    if (json['passages'] != null && json['passages'] is List) {
      parsedPassages = List<Map<String, dynamic>>.from(
        (json['passages'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }

    return ReadingPlan(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      totalDays: json['total_days'],
      color: json['color'] ?? '#2196F3',
      icon: json['icon'] ?? 'calendar_today',
      goal: json['goal'],
      passages: parsedPassages,
    );
  }

  /// Retorna a passagem para um dia específico
  String? getPassageForDay(int day) {
    final entry = passages.firstWhere(
      (p) => p['day'] == day,
      orElse: () => {},
    );
    return entry.isNotEmpty ? entry['passage'] as String? : null;
  }
}

/// Plano de leitura do utilizador — tabela `user_reading_plans`
class UserReadingPlan {
  final String id;
  final String userId;
  final String planId;
  final int currentDay;
  final DateTime startedAt;
  final DateTime? completedAt;

  // Dados do plano (join)
  final ReadingPlan? plan;

  UserReadingPlan({
    required this.id,
    required this.userId,
    required this.planId,
    this.currentDay = 0,
    required this.startedAt,
    this.completedAt,
    this.plan,
  });

  factory UserReadingPlan.fromJson(Map<String, dynamic> json) {
    return UserReadingPlan(
      id: json['id'],
      userId: json['user_id'],
      planId: json['plan_id'],
      currentDay: json['current_day'] ?? 0,
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      plan: json['reading_plans'] != null 
          ? ReadingPlan.fromJson(json['reading_plans']) 
          : null,
    );
  }

  /// Retorna progresso como fração 0.0 a 1.0
  double get progress {
    if (plan == null || plan!.totalDays == 0) return 0;
    return (currentDay / plan!.totalDays).clamp(0.0, 1.0);
  }
}
