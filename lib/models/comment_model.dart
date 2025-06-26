// lib/models/comment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String commentText;
  final Timestamp createdAt;
  int likeCount;
  final String? parentId; // <-- НОВОЕ ПОЛЕ ДЛЯ ОТВЕТОВ
  final String? parentUserName; // <-- Имя того, кому отвечают

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.commentText,
    required this.createdAt,
    this.likeCount = 0,
    this.parentId,         // <-- В КОНСТРУКТОР
    this.parentUserName,   // <-- В КОНСТРУКТОР
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Аноним',
      commentText: data['commentText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0,
      parentId: data['parentId'], // <-- В ФАБРИЧНЫЙ МЕТОД
      parentUserName: data['parentUserName'], // <-- В ФАБРИЧНЫЙ МЕТОД
    );
  }
}