// lib/models/lesson_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'content_item_model.dart';

class Lesson {
  final String id;
  final String title;
  final String duration;
  final String videoUrl;
  final String content;
  final Timestamp createdAt;
  
  // --- НОВЫЕ ПОЛЯ ---
  final String? additionalInfoTitle;
  final String? additionalInfoContent;

  Lesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.content,
    required this.createdAt,
    this.additionalInfoTitle,   // <-- В КОНСТРУКТОР
    this.additionalInfoContent, // <-- В КОНСТРУКТОР
  });

  // --- ОБНОВЛЕННЫЙ ФАБРИЧНЫЙ КОНСТРУКТОР ---
  factory Lesson.fromContentItem(ContentItem item) {
    return Lesson(
      id: item.id,
      title: item.title,
      duration: item.duration ?? '',
      videoUrl: item.videoUrl ?? '',
      content: item.content ?? '',
      createdAt: item.createdAt,
      additionalInfoTitle: item.additionalInfoTitle, // <-- Передаем новые данные
      additionalInfoContent: item.additionalInfoContent, // <-- Передаем новые данные
    );
  }
  
  // Этот метод можно оставить без изменений, он используется в других местах
  factory Lesson.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Lesson(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      duration: data['duration'] ?? '00:00',
      videoUrl: data['videoUrl'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      additionalInfoTitle: data['additionalInfoTitle'],
      additionalInfoContent: data['additionalInfoContent'],
    );
  }
}