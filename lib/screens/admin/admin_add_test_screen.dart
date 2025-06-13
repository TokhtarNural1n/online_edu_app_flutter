import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/question_model.dart';
import '../../models/option_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddTestScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const AdminAddTestScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<AdminAddTestScreen> createState() => _AdminAddTestScreenState();
}

class _AdminAddTestScreenState extends State<AdminAddTestScreen> {
  final _testTitleController = TextEditingController();
  final List<Question> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Начинаем с одного пустого вопроса
    _addNewQuestion();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(Question(
        questionText: '',
        // Начинаем с 2-х пустых вариантов ответа
        options: [Option(text: ''), Option(text: '')],
      ));
    });
  }

  void _addOptionToQuestion(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(Option(text: ''));
    });
  }

  void _setCorrectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      // Сначала сбрасываем все ответы для этого вопроса
      for (var option in _questions[questionIndex].options) {
        option.isCorrect = false;
      }
      // Затем устанавливаем правильный
      _questions[questionIndex].options[optionIndex].isCorrect = true;
    });
  }

  void _handleSaveTest() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? error = await adminViewModel.addTest(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      title: _testTitleController.text,
      questions: _questions,
    );

    if (mounted) {
      setState(() { _isLoading = false; });
      if (error == null) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать новый тест'),
        actions: [
          IconButton(onPressed: _handleSaveTest, icon: const Icon(Icons.save))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _questions.length + 2, // +2 для заголовка и кнопки
              itemBuilder: (context, index) {
                if (index == 0) {
                  return TextField(
                    controller: _testTitleController,
                    decoration: const InputDecoration(labelText: 'Название теста'),
                  );
                }
                if (index == _questions.length + 1) {
                  return OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить вопрос'),
                    onPressed: _addNewQuestion,
                  );
                }
                final questionIndex = index - 1;
                return _buildQuestionCard(questionIndex);
              },
            ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вопрос №${questionIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: question.questionText,
              decoration: const InputDecoration(labelText: 'Текст вопроса'),
              onChanged: (text) => question.questionText = text,
            ),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (optionIndex) {
              final option = question.options[optionIndex];
              return Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: option.isCorrect,
                    onChanged: (value) => _setCorrectAnswer(questionIndex, optionIndex),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: option.text,
                      decoration: InputDecoration(labelText: 'Вариант ${optionIndex + 1}'),
                      onChanged: (text) => option.text = text,
                    ),
                  ),
                ],
              );
            }),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить вариант'),
              onPressed: () => _addOptionToQuestion(questionIndex),
            ),
          ],
        ),
      ),
    );
  }
}
