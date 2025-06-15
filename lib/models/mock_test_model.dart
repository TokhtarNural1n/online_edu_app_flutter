// lib/models/mock_test_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MockTest {
  final String id;
  final String title;
  final String subject;
  final String language;
  final int questionCount;
  final int timeLimitMinutes; // <-- НОВОЕ ПОЛЕ
  final Timestamp createdAt;

  MockTest({
    required this.id,
    required this.title,
    required this.subject,
    required this.language,
    required this.questionCount,
    required this.timeLimitMinutes, // <-- В КОНСТРУКТОР
    required this.createdAt,
  });

  factory MockTest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MockTest(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      subject: data['subject'] ?? '',
      language: data['language'] ?? 'KK',
      questionCount: data['questionCount'] ?? 0,
      timeLimitMinutes: data['timeLimitMinutes'] ?? 60, // <-- В ФАБРИЧНЫЙ МЕТОД
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}