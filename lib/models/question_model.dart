import 'option_model.dart';

class Question {
  // Не final, так как мы будем изменять их в редакторе
  String questionText;
  List<Option> options;

  Question({required this.questionText, required this.options});
}
