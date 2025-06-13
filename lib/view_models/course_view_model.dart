import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/lesson_model.dart';

class CourseViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Метод для загрузки всех курсов (для каталога)
  // Мы его упрощаем, так как теперь полные данные грузятся на детальном экране
  Future<List<Course>> fetchCourses() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('courses').get();
      // Теперь мы загружаем только "обложку" курса, без модулей
      return snapshot.docs.map((doc) => Course.fromFirestore(doc, [])).toList();
    } catch (e) {
      print("Ошибка при загрузке курсов: $e");
      return [];
    }
  }

  // --- НОВЫЙ И САМЫЙ ВАЖНЫЙ МЕТОД ---
  // Загружает один курс со всеми его вложенными модулями и уроками
  Future<Course> fetchCourseDetails(String courseId) async {
    try {
      // 1. Загружаем основной документ курса
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();

      // 2. Загружаем под-коллекцию модулей
      final modulesSnapshot = await courseDoc.reference.collection('modules').orderBy('createdAt').get();

      List<Module> modules = [];
      // 3. Для каждого модуля загружаем его уроки
      for (var moduleDoc in modulesSnapshot.docs) {
        final lessonsSnapshot = await moduleDoc.reference.collection('lessons').orderBy('createdAt').get();
        final lessons = lessonsSnapshot.docs.map((lessonDoc) => Lesson.fromFirestore(lessonDoc)).toList();
        
        // Собираем объект модуля с его уроками
        modules.add(Module.fromFirestore(moduleDoc, lessons));
      }

      // 4. Собираем и возвращаем полный объект курса
      return Course.fromFirestore(courseDoc, modules);

    } catch (e) {
      print("Ошибка при загрузке деталей курса: $e");
      throw Exception('Не удалось загрузить данные курса.');
    }
  }

  // Метод для "Моих курсов" остается почти без изменений
  Future<List<Course>> fetchMyCourses({String? userId}) async {
    final targetUserId = userId ?? _auth.currentUser?.uid;
    if (targetUserId == null) return [];

    try {
      final enrolledSnapshot = await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('enrolled_courses')
          .get();
      
      if (enrolledSnapshot.docs.isEmpty) return [];
      final courseIds = enrolledSnapshot.docs.map((doc) => doc.id).toList();

      if (courseIds.isEmpty) return [];
      
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where(FieldPath.documentId, whereIn: courseIds)
          .get();

      // Мы также грузим только "обложки" для списка
      return coursesSnapshot.docs.map((doc) => Course.fromFirestore(doc, [])).toList();
    } catch (e) {
      print("Ошибка при загрузке 'Моих курсов': $e");
      return [];
    }
  }
}
