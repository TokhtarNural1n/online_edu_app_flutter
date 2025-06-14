import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/content_item_model.dart';
import '../models/question_model.dart';
import '../models/my_course_progress_info.dart';
import '../models/content_item_model.dart';

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
      // 3. Для каждого модуля загружаем его контент
      for (var moduleDoc in modulesSnapshot.docs) {
        // ЗАПРАШИВАЕМ ИЗ ПРАВИЛЬНОЙ КОЛЛЕКЦИИ 'contentItems'
        final contentSnapshot = await moduleDoc.reference.collection('contentItems').orderBy('createdAt').get();
        final contentItems = contentSnapshot.docs.map((contentDoc) => ContentItem.fromFirestore(contentDoc)).toList();
        
        // Собираем объект модуля с его контентом
        modules.add(Module.fromFirestore(moduleDoc, contentItems));
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
  Future<List<Question>> fetchTestQuestions({
    required String courseId,
    required String moduleId,
    required String testId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('courses').doc(courseId)
          .collection('modules').doc(moduleId)
          .collection('contentItems').doc(testId)
          .collection('questions')
          .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

    } catch (e) {
      print("Ошибка при загрузке вопросов теста: $e");
      return [];
    }
  }
  Future<void> markContentAsCompleted(String courseId, String contentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress') // Создаем новую подколлекцию для прогресса
          .doc(courseId)
          .collection('completed_items')
          .doc(contentId)
          .set({'completedAt': Timestamp.now()});
    } catch (e) {
      print("Ошибка при сохранении прогресса: $e");
    }
  }

  /// Загружает ID всех пройденных элементов в курсе
  Future<Set<String>> fetchCompletedContentIds(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .doc(courseId)
          .collection('completed_items')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print("Ошибка при загрузке прогресса: $e");
      return {};
    }
  }
  Future<List<MyCourseProgressInfo>> fetchMyCoursesWithProgress() async {
  // 1. Сначала получаем базовый список курсов пользователя
  final myCourses = await fetchMyCourses();
  if (myCourses.isEmpty) return [];

  List<MyCourseProgressInfo> progressInfoList = [];

  // 2. В цикле для каждого курса получаем детали и считаем прогресс
  for (final course in myCourses) {
    // Параллельно загружаем полную структуру курса и ID пройденных уроков
    final results = await Future.wait([
      fetchCourseDetails(course.id),
      fetchCompletedContentIds(course.id),
    ]);

    final detailedCourse = results[0] as Course;
    final completedIds = results[1] as Set<String>;

    // 3. Собираем все уроки и тесты курса в один список
    final allContentItems = detailedCourse.modules
        .expand((module) => module.contentItems)
        .toList();

    // Если в курсе нет контента, показываем прогресс 0%
    if (allContentItems.isEmpty) {
      progressInfoList.add(MyCourseProgressInfo(
        course: detailedCourse,
        progressPercent: 0,
        lessonNumberToContinue: 1,
        nextContentItem: null,
      ));
      continue; // Переходим к следующему курсу в цикле
    }

    // 4. Считаем процент прогресса
    final double progressPercent = (completedIds.length / allContentItems.length) * 100;

    // 5. Находим следующий урок для прохождения
    ContentItem? nextItem;
    int nextItemAbsoluteIndex = 0;
    for (int i = 0; i < allContentItems.length; i++) {
      if (!completedIds.contains(allContentItems[i].id)) {
        nextItem = allContentItems[i];
        nextItemAbsoluteIndex = i + 1; // Порядковый номер (напр. "7-й урок")
        break;
      }
    }

    // 6. Собираем всю информацию в один объект и добавляем в финальный список
    progressInfoList.add(MyCourseProgressInfo(
      course: detailedCourse,
      progressPercent: progressPercent,
      lessonNumberToContinue: nextItemAbsoluteIndex > 0 ? nextItemAbsoluteIndex : allContentItems.length,
      nextContentItem: nextItem,
    ));
  }

  return progressInfoList;
}
}
