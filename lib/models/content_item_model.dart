import 'package:cloud_firestore/cloud_firestore.dart';

// Перечисление для всех возможных типов контента
enum ContentType { lesson, test, material, unknown }

class ContentItem {
  final String id;
  final String title;
  final Timestamp createdAt;
  final ContentType type;

  // Поля, специфичные для видеоурока
  final String? duration;
  final String? videoUrl;
  final String? content;

  // Другие поля для тестов или материалов можно добавить здесь
  // final int? questionCount;
  // final String? fileUrl;

  ContentItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.type,
    this.duration,
    this.videoUrl,
    this.content,
  });

  factory ContentItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Определяем тип контента по полю 'type' из базы данных
    ContentType type = ContentType.unknown;
    switch (data['type']) {
      case 'lesson':
        type = ContentType.lesson;
        break;
      case 'test':
        type = ContentType.test;
        break;
      case 'material':
        type = ContentType.material;
        break;
    }
    
    return ContentItem(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      type: type,
      duration: data['duration'],
      videoUrl: data['videoUrl'],
      content: data['content'],
    );
  }
}
