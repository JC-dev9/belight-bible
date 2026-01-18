import 'dart:convert';
import 'package:flutter/material.dart';

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
