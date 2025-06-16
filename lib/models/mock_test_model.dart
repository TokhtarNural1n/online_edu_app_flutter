import 'package:cloud_firestore/cloud_firestore.dart';

// Перечисление для двух типов тестов
enum MockTestType { simple, ubt }

class MockTest {
  final String id;
  final String title;
  final MockTestType testType; // <-- НОВОЕ ПОЛЕ
  final String subject; // Используется для простых тестов
  final String language;
  final int questionCount;
  final int timeLimitMinutes;
  final Timestamp createdAt;

  MockTest({
    required this.id,
    required this.title,
    required this.testType,
    required this.subject,
    required this.language,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.createdAt,
  });

  factory MockTest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MockTest(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      // Определяем тип теста по полю в базе данных
      testType: (data['testType'] == 'ubt') ? MockTestType.ubt : MockTestType.simple,
      subject: data['subject'] ?? '',
      language: data['language'] ?? 'KK',
      questionCount: data['questionCount'] ?? 0,
      timeLimitMinutes: data['timeLimitMinutes'] ?? 60,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
