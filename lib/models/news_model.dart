// lib/models/news_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final Timestamp createdAt;
  final String category;
  final int viewCount;
  final int commentCount; // <-- НОВОЕ ПОЛЕ
  final String thumbnailUrl; 

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.category,
    required this.viewCount,
    this.commentCount = 0, // <-- В КОНСТРУКТОР
    required this.thumbnailUrl,
  });

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? 'Без заголовка',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      category: data['category'] ?? 'Без категории',
      viewCount: data['viewCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0, // <-- В ФАБРИЧНЫЙ МЕТОД
      thumbnailUrl: data['thumbnailUrl'] ?? data['imageUrl'] ?? '',
    );
  }
}