import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/content_item_model.dart';
import '../models/question_model.dart';
import '../models/my_course_progress_info.dart';
import '../models/mock_test_model.dart';
import '../models/mock_test_attempt_model.dart';
import '../models/ubt_subject_model.dart';




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
  Future<String?> activatePromoCode(String code) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) {
    return 'Для активации промокода необходимо войти в систему.';
  }
  if (code.isEmpty) {
    return 'Поле промокода не может быть пустым.';
  }

  final promoCodeRef = _firestore.collection('promo_codes').doc(code.trim().toUpperCase());

  try {
    // Выполняем все операции в транзакции, чтобы обеспечить целостность данных.
    // Это гарантирует, что никто другой не сможет использовать этот же код одновременно.
    return await _firestore.runTransaction((transaction) async {
      // 1. Получаем документ промокода
      final promoDoc = await transaction.get(promoCodeRef);

      // 2. Проверяем, существует ли код и не использован ли он
      if (!promoDoc.exists) {
        return 'Промокод не найден.';
      }
      if (promoDoc.data()?['isUsed'] == true) {
        return 'Этот промокод уже был использован.';
      }

      // 3. Получаем ID курса из промокода
      final courseId = promoDoc.data()?['courseId'];
      if (courseId == null) {
        return 'Ошибка: к этому промокоду не привязан курс.';
      }

      // 4. Проверяем, нет ли у пользователя уже доступа к этому курсу
      final enrollmentRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('enrolled_courses')
          .doc(courseId);
      final enrollmentDoc = await transaction.get(enrollmentRef);
      if (enrollmentDoc.exists) {
        return 'У вас уже есть доступ к этому курсу.';
      }

      // 5. Обновляем (сжигаем) промокод
      transaction.update(promoCodeRef, {
        'isUsed': true,
        'usedBy': userId,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // 6. Предоставляем пользователю доступ к курсу
      transaction.set(enrollmentRef, {
        'enrolledAt': FieldValue.serverTimestamp(),
        'activatedWithCode': code.trim().toUpperCase(),
      });

      // Возвращаем null, что означает успешное завершение
      return null;
    });
  } on FirebaseException catch (e) {
    return 'Произошла ошибка: ${e.message}';
  }
}
Future<List<MockTest>> fetchMockTests() async {
  try {
    final snapshot = await _firestore.collection('mock_tests').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => MockTest.fromFirestore(doc)).toList();
  } catch (e) {
    print("Ошибка при загрузке пробных тестов: $e");
    return [];
  }
}Future<List<Question>> fetchQuestionsForMockTest(String testId) async {
  try {
    final snapshot = await _firestore
        .collection('mock_tests')
        .doc(testId)
        .collection('questions')
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }

    return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
  } catch (e) {
    print("Ошибка при загрузке вопросов пробного теста: $e");
    return [];
  }
}
  Future<void> saveMockTestAttempt({ required String testId, required String testTitle, required int score, required int totalQuestions, required Map<String, Map<int, int>> userAnswers, }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final answersToSave = userAnswers.map((subjectId, answers) => MapEntry(subjectId, answers.map((key, value) => MapEntry(key.toString(), value))));
    try {
      await _firestore.collection('users').doc(userId).collection('mock_test_attempts').add({
        'testId': testId, 'testTitle': testTitle, 'score': score, 'totalQuestions': totalQuestions,
        'completedAt': Timestamp.now(), 'userAnswers': answersToSave,
      });
    } catch (e) { print("Ошибка при сохранении попытки теста: $e"); }
  }
  Future<Set<String>> fetchAttemptedMockTestIds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mock_test_attempts')
          .get();

      // Возвращаем набор уникальных ID тестов, которые пытался пройти пользователь
      return snapshot.docs.map((doc) => doc.data()['testId'] as String).toSet();
    } catch (e) {
      print("Ошибка при загрузке попыток тестов: $e");
      return {};
    }
  }
  Future<MockTestAttempt?> fetchLastMockTestAttempt(String testId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mock_test_attempts')
          .where('testId', isEqualTo: testId)
          .orderBy('completedAt', descending: true) // Сортируем, чтобы последняя была первой
          .limit(1) // Берем только одну, самую последнюю
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MockTestAttempt.fromFirestore(snapshot.docs.first);
      }
      return null; // Если попыток не найдено
    } catch (e) {
      print("Ошибка при загрузке последней попытки: $e");
      return null;
    }
  }
  Future<List<MockTestAttempt>> fetchAttemptsForMockTest(String testId) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return [];

  try {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mock_test_attempts')
        .where('testId', isEqualTo: testId) // Находим все попытки для этого теста
        .orderBy('completedAt', descending: true) // Сортируем от новых к старым
        .get();

    return snapshot.docs.map((doc) => MockTestAttempt.fromFirestore(doc)).toList();
  } catch (e) {
    print("Ошибка при загрузке истории попыток: $e");
    return [];
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
  Future<List<UbtSubject>> fetchSubjectsForUbtTest(String testId) async {
    try {
      final subjectsSnapshot = await _firestore
          .collection('mock_tests')
          .doc(testId)
          .collection('subjects')
          .get();
      
      // Преобразуем документы в объекты UbtSubject
      return subjectsSnapshot.docs.map((doc) => UbtSubject(
        id: doc.id,
        title: doc.data()['title'] ?? '',
        // Пока не загружаем сами вопросы
        questions: [], 
      )).toList();
    } catch (e) {
      print("Ошибка при загрузке предметов ҰБТ-теста: $e");
      return [];
    }
  }  
  Future<List<UbtSubject>> fetchUbtTestWithQuestions(String testId) async {
    try {
      final subjectsSnapshot = await _firestore.collection('mock_tests').doc(testId).collection('subjects').get();
      if (subjectsSnapshot.docs.isEmpty) return [];
      List<UbtSubject> subjectsWithQuestions = [];
      await Future.forEach(subjectsSnapshot.docs, (subjectDoc) async {
        final questionsSnapshot = await subjectDoc.reference.collection('questions').get();
        final questions = questionsSnapshot.docs.map((qDoc) => Question.fromFirestore(qDoc)).toList();
        subjectsWithQuestions.add(UbtSubject(id: subjectDoc.id, title: subjectDoc.data()['title'] ?? '', questions: questions));
      });
      return subjectsWithQuestions;
    } catch (e) { print("Ошибка при загрузке ҰБТ-теста с вопросами: $e"); return []; }
  }
    /// ВОТ НЕДОСТАЮЩИЙ МЕТОД
  Future<List<MockTestAttempt>> fetchAllMockTestAttempts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    try {
      final snapshot = await _firestore.collection('users').doc(userId).collection('mock_test_attempts').orderBy('completedAt', descending: true).get();
      return snapshot.docs.map((doc) => MockTestAttempt.fromFirestore(doc)).toList();
    } catch (e) { print("Ошибка при загрузке всех попыток: $e"); return []; }
  }
  

  Future<MockTest?> fetchMockTestById(String testId) async {
    try {
      final doc = await _firestore.collection('mock_tests').doc(testId).get();
      return doc.exists ? MockTest.fromFirestore(doc) : null;
    } catch (e) { return null; }
  }


  Future<List<MyCourseProgressInfo>> fetchMyCoursesWithProgress() async {
    final myCourses = await fetchMyCourses();
    if (myCourses.isEmpty) return [];

    List<MyCourseProgressInfo> progressInfoList = [];

    for (final course in myCourses) {
      final results = await Future.wait([
        fetchCourseDetails(course.id),
        fetchCompletedContentIds(course.id),
      ]);

      final detailedCourse = results[0] as Course;
      final completedIds = results[1] as Set<String>;

      final allContentItems = detailedCourse.modules
          .expand((module) => module.contentItems)
          .toList();

      // --- ИЗМЕНЕНИЕ: Создаем список только отслеживаемых элементов (лекции и тесты) ---
      final trackableItems = allContentItems
          .where((item) => item.type == ContentType.lesson || item.type == ContentType.test)
          .toList();

      double progressPercent = 0.0;
      if (trackableItems.isNotEmpty) {
        // Считаем пройденные только среди отслеживаемых
        final completedTrackableItems = trackableItems
            .where((item) => completedIds.contains(item.id))
            .length;
        progressPercent = (completedTrackableItems / trackableItems.length) * 100;
      }

      // Находим следующий урок для прохождения среди отслеживаемых
      ContentItem? nextItem;
      int nextItemAbsoluteIndex = 0;
      for (int i = 0; i < trackableItems.length; i++) {
        if (!completedIds.contains(trackableItems[i].id)) {
          nextItem = trackableItems[i];
          nextItemAbsoluteIndex = i + 1; // Порядковый номер среди лекций/тестов
          break;
        }
      }

      progressInfoList.add(MyCourseProgressInfo(
        course: detailedCourse,
        progressPercent: progressPercent,
        lessonNumberToContinue: nextItemAbsoluteIndex > 0 ? nextItemAbsoluteIndex : trackableItems.length,
        nextContentItem: nextItem,
      ));
    }

    return progressInfoList;
  }
} 