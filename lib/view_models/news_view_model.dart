import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Метод для загрузки всех новостей
  Future<List<NewsArticle>> fetchAllNews() async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке новостей для пользователя: $e");
      return [];
    }
  }

  // --- НОВЫЙ МЕТОД ДЛЯ СЧЕТЧИКА ПРОСМОТРОВ ---
  // Этот метод не возвращает ничего, он просто отправляет команду в базу
  Future<void> incrementViewCount(String newsId) async {
    try {
      // FieldValue.increment(1) - это специальная атомарная операция Firebase.
      // Она безопасна, даже если 1000 человек откроют новость одновременно.
      await _firestore.collection('news').doc(newsId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print("Ошибка при увеличении счетчика просмотров: $e");
    }
  }
}
