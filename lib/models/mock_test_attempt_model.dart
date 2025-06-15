// lib/models/mock_test_attempt_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';


class MockTestAttempt {
  final String id;
  final String testId;
  final String testTitle;
  final int score;
  final int totalQuestions;
  final Timestamp completedAt;
  final Map<String, dynamic> userAnswers; 

  MockTestAttempt({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.userAnswers,
  });

  factory MockTestAttempt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MockTestAttempt(
      id: doc.id,
      testId: data['testId'] ?? '',
      testTitle: data['testTitle'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      userAnswers: data['userAnswers'] ?? {},
      completedAt: data['completedAt'] ?? Timestamp.now(),
      
    );
  }
}