// lib/models/content_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { lesson, test, material, unknown }

class ContentItem {
  final String id;
  final String title;
  final Timestamp createdAt;
  final ContentType type;

  // Поля для урока
  final String? duration;
  final String? videoUrl;
  final String? content;

  // Новые поля для теста
  final int? questionCount;
  final int? timeLimitMinutes;
  final int? passingPercentage;

  ContentItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.type,
    this.duration,
    this.videoUrl,
    this.content,
    this.questionCount,
    this.timeLimitMinutes,
    this.passingPercentage,
  });

  factory ContentItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    ContentType type = ContentType.unknown;
    switch (data['type']) {
      case 'lesson': type = ContentType.lesson; break;
      case 'test': type = ContentType.test; break;
      case 'material': type = ContentType.material; break;
    }

    return ContentItem(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      type: type,
      duration: data['duration'],
      videoUrl: data['videoUrl'],
      content: data['content'],
      questionCount: data['questionCount'],
      timeLimitMinutes: data['timeLimitMinutes'],
      passingPercentage: data['passingPercentage'],
    );
  }
}