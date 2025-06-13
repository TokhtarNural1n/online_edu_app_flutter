import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final Timestamp createdAt;
  final String category; // <-- Новое поле
  final int viewCount;   // <-- Новое поле

  NewsArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.category,
    required this.viewCount,
  });

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? 'Без заголовка',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      category: data['category'] ?? 'Без категории', // <-- Загрузка нового поля
      viewCount: data['viewCount'] ?? 0,             // <-- Загрузка нового поля
    );
  }
}
