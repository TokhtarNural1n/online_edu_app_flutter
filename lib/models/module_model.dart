import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_model.dart';

class Module {
  final String id;
  final String title;
  final int lectureCount;
  final int fileCount;
  final int testCount;
  final Timestamp createdAt;
  final List<Lesson> lessons; // Модуль содержит список уроков

  Module({
    required this.id,
    required this.title,
    this.lectureCount = 0,
    this.fileCount = 0,
    this.testCount = 0,
    required this.createdAt,
    this.lessons = const [],
  });

  // Этот конструктор будет принимать готовый список уроков
  factory Module.fromFirestore(DocumentSnapshot doc, List<Lesson> lessons) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Module(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      lectureCount: data['lectureCount'] ?? 0,
      fileCount: data['fileCount'] ?? 0,
      testCount: data['testCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lessons: lessons,
    );
  }
}
