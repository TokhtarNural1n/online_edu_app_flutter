import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/news_model.dart';
import '../models/module_model.dart'; 
import '../models/content_item_model.dart';
import '../models/question_model.dart'; 
import 'dart:math';
import '../models/promo_code_model.dart';
import '../models/enrollment_model.dart';
import '../models/enrollment_detail_model.dart';
import '../models/course_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../models/mock_test_model.dart';
import '../models/ubt_subject_model.dart';
import 'package:image/image.dart' as img;
import '../models/subject_model.dart';



class AdminViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Методы для пользователей (без изменений) ---
  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке пользователей: $e");
      return [];
    }
  }

  Future<String?> grantCourseAccess({required String userId, required String courseId}) async {
    try {
      await _firestore
          .collection('users').doc(userId)
          .collection('enrolled_courses').doc(courseId)
          .set({
            // ИЗМЕНЕНИЕ: Используем серверное время вместо времени устройства
            'enrolledAt': FieldValue.serverTimestamp(), 
            'grantMethod': 'admin'
          });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> revokeCourseAccess({required String userId, required String courseId}) async {
    try {
      await _firestore.collection('users').doc(userId).collection('enrolled_courses').doc(courseId).delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<String?> generatePromoCodes({
    required String courseId,
    required String courseTitle,
    required int count,
  }) async {
    if (count <= 0) {
      return 'Количество кодов должно быть больше нуля.';
    }
    try {
      // Используем пакетную запись для эффективности
      final batch = _firestore.batch();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = Random();

      for (int i = 0; i < count; i++) {
        // Генерируем случайный 8-значный код
        final promoCode = String.fromCharCodes(Iterable.generate(
            8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

        // Готовим документ для добавления в базу
        final docRef = _firestore.collection('promo_codes').doc(promoCode);
        batch.set(docRef, {
          'courseId': courseId,
          'courseTitle': courseTitle,
          'createdAt': Timestamp.now(),
          'isUsed': false,
          'usedBy': null,
          'usedAt': null,
        });
      }

      // Отправляем все сгенерированные коды в базу одной операцией
      await batch.commit();
      return null; // Успех
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<List<PromoCode>> fetchPromoCodesForCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('promo_codes')
          .where('courseId', isEqualTo: courseId)
          .where('isUsed', isEqualTo: false) // Показываем только активные коды
          .get();
      return snapshot.docs.map((doc) => PromoCode.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке промокодов: $e");
      return [];
    }
  }

  Future<List<EnrollmentDetail>> fetchUserEnrollments(String userId) async {
  try {
    // 1. Получаем все документы о зачислении
    final enrolledSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('enrolled_courses')
        .get();

    if (enrolledSnapshot.docs.isEmpty) return [];

    List<Enrollment> enrollments = enrolledSnapshot.docs
        .map((doc) => Enrollment.fromFirestore(doc))
        .toList();

    // 2. Получаем ID всех курсов
    final courseIds = enrollments.map((e) => e.courseId).toList();
    if (courseIds.isEmpty) return [];

    // 3. Загружаем данные самих курсов
    final coursesSnapshot = await _firestore
        .collection('courses')
        .where(FieldPath.documentId, whereIn: courseIds)
        .get();

    final coursesMap = {for (var doc in coursesSnapshot.docs) doc.id: Course.fromFirestore(doc, [])};

    // 4. Объединяем данные о курсе и о зачислении
    List<EnrollmentDetail> enrollmentDetails = [];
    for (var enrollment in enrollments) {
      if (coursesMap.containsKey(enrollment.courseId)) {
        enrollmentDetails.add(EnrollmentDetail(
          course: coursesMap[enrollment.courseId]!,
          enrollment: enrollment,
        ));
      }
    }
    return enrollmentDetails;
  } catch (e) {
    print("Ошибка при загрузке зачислений: $e");
    return [];
  }
}

  // --- Методы для новостей ---
  Future<List<NewsArticle>> fetchNews() async {
    try {
      final snapshot = await _firestore.collection('news').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке новостей: $e");
      return [];
    }
  }

  Future<String?> addNewsArticle({
    required String title,
    required String content,
    required String imageUrl,
    required String thumbnailUrl,
  }) async {
    if (title.isEmpty || content.isEmpty) return 'Заголовок и содержание не могут быть пустыми.';
    try {
      await _firestore.collection('news').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': Timestamp.now(),
        'category': 'Жаңалықтар', // или любая другая категория по умолчанию
        'viewCount': 0,
        'commentCount': 0, // Инициализируем счетчик комментариев
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  /// Обновляет новость, включая возможность смены изображения.
  Future<String?> updateNewsArticle({
    required String newsId,
    required String title,
    required String content,
    String? newImageUrl, // Ссылки передаются уже готовыми
    String? newThumbnailUrl,
    String? oldImageUrl,
  }) async {
    if (title.isEmpty || content.isEmpty) return 'Поля не могут быть пустыми.';
    try {
      final Map<String, dynamic> updateData = {
        'title': title,
        'content': content,
      };

      // Если были переданы новые ссылки, добавляем их в данные для обновления
      if (newImageUrl != null && newThumbnailUrl != null) {
        updateData['imageUrl'] = newImageUrl;
        updateData['thumbnailUrl'] = newThumbnailUrl;

        // Удаляем старые фото, если они были
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          // Пытаемся удалить и оригинал, и thumbnail
          await deleteNewsImage(oldImageUrl);
          final oldThumbUrl = oldImageUrl.replaceFirst('/original/', '/thumb/');
          await deleteNewsImage(oldThumbUrl);
        }
      }

      await _firestore.collection('news').doc(newsId).update(updateData);
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  /// Вспомогательный метод для удаления одного изображения из Storage.
  Future<void> deleteNewsImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      print("Ошибка при удалении старого фото (можно игнорировать): $e");
    }
  }

  /// Удаляет всю новость (документ + оба изображения).
  Future<String?> deleteNewsArticle({required String newsId, required String imageUrl}) async {
    try {
      // Удаляем и оригинал, и thumbnail
      await deleteNewsImage(imageUrl);
      final thumbUrl = imageUrl.replaceFirst('/original/', '/thumb/');
      await deleteNewsImage(thumbUrl);
      
      // Затем удаляем документ из Firestore
      await _firestore.collection('news').doc(newsId).delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<String?> addCourse({
    required String title,
    required String author,
    required String category,
    required String description,
    required String price,
    required String originalPrice,
    required bool areLessonsSequential,
    String? imageUrl,
    String? thumbnailUrl,
  }) async {
    try {
      await _firestore.collection('courses').add({
        'title': title, 'author': author, 'category': category,
        'description': description, 'price': price, 'originalPrice': originalPrice,
        'imageUrl': imageUrl ?? '', 'thumbnailUrl': thumbnailUrl ?? '',
        'areLessonsSequential': areLessonsSequential,
        'createdAt': Timestamp.now(), 'reviewCount': 0, 'rating': 0.0,
      });
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }

  // Метод для обновления курса
  Future<String?> updateCourse({
    required String courseId,
    required String title,
    required String author,
    required String category,
    required String description,
    required String price,
    required String originalPrice,
    required bool areLessonsSequential,
    String? newImageUrl,
    String? newThumbnailUrl,
    String? oldImageUrl,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'title': title, 'author': author, 'category': category,
        'description': description, 'price': price, 'originalPrice': originalPrice,
        'areLessonsSequential': areLessonsSequential,
      };

      if (newImageUrl != null && newThumbnailUrl != null) {
        updateData['imageUrl'] = newImageUrl;
        updateData['thumbnailUrl'] = newThumbnailUrl;
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          final oldThumbUrl = oldImageUrl.replaceFirst('/original/', '/thumb/');
          try { await _storage.refFromURL(oldImageUrl).delete(); } catch (e) {}
          try { await _storage.refFromURL(oldThumbUrl).delete(); } catch (e) {}
        }
      }
      await _firestore.collection('courses').doc(courseId).update(updateData);
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }


  // Метод для удаления курса
  Future<String?> deleteCourse({required String courseId, required String imageUrl}) async {
    try {
      if (imageUrl.isNotEmpty && !imageUrl.contains('placehold.co')) {
        await _storage.refFromURL(imageUrl).delete();
      }
      await _firestore.collection('courses').doc(courseId).delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<List<Module>> fetchModules(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .orderBy('createdAt') // Сортируем по названию
          .get();
      // Загружаем модули без уроков, так как на этом экране они не нужны
      return snapshot.docs.map((doc) => Module.fromFirestore(doc, [])).toList();
    } catch (e) {
      print("Ошибка при загрузке модулей: $e");
      return [];
    }
  }

  // Добавление нового модуля к курсу
  Future<String?> addModule({
    required String courseId,
    required String title,
  }) async {
    if (title.isEmpty) return 'Название модуля не может быть пустым.';
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .add({'title': title, 'lectureCount': 0, 'fileCount': 0, 'testCount': 0, 'createdAt': Timestamp.now(),});
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  // Обновление названия модуля
  Future<String?> updateModule({
    required String courseId,
    required String moduleId,
    required String newTitle,
  }) async {
    if (newTitle.isEmpty) return 'Название модуля не может быть пустым.';
    try {
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .update({'title': newTitle});
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  // Удаление модуля
  Future<String?> deleteModule({
    required String courseId,
    required String moduleId,
  }) async {
    try {
      // В реальном приложении здесь также нужно будет удалить все вложенные уроки
      await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('modules')
          .doc(moduleId)
          .delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

 Future<List<ContentItem>> fetchContentItems(String courseId, String moduleId) async {
    try {
      final snapshot = await _firestore
          .collection('courses').doc(courseId)
          .collection('modules').doc(moduleId)
          .collection('contentItems').orderBy('createdAt').get(); 
      return snapshot.docs.map((doc) => ContentItem.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке контента: $e");
      return [];
    }
  }
  Future<String?> addVideoLesson({
    required String courseId,
    required String moduleId,
    required String title,
    required String duration,
    required String videoUrl,
    required String content,
    required bool isStopLesson,
  }) async {
    try {
      // Получаем текущее количество элементов, чтобы задать порядок
      final contentCollection = _firestore.collection('courses').doc(courseId).collection('modules').doc(moduleId).collection('contentItems');
      final currentCount = (await contentCollection.count().get()).count;

      await contentCollection.add({
            'type': 'lesson',
            'title': title,
            'duration': duration,
            'videoUrl': videoUrl,
            'content': content,
            'isStopLesson': isStopLesson,
            'createdAt': Timestamp.now(),
            'orderIndex': currentCount, // <-- Присваиваем порядковый номер
          });
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }

  // --- МЕТОД ДЛЯ ОБНОВЛЕНИЯ УРОКА (КОТОРЫЙ ВЫЗЫВАЕТСЯ) ---
  Future<String?> updateVideoLesson({
    required String courseId,
    required String moduleId,
    required String contentId,
    required String title,
    required String duration,
    required String videoUrl,
    required String content,
    required bool isStopLesson,
  }) async {
    try {
      await _firestore
          .collection('courses').doc(courseId)
          .collection('modules').doc(moduleId)
          .collection('contentItems').doc(contentId)
          .update({
            'title': title,
            'duration': duration,
            'videoUrl': videoUrl,
            'content': content,
            'isStopLesson': isStopLesson,
          });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
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

  /// Обновляет существующий тест и его вопросы
  Future<String?> updateTest({
    required String courseId,
    required String moduleId,
    required String testId,
    required String title,
    required int timeLimitMinutes,
    required int passingPercentage,
    required bool isStopLesson, // <-- ДОБАВИЛИ ПАРАМЕТР
    required List<Question> questions,
  }) async {
    if (title.isEmpty) return 'Название теста не может быть пустым.';

    final testDocRef = _firestore
        .collection('courses').doc(courseId)
        .collection('modules').doc(moduleId)
        .collection('contentItems').doc(testId);

    try {
      await testDocRef.update({
        'title': title,
        'questionCount': questions.length,
        'timeLimitMinutes': timeLimitMinutes,
        'passingPercentage': passingPercentage,
        'isStopLesson': isStopLesson, // <-- ОБНОВЛЯЕМ В БАЗЕ
      });

      final oldQuestions = await testDocRef.collection('questions').get();
      WriteBatch deleteBatch = _firestore.batch();
      for (var doc in oldQuestions.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      WriteBatch addBatch = _firestore.batch();
      for (var question in questions) {
        final questionDocRef = testDocRef.collection('questions').doc();
        addBatch.set(questionDocRef, {
          'questionText': question.questionText,
          'imageUrl': question.imageUrl,
          'options': question.options.map((opt) => {'text': opt.text, 'isCorrect': opt.isCorrect}).toList(),
        });
      }
      await addBatch.commit();

      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<Map<String, String>?> uploadNewsImageAndThumbnail(XFile imageFile) async {
    try {
      print("--- 1. Начинаю загрузку фото для новости...");
      final String fileName = 'news_${DateTime.now().millisecondsSinceEpoch}';
      final Uint8List fileBytes = await imageFile.readAsBytes();
      print("--- 2. Файл прочитан в память.");

      final originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) {
        print("!!! ОШИБКА: Не удалось декодировать изображение.");
        return null;
      }
      print("--- 3. Изображение успешно декодировано.");

      final thumbnail = img.copyResize(originalImage, width: 400);
      print("--- 4. Thumbnail создан.");

      final originalRef = _storage.ref().child('news_images/original/$fileName.jpg');
      print("--- 5. Загружаю оригинал в Storage...");
      await originalRef.putData(img.encodeJpg(originalImage, quality: 85));
      final originalUrl = await originalRef.getDownloadURL();
      print("--- 6. Оригинал успешно загружен.");

      final thumbRef = _storage.ref().child('news_images/thumb/$fileName.jpg');
      print("--- 7. Загружаю thumbnail в Storage...");
      await thumbRef.putData(img.encodeJpg(thumbnail, quality: 75));
      final thumbUrl = await thumbRef.getDownloadURL();
      print("--- 8. Thumbnail успешно загружен. Все готово!");

      return {'imageUrl': originalUrl, 'thumbnailUrl': thumbUrl};
    } catch (e) {
      print("!!! ПРОИЗОШЛА КРИТИЧЕСКАЯ ОШИБКА ВО ВРЕМЯ ЗАГРУЗКИ: $e");
      if (e is FirebaseException) {
        print("!!! КОД ОШИБКИ FIREBASE: ${e.code}");
      }
      return null;
    }
  }
  

  Future<String?> addTest({
    required String courseId,
    required String moduleId,
    required String title,
    required int timeLimitMinutes,
    required int passingPercentage,
    required bool isStopLesson, // <-- ДОБАВИЛИ ПАРАМЕТР
    required List<Question> questions,
  }) async {
    if (title.isEmpty) return 'Название теста не может быть пустым.';
    if (questions.isEmpty) return 'Тест должен содержать хотя бы один вопрос.';

    try {
      final testDocRef = _firestore.collection('courses').doc(courseId).collection('modules').doc(moduleId).collection('contentItems').doc();

      await testDocRef.set({
        'type': 'test',
        'title': title,
        'questionCount': questions.length,
        'timeLimitMinutes': timeLimitMinutes,
        'passingPercentage': passingPercentage,
        'isStopLesson': isStopLesson, // <-- СОХРАНЯЕМ В БАЗУ
        'createdAt': Timestamp.now(),
      });

      WriteBatch batch = _firestore.batch();
      for (var question in questions) {
        final questionDocRef = testDocRef.collection('questions').doc();
        batch.set(questionDocRef, {
          'questionText': question.questionText,
          'imageUrl': question.imageUrl,
          'options': question.options.map((opt) => {'text': opt.text, 'isCorrect': opt.isCorrect}).toList(),
        });
      }
      await batch.commit();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<String?> uploadQuestionImage(XFile imageFile) async {
    try {
      String fileName = 'test_question_images/${DateTime.now().millisecondsSinceEpoch.toString()}';
      Reference ref = _storage.ref().child(fileName);

      Uint8List fileBytes = await imageFile.readAsBytes();
      TaskSnapshot snapshot = await ref.putData(fileBytes);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print("Ошибка при загрузке изображения вопроса: $e");
      return null;
    }
  }
  // lib/view_models/admin_view_model.dart

/// Загружает файл материала в Storage и возвращает ссылку
Future<String?> uploadCourseMaterial(PlatformFile file) async {
  try {
    String fileName = 'course_materials/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    Reference ref = _storage.ref().child(fileName);

    TaskSnapshot snapshot;
    // Для веба мы используем байты файла, для мобильных - путь к файлу (это эффективнее)
    if (kIsWeb) {
      if (file.bytes == null) return null; // Проверка на всякий случай
      snapshot = await ref.putData(file.bytes!);
    } else {
      if (file.path == null) return null; // Проверка на всякий случай
      snapshot = await ref.putFile(File(file.path!));
    }

    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    print("Ошибка при загрузке материала: $e");
    return null;
  }
}

/// Добавляет информацию о материале в Firestore
Future<String?> addMaterial({
  required String courseId,
  required String moduleId,
  required String title,
  required String fileUrl,
  required String fileName,
  required String fileType,
}) async {
  try {
    await _firestore
        .collection('courses').doc(courseId)
        .collection('modules').doc(moduleId)
        .collection('contentItems')
        .add({
          'type': 'material',
          'title': title,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileType': fileType,
          'createdAt': Timestamp.now(),
        });
    return null;
  } on FirebaseException catch (e) {
    return e.message;
  }
}
  Future<String?> updateMaterial({
    required String courseId,
    required String moduleId,
    required String contentId,
    required String title,
    // Для файла передаем PlatformFile, если его меняли
    PlatformFile? newFile,
    // А также URL старого файла, чтобы его удалить
    String? oldFileUrl,
  }) async {
    try {
      String fileUrl = oldFileUrl ?? '';
      String fileName = '';
      String fileType = '';

      // Если был выбран новый файл
      if (newFile != null) {
        // Удаляем старый файл из Storage, если он был
        if (oldFileUrl != null && oldFileUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(oldFileUrl).delete();
          } catch (e) {
            print("Не удалось удалить старый файл (возможно, его нет): $e");
          }
        }
        // Загружаем новый
        fileUrl = await uploadCourseMaterial(newFile) ?? '';
        fileName = newFile.name;
        fileType = newFile.extension ?? '';
      }

      // Обновляем документ в Firestore
      await _firestore
          .collection('courses').doc(courseId)
          .collection('modules').doc(moduleId)
          .collection('contentItems').doc(contentId)
          .update({
            'title': title,
            // Если файл не меняли, эти поля останутся прежними
            if (newFile != null) ...{
              'fileUrl': fileUrl,
              'fileName': fileName,
              'fileType': fileType,
            }
          });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<void> uploadImage(XFile imageFile) async {
    // 1. Проверяем размер файла
    final fileSizeInBytes = await imageFile.length();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    // Ваше ограничение в правилах - 5 МБ
    const maxSizeInMB = 5.0; 

    if (fileSizeInMB > maxSizeInMB) {
      // 2. Если файл слишком большой, показываем ошибку и не начинаем загрузку
      print('Ошибка: Файл слишком большой (${fileSizeInMB.toStringAsFixed(2)} MB). Максимальный размер: $maxSizeInMB MB.');
      // Здесь можно показать SnackBar или диалоговое окно пользователю
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Файл слишком большой! Максимум $maxSizeInMB МБ.')),
      // );
      return; // Прерываем выполнение функции
    }

    // 3. Если проверка пройдена, начинаем загрузку
    print('Размер файла в норме. Начинаю загрузку...');
    // await _adminViewModel.uploadCourseImageAndThumbnail(imageFile);
  }

  Future<String?> deleteContentItem({
    required String courseId,
    required String moduleId,
    required String contentId,
  }) async {
    try {
      await _firestore.collection('courses').doc(courseId).collection('modules').doc(moduleId).collection('contentItems').doc(contentId).delete();
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }

/// Загружает все созданные пробные тесты
Future<List<MockTest>> fetchAllMockTests() async {
  try {
    final snapshot = await _firestore.collection('mock_tests').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => MockTest.fromFirestore(doc)).toList();
  } catch (e) {
    print("Ошибка при загрузке пробных тестов: $e");
    return [];
  }
}


/// Добавляет новый пробный тест и вопросы к нему
 Future<String?> addMockTest({
    required String title, required String subject, required String language,
    required int timeLimitMinutes, required MockTestType testType,
    List<Question>? simpleQuestions, List<UbtSubject>? ubtSubjects,
  }) async {
    try {
      if (testType == MockTestType.simple) {
        if (simpleQuestions == null || simpleQuestions.isEmpty) return 'Тест должен содержать вопросы.';
        final testDocRef = _firestore.collection('mock_tests').doc();
        await testDocRef.set({
          'title': title, 'subject': subject, 'language': language,
          'timeLimitMinutes': timeLimitMinutes, 'testType': 'simple',
          'questionCount': simpleQuestions.length, 'createdAt': Timestamp.now(),
        });
        WriteBatch batch = _firestore.batch();
        for (var q in simpleQuestions) {
          batch.set(testDocRef.collection('questions').doc(), {'questionText': q.questionText, 'imageUrl': q.imageUrl, 'options': q.options.map((opt) => {'text': opt.text, 'isCorrect': opt.isCorrect}).toList()});
        }
        await batch.commit();
      } else {
        if (ubtSubjects == null || ubtSubjects.isEmpty) return 'ҰБТ-тест должен содержать предметы.';
        int totalQuestions = ubtSubjects.fold(0, (sum, s) => sum + s.questions.length);
        final testDocRef = _firestore.collection('mock_tests').doc();
        await testDocRef.set({
          'title': title, 'subject': 'ҰБТ', 'language': language,
          'timeLimitMinutes': timeLimitMinutes, 'testType': 'ubt',
          'questionCount': totalQuestions, 'createdAt': Timestamp.now(),
        });
        for (var sub in ubtSubjects) {
          if (sub.questions.isEmpty) continue;
          final subjectDocRef = testDocRef.collection('subjects').doc();
          await subjectDocRef.set({'title': sub.title});
          WriteBatch batch = _firestore.batch();
          for (var q in sub.questions) {
            batch.set(subjectDocRef.collection('questions').doc(), {'questionText': q.questionText, 'imageUrl': q.imageUrl, 'options': q.options.map((opt) => {'text': opt.text, 'isCorrect': opt.isCorrect}).toList()});
          }
          await batch.commit();
        }
      }
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }

/// Удаляет пробный тест (вместе с вопросами)
  Future<String?> deleteMockTest({required String testId}) async {
    try {
      // В реальном приложении здесь нужна будет Cloud Function для каскадного удаления
      // подколлекции с вопросами. Пока что мы удаляем только основной документ.
      await _firestore.collection('mock_tests').doc(testId).delete();
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<List<Subject>> fetchSubjects() async {
    try {
      final snapshot = await _firestore.collection('subjects').get();
      return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
    } catch (e) { return []; }
  }

  Future<Map<String, String>?> uploadCourseImageAndThumbnail(XFile imageFile) async {
    try {
      print("--- 1. Начинаю загрузку фото для курса...");
      final String fileName = 'course_${DateTime.now().millisecondsSinceEpoch}';
      final Uint8List fileBytes = await imageFile.readAsBytes();
      print("--- 2. Файл прочитан в память.");

      final originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) {
        print("!!! ОШИБКА: Не удалось декодировать изображение.");
        return null;
      }
      print("--- 3. Изображение успешно декодировано.");

      final thumbnail = img.copyResize(originalImage, width: 400);
      print("--- 4. Thumbnail создан.");

      final originalRef = _storage.ref().child('course_images/original/$fileName.jpg');
      print("--- 5. Загружаю оригинал в Storage...");
      await originalRef.putData(img.encodeJpg(originalImage, quality: 85));
      final originalUrl = await originalRef.getDownloadURL();
      print("--- 6. Оригинал успешно загружен.");

      final thumbRef = _storage.ref().child('course_images/thumb/$fileName.jpg');
      print("--- 7. Загружаю thumbnail в Storage...");
      await thumbRef.putData(img.encodeJpg(thumbnail, quality: 75));
      final thumbUrl = await thumbRef.getDownloadURL();
      print("--- 8. Thumbnail успешно загружен. Все готово!");

      return {'imageUrl': originalUrl, 'thumbnailUrl': thumbUrl};
    } catch (e) {
      print("!!! ПРОИЗОШЛА КРИТИЧЕСКАЯ ОШИБКА ВО ВРЕМЯ ЗАГРУЗКИ: $e");
      if (e is FirebaseException) {
        print("!!! КОД ОШИБКИ FIREBASE: ${e.code}");
      }
      return null;
    }
  }

}