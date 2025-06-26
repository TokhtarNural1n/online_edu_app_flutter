// lib/view_models/news_view_model.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';
import '../models/comment_model.dart';

class NewsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<NewsArticle>> fetchNewsPaginated({int limit = 15, DocumentSnapshot? lastVisible}) async {
    try {
      // Начинаем строить запрос
      Query query = _firestore
          .collection('news')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Если это не первая страница, начинаем загрузку после последнего виденного документа
      if (lastVisible != null) {
        query = query.startAfterDocument(lastVisible);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при пагинации новостей: $e");
      return [];
    }
  }

  Future<void> incrementViewCount(String newsId) async {
    try {
      await _firestore.collection('news').doc(newsId).update({'viewCount': FieldValue.increment(1)});
    } catch (e) {
      print("Ошибка при увеличении счетчика просмотров: $e");
    }
  }

  // --- ОПТИМИЗИРОВАННЫЙ МЕТОД ДЛЯ ЛАЙКОВ ---
  // Одним запросом получает ID всех комментариев, которые лайкнул пользователь
  Future<Set<String>> fetchLikedCommentIds(String newsId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};
    try {
      // Ищем все документы в подколлекциях 'likes', где 'userId' равен нашему
      final snapshot = await _firestore
          .collectionGroup('likes')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return {};
      
      // Фильтруем лайки, чтобы они относились только к текущей новости
      return snapshot.docs
        .where((doc) => doc.reference.path.contains(newsId))
        .map((doc) => doc.reference.parent.parent!.id) // Получаем ID комментария
        .toSet();
    } catch (e) {
      print("Ошибка при загрузке лайкнутых комментариев: $e");
      return {};
    }
  }
  
  // --- ОБЫЧНЫЙ МЕТОД ЗАГРУЗКИ КОММЕНТАРИЕВ ---
  Future<List<Comment>> fetchComments(String newsId) async {
    try {
      final snapshot = await _firestore
          .collection('news').doc(newsId)
          .collection('comments').orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
    } catch (e) {
      print("Ошибка при загрузке комментариев: $e");
      return [];
    }
  }

  Future<void> toggleCommentLike(String newsId, String commentId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final commentRef = _firestore.collection('news').doc(newsId).collection('comments').doc(commentId);
    final likeRef = commentRef.collection('likes').doc(userId);
    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
      await commentRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({'userId': userId});
      await commentRef.update({'likeCount': FieldValue.increment(1)});
    }
  }
  Future<List<NewsArticle>> fetchLatestNews({int limit = 5}) async {
  try {
    final snapshot = await _firestore
        .collection('news')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => NewsArticle.fromFirestore(doc)).toList();
  } catch (e) {
    print("Ошибка при загрузке последних новостей: $e");
    return [];
  }
}

  Future<void> addComment(String newsId, String commentText, {String? parentId, String? parentUserName}) async {
    final user = _auth.currentUser;
    if (user == null || commentText.trim().isEmpty) return;
    
    final newsRef = _firestore.collection('news').doc(newsId);
    final commentRef = newsRef.collection('comments').doc();
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['name'] ?? 'Аноним';

    return _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, {
        'userId': user.uid,
        'userName': userName,
        'commentText': commentText,
        'createdAt': Timestamp.now(),
        'likeCount': 0,
        'parentId': parentId,
        'parentUserName': parentUserName,
      });
      transaction.update(newsRef, {'commentCount': FieldValue.increment(1)});
    });
  }
}