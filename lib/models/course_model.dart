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
  final String description;
  final int totalDurationMinutes;
  final double rating;
  final int reviewCount;
  final List<Module> modules; // Теперь курс содержит список модулей

  Course({
    required this.id,
    required this.title,
    required this.category,
    required this.author,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.description,
    required this.totalDurationMinutes,
    required this.rating,
    required this.reviewCount,
    required this.modules,
  });

  // Обновляем конструктор: он будет принимать готовый список модулей
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
      description: data['description'] ?? 'Описания нет.',
      totalDurationMinutes: data['totalDurationMinutes'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      modules: modules,
    );
  }
}
