// lib/screens/admin/admin_add_test_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/content_item_model.dart';
import '../../models/question_model.dart';
import '../../models/option_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddTestScreen extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final ContentItem? testToEdit;

  const AdminAddTestScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    this.testToEdit,
  });

  @override
  State<AdminAddTestScreen> createState() => _AdminAddTestScreenState();
}

class _AdminAddTestScreenState extends State<AdminAddTestScreen> {
  final _testTitleController = TextEditingController();
  final _timeLimitController = TextEditingController();
  final _passingPercentageController = TextEditingController();
  
  List<Question> _questions = [];
  bool _isLoading = false;
  bool _isStopTest = false; // <-- НОВОЕ ПОЛЕ СОСТОЯНИЯ
  bool get isEditing => widget.testToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final test = widget.testToEdit!;
      _testTitleController.text = test.title;
      _timeLimitController.text = (test.timeLimitMinutes ?? 60).toString();
      _passingPercentageController.text = (test.passingPercentage ?? 50).toString();
      _isStopTest = test.isStopLesson; // <-- ЗАПОЛНЯЕМ СОСТОЯНИЕ
      _loadQuestionsForEdit();
    } else {
      _addNewQuestion();
    }
  }

  void _loadQuestionsForEdit() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    final questions = await adminViewModel.fetchTestQuestions(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      testId: widget.testToEdit!.id,
    );
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(Question(
        questionText: '',
        options: [Option(text: ''), Option(text: '')],
      ));
    });
  }
  
  // (Методы _pickImage, _addOptionToQuestion, _setCorrectAnswer остаются без изменений)
    Future<void> _pickImage(int questionIndex) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Загрузка изображения...')));

      final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
      final imageUrl = await adminViewModel.uploadQuestionImage(pickedFile);
      
      messenger.hideCurrentSnackBar();

      if (imageUrl != null) {
        setState(() {
          _questions[questionIndex].imageUrl = imageUrl;
        });
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('Не удалось загрузить изображение.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _addOptionToQuestion(int questionIndex) {
    setState(() {
      _questions[questionIndex].options.add(Option(text: ''));
    });
  }

  void _setCorrectAnswer(int questionIndex, int optionIndex) {
    setState(() {
      for (var option in _questions[questionIndex].options) {
        option.isCorrect = false;
      }
      _questions[questionIndex].options[optionIndex].isCorrect = true;
    });
  }

  void _handleSaveTest() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    String? error;
    if (isEditing) {
      error = await adminViewModel.updateTest(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        testId: widget.testToEdit!.id,
        title: _testTitleController.text,
        timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 60,
        passingPercentage: int.tryParse(_passingPercentageController.text) ?? 50,
        questions: _questions,
        isStopLesson: _isStopTest, // <-- ПЕРЕДАЕМ ЗНАЧЕНИЕ
      );
    } else {
      error = await adminViewModel.addTest(
        courseId: widget.courseId,
        moduleId: widget.moduleId,
        title: _testTitleController.text,
        timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 60,
        passingPercentage: int.tryParse(_passingPercentageController.text) ?? 50,
        questions: _questions,
        isStopLesson: _isStopTest, // <-- ПЕРЕДАЕМ ЗНАЧЕНИЕ
      );
    }

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
        title: Text(isEditing ? 'Редактировать тест' : 'Создать новый тест'),
        actions: [
          IconButton(onPressed: _isLoading ? null : _handleSaveTest, icon: const Icon(Icons.save))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _questions.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _buildTestSettings();
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

  Widget _buildTestSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _testTitleController, decoration: const InputDecoration(labelText: 'Название теста')),
            const SizedBox(height: 16),
            TextField(controller: _timeLimitController, decoration: const InputDecoration(labelText: 'Лимит времени (в минутах)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: _passingPercentageController, decoration: const InputDecoration(labelText: 'Проходной балл (%)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            // --- НОВЫЙ ПЕРЕКЛЮЧАТЕЛЬ ДЛЯ ТЕСТА ---
            SwitchListTile(
              title: const Text('Стоп-тест'),
              subtitle: const Text('Следующий урок не откроется, пока тест не будет сдан.'),
              value: _isStopTest,
              onChanged: (bool value) {
                setState(() {
                  _isStopTest = value;
                });
              },
            ),
          ],
        ),
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
              key: ValueKey(question.id ?? questionIndex),
              initialValue: question.questionText,
              decoration: const InputDecoration(labelText: 'Текст вопроса'),
              onChanged: (text) => question.questionText = text,
            ),
            const SizedBox(height: 16),
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Image.network(question.imageUrl!, height: 150),
              ),
            TextButton.icon(onPressed: () => _pickImage(questionIndex), icon: const Icon(Icons.image), label: Text(question.imageUrl == null ? 'Добавить картинку' : 'Изменить картинку')),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (optionIndex) {
              final option = question.options[optionIndex];
              return Row(
                children: [
                  Radio<int>(
                    value: optionIndex,
                    groupValue: option.isCorrect ? optionIndex : null,
                    onChanged: (value) => _setCorrectAnswer(questionIndex, optionIndex),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey(question.options[optionIndex]),
                      initialValue: option.text,
                      decoration: InputDecoration(labelText: 'Вариант ${optionIndex + 1}'),
                      onChanged: (text) => option.text = text,
                    ),
                  ),
                ],
              );
            }),
            TextButton.icon(icon: const Icon(Icons.add, size: 16), label: const Text('Добавить вариант'), onPressed: () => _addOptionToQuestion(questionIndex)),
          ],
        ),
      ),
    );
  }
}