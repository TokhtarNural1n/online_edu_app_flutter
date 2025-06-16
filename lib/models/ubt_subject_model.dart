import 'question_model.dart';

// Модель для одного предмета внутри ҰБТ-теста
class UbtSubject {
  String id;
  String title;
  List<Question> questions;

  UbtSubject({
    required this.id,
    required this.title,
    this.questions = const [],
  });
}
