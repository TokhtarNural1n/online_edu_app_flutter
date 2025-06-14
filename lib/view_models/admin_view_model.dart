import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../models/news_model.dart';
import '../models/module_model.dart'; 
import '../models/lesson_model.dart';
import '../models/content_item_model.dart';
import '../models/question_model.dart'; 
import '../models/option_model.dart';


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
      await _firestore.collection('users').doc(userId).collection('enrolled_courses').doc(courseId).set({'enrolledAt': Timestamp.now()});
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

  Future<String?> addNewsArticle({ required String title, required String content, XFile? imageXFile }) async {
    if (title.isEmpty || content.isEmpty) return 'Заголовок и содержание не могут быть пустыми.';
    try {
      String imageUrl = '';
      if (imageXFile != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child('news_images').child(fileName);
        Uint8List fileBytes = await imageXFile.readAsBytes();
        TaskSnapshot snapshot = await ref.putData(fileBytes);
        imageUrl = await snapshot.ref.getDownloadURL();
      }
      await _firestore.collection('news').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'category': 'Общее',
        'viewCount': 0,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  // --- ИСПРАВЛЕННЫЕ МЕТОДЫ РЕДАКТИРОВАНИЯ И УДАЛЕНИЯ ---

  // Метод для обновления новости
  Future<String?> updateNewsArticle({
    required String newsId,
    required String title,
    required String content,
    XFile? newImageFile,
    String? oldImageUrl,
  }) async {
    if (title.isEmpty || content.isEmpty) return 'Поля не могут быть пустыми.';
    try {
      String imageUrl = oldImageUrl ?? '';

      // Если было выбрано новое изображение, загружаем его и удаляем старое
      if (newImageFile != null) {
        // Удаляем старое фото, если оно было
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          await deleteNewsImage(oldImageUrl);
        }
        // Загружаем новое
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child('news_images').child(fileName);
        Uint8List fileBytes = await newImageFile.readAsBytes();
        TaskSnapshot snapshot = await ref.putData(fileBytes);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore.collection('news').doc(newsId).update({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
      });
      return null; // Успех
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  // Вспомогательный метод для удаления изображения из Storage
  Future<void> deleteNewsImage(String imageUrl) async {
    // Не пытаемся удалять заглушки или пустые ссылки
    if (imageUrl.isEmpty || imageUrl.contains('placehold.co')) return;
    try {
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      // Игнорируем ошибку, если файл не найден (возможно, уже удален)
      print("Ошибка при удалении старого фото (можно игнорировать): $e");
    }
  }

  // Метод для удаления всей новости (документ + фото)
  Future<String?> deleteNewsArticle({required String newsId, required String imageUrl}) async {
    try {
      // Сначала удаляем фото из Storage (если оно есть)
      await deleteNewsImage(imageUrl);
      // Затем удаляем документ из Firestore
      await _firestore.collection('news').doc(newsId).delete();
      return null; // Успех
    } on FirebaseException catch (e) {
      return e.message;
    }
  }
  Future<String?> addCourse({
    required String title,
    required String author,
    required String description,
    required String price,
    required String originalPrice,
    XFile? imageXFile,
  }) async {
    if (title.isEmpty || author.isEmpty || description.isEmpty || price.isEmpty) {
      return 'Все поля, кроме старой цены, обязательны.';
    }
    
    try {
      String imageUrl = 'https://placehold.co/600x400/7B1FA2/FFFFFF?text=Course';
      if (imageXFile != null) {
        String fileName = 'course_${DateTime.now().millisecondsSinceEpoch.toString()}';
        Reference ref = _storage.ref().child('course_images').child(fileName);
        Uint8List fileBytes = await imageXFile.readAsBytes();
        TaskSnapshot snapshot = await ref.putData(fileBytes);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore.collection('courses').add({
        'title': title,
        'author': author,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });
      
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  // Метод для обновления курса
  Future<String?> updateCourse({
    required String courseId,
    required String title,
    required String author,
    required String description,
    required String price,
    required String originalPrice,
    XFile? newImageFile,
    String? oldImageUrl,
  }) async {
    if (title.isEmpty || author.isEmpty || description.isEmpty || price.isEmpty) {
      return 'Все поля, кроме старой цены, обязательны.';
    }
    try {
      String imageUrl = oldImageUrl ?? '';
      if (newImageFile != null) {
        if (oldImageUrl != null && oldImageUrl.isNotEmpty && !oldImageUrl.contains('placehold.co')) {
          await _storage.refFromURL(oldImageUrl).delete();
        }
        String fileName = 'course_${DateTime.now().millisecondsSinceEpoch.toString()}';
        Reference ref = _storage.ref().child('course_images').child(fileName);
        Uint8List fileBytes = await newImageFile.readAsBytes();
        TaskSnapshot snapshot = await ref.putData(fileBytes);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      await _firestore.collection('courses').doc(courseId).update({
        'title': title,
        'author': author,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    }
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
  }) async {
    try {
      await _firestore.collection('courses').doc(courseId).collection('modules').doc(moduleId).collection('contentItems').add({
            'type': 'lesson',
            'title': title,
            'duration': duration,
            'videoUrl': videoUrl,
            'content': content,
            'createdAt': Timestamp.now(),
          });
      return null;
    } on FirebaseException catch (e) { return e.message; }
  }

  Future<String?> addTest({
    required String courseId,
    required String moduleId,
    required String title,
    required int timeLimitMinutes, // Новое поле
    required int passingPercentage, // Новое поле
    required List<Question> questions,
  }) async {
    if (title.isEmpty) return 'Название теста не может быть пустым.';
    if (questions.isEmpty) return 'Тест должен содержать хотя бы один вопрос.';

    try {
      final testDocRef = _firestore.collection('courses').doc(courseId).collection('modules').doc(moduleId).collection('contentItems').doc();

      // Сохраняем новые поля
      await testDocRef.set({
        'type': 'test',
        'title': title,
        'questionCount': questions.length,
        'timeLimitMinutes': timeLimitMinutes,
  'passingPercentage': passingPercentage,
        'createdAt': Timestamp.now(),
      });

      WriteBatch batch = _firestore.batch();
      for (var question in questions) {
        final questionDocRef = testDocRef.collection('questions').doc();
        batch.set(questionDocRef, {
          'questionText': question.questionText,
          'imageUrl': question.imageUrl, // Сохраняем URL картинки
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
}
