class Option {
  // Не final, так как мы будем изменять их в редакторе
  String text;
  bool isCorrect;

  Option({required this.text, this.isCorrect = false});
}
