// lib/models/option_model.dart
class Option {
  String text;
  bool isCorrect;

  Option({required this.text, this.isCorrect = false});

  // Этот метод позволит нам создавать объект из данных Firebase
  factory Option.fromMap(Map<String, dynamic> map) {
    return Option(
      text: map['text'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
    );
  }
}