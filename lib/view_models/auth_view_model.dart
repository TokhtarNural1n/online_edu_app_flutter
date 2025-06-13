import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthViewModel() {
    // Слушаем глобальные изменения состояния входа/выхода
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _currentUser = user;
    notifyListeners(); // Уведомляем всех, когда пользователь входит или выходит
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String surname,
  }) async {
    if (name.isEmpty || surname.isEmpty) {
      return "Имя и фамилия не могут быть пустыми.";
    }
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name.trim(),
          'surname': surname.trim(),
          'email': email.trim(),
          'uid': user.uid,
          'createdAt': Timestamp.now(),
          'role': 'user', // <-- 2. ПРИСВАИВАЕМ РОЛЬ ПО УМОЛЧАНИЮ
        });
        
        await user.updateDisplayName('${name.trim()} ${surname.trim()}');
        await user.reload();
        _currentUser = _auth.currentUser;
        notifyListeners();
        return null;
      }
      return "Не удалось создать пользователя.";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Обновляем getUserData, чтобы он возвращал UserModel
  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      return UserModel.fromFirestore(docSnap);
    } else {
      // Логика "ленивого" создания профиля
      try {
        // --- ИЗМЕНИТЕ ТОЛЬКО ЭТУ СТРОКУ ---
        final Map<String, dynamic> newUserData = { // <-- Явно указываем тип Map<String, dynamic>
          'email': user.email ?? '',
          'uid': user.uid,
          'createdAt': Timestamp.now(),
          'name': '', 
          'surname': '',
          'role': 'user',
        };
        // ------------------------------------
        
        await docRef.set(newUserData);
        final newDocSnap = await docRef.get();
        return UserModel.fromFirestore(newDocSnap);
      } catch (e) {
        print("Ошибка при создании документа пользователя: $e");
        return null;
      }
    }
  }

  Future<String?> updateUserData({
    required String name,
    required String surname,
  }) async {
    if (_currentUser == null) return "Пользователь не найден.";
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'name': name.trim(),
        'surname': surname.trim(),
      }, SetOptions(merge: true));

      await _currentUser!.updateDisplayName('${name.trim()} ${surname.trim()}');
      
      // --- ВАЖНОЕ ИЗМЕНЕНИЕ ---
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;
      notifyListeners(); // Уведомляем UI
      // -----------------------

      return null; // Успех
    } on FirebaseException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return 'Если аккаунт с таким email существует, на него отправлена ссылка для сброса пароля.';
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }



  // --- ВОТ НЕДОСТАЮЩИЙ МЕТОД ---
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return "Сначала вам нужно войти в систему.";
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: _currentUser!.email!,
      password: currentPassword,
    );

    try {
      await _currentUser!.reauthenticateWithCredential(credential);
      await _currentUser!.updatePassword(newPassword);
      return null; // Успех
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        return 'Неверный текущий пароль.';
      }
      return 'Произошла ошибка: ${e.message}';
    }
  }
}