import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String surname;
  final String role; // Наше новое поле

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.surname,
    required this.role,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      role: data['role'] ?? 'user', // По умолчанию роль 'user'
    );
  }
}