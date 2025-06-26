// lib/models/content_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { lesson, test, material, unknown }

class ContentItem {
  final String id;
  final String title;
  final Timestamp createdAt;
  final ContentType type;
  final bool isStopLesson;

  // Поля для урока
  final String? duration;
  final String? videoUrl;
  final String? content;
  final String? additionalInfoTitle;   // <-- НОВОЕ ПОЛЕ
  final String? additionalInfoContent; // <-- НОВОЕ ПОЛЕ

  // Поля для теста
  final int? questionCount;
  final int? timeLimitMinutes;
  final int? passingPercentage;

  // Поля для материалов
  final String? fileUrl;
  final String? fileName;
  final String? fileType;

  ContentItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.type,
    this.isStopLesson = false,
    this.duration,
    this.videoUrl,
    this.content,
    this.additionalInfoTitle,      // <-- В КОНСТРУКТОР
    this.additionalInfoContent,    // <-- В КОНСТРУКТОР
    this.questionCount,
    this.timeLimitMinutes,
    this.passingPercentage,
    this.fileUrl,
    this.fileName,
    this.fileType,
  });

  factory ContentItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    ContentType type;
    switch (data['type']) {
      case 'lesson': type = ContentType.lesson; break;
      case 'test': type = ContentType.test; break;
      case 'material': type = ContentType.material; break;
      default: type = ContentType.unknown; break;
    }

    return ContentItem(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      type: type,
      isStopLesson: data['isStopLesson'] ?? false,
      duration: data['duration'],
      videoUrl: data['videoUrl'],
      content: data['content'],
      additionalInfoTitle: data['additionalInfoTitle'], // <-- ИЗ FIRESTORE
      additionalInfoContent: data['additionalInfoContent'], // <-- ИЗ FIRESTORE
      questionCount: data['questionCount'],
      timeLimitMinutes: data['timeLimitMinutes'],
      passingPercentage: data['passingPercentage'],
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileType: data['fileType'],
    );
  }
}