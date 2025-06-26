// lib/models/subject_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String imageUrl;
  final int courseCount;

  Subject({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.courseCount,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      courseCount: data['courseCount'] ?? 0,
    );
  }
}