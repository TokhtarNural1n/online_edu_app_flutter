// lib/models/course_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'module_model.dart';

class Course {
  final String id;
  final String title;
  final String category;
  final String author;
  final String price;
  final String originalPrice;
  final String imageUrl;
  final String thumbnailUrl;
  final String description;
  final double rating;
  final int reviewCount;
  final bool areLessonsSequential;
  final List<Module> modules;
  final int moduleCount;
  final int lessonCount;
  final int totalDurationMinutes; // <-- НЕДОСТАЮЩЕЕ ПОЛЕ

  Course({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.areLessonsSequential,
    required this.modules,
    this.moduleCount = 0, // <-- В КОНСТРУКТОР
    this.lessonCount = 0,
    required this.totalDurationMinutes, // <-- В КОНСТРУКТОР
  });

  factory Course.fromFirestore(DocumentSnapshot doc, List<Module> modules) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? 'Без названия',
      category: data['category'] ?? 'Басты',
      author: data['author'] ?? 'Неизвестен',
      price: data['price'] ?? '0 т',
      originalPrice: data['originalPrice'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? data['imageUrl'] ?? '',
      description: data['description'] ?? 'Описания нет.',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      areLessonsSequential: data['areLessonsSequential'] ?? false,
      modules: modules,
      moduleCount: data['moduleCount'] ?? 0, // <-- В ФАБРИЧНЫЙ МЕТОД
      lessonCount: data['lessonCount'] ?? 0,
      totalDurationMinutes: data['totalDurationMinutes'] ?? 0, // <-- В ФАБРИЧНЫЙ МЕТОД
    );
  }
}