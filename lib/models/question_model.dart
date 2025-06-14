// lib/models/question_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'option_model.dart';

class Question {
  final String? id;
  String questionText;
  String? imageUrl; // <-- НОВОЕ ПОЛЕ ДЛЯ КАРТИНКИ
  List<Option> options;

  Question({
    this.id,
    required this.questionText,
    this.imageUrl, // <-- ДОБАВЛЯЕМ В КОНСТРУКТОР
    required this.options,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var optionsFromDb = data['options'] as List<dynamic>? ?? [];
    List<Option> optionsList = optionsFromDb.map((optionData) {
      return Option.fromMap(optionData as Map<String, dynamic>);
    }).toList();

    return Question(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      imageUrl: data['imageUrl'], // <-- ПОЛУЧАЕМ КАРТИНКУ ИЗ FIREBASE
      options: optionsList,
    );
  }
}