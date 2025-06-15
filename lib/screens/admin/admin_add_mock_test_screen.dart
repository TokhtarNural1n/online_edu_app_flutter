// lib/screens/admin/admin_add_mock_test_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/question_model.dart';
import '../../models/option_model.dart';
import '../../view_models/admin_view_model.dart';

class AdminAddMockTestScreen extends StatefulWidget {
  const AdminAddMockTestScreen({super.key});

  @override
  State<AdminAddMockTestScreen> createState() => _AdminAddMockTestScreenState();
}

class _AdminAddMockTestScreenState extends State<AdminAddMockTestScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _languageController = TextEditingController(text: 'RU');
  final _timeLimitController = TextEditingController(text: '60');
  final List<Question> _questions = [];
  final Map<int, XFile?> _questionImages = {}; // Для хранения выбранных изображений
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(Question(
        questionText: '',
        options: [Option(text: ''), Option(text: '')],
      ));
    });
  }

  void _addOptionToQuestion(int questionIndex) {
    setState(() {
      if (_questions[questionIndex].options.length < 6) { // Ограничение на 6 вариантов
        _questions[questionIndex].options.add(Option(text: ''));
      }
    });
  }

  void _removeOptionFromQuestion(int questionIndex, int optionIndex) {
    setState(() {
      if (_questions[questionIndex].options.length > 2) { // Оставляем минимум 2 варианта
        _questions[questionIndex].options.removeAt(optionIndex);
      }
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

  Future<void> _pickImage(int questionIndex) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _questionImages[questionIndex] = pickedFile;
      });
    }
  }

  void _handleSaveTest() async {
    setState(() { _isLoading = true; });
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);

    // Сначала загружаем все картинки и получаем их URL
    for (int i = 0; i < _questions.length; i++) {
      if (_questionImages.containsKey(i)) {
        final imageUrl = await adminViewModel.uploadQuestionImage(_questionImages[i]!);
        _questions[i].imageUrl = imageUrl;
      }
    }

    String? error = await adminViewModel.addMockTest(
      title: _titleController.text,
      subject: _subjectController.text,
      language: _languageController.text,
      timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 60, // <-- ПЕРЕДАЕМ ЛИМИТ
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
        title: const Text('Создать пробный тест'),
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
                if (index == 0) return _buildTestInfoFields();
                if (index == _questions.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить вопрос'),
                      onPressed: _addNewQuestion,
                    ),
                  );
                }
                final questionIndex = index - 1;
                return _buildQuestionCard(questionIndex);
              },
            ),
    );
  }

  Widget _buildTestInfoFields() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название теста')),
            const SizedBox(height: 16),
            TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Предмет')),
            const SizedBox(height: 16),
            TextField(controller: _languageController, decoration: const InputDecoration(labelText: 'Язык (напр. KK или RU)')),
            const SizedBox(height: 16),
            // <-- НОВОЕ ПОЛЕ ДЛЯ ВВОДА ВРЕМЕНИ -->
            TextField(
              controller: _timeLimitController,
              decoration: const InputDecoration(labelText: 'Лимит времени (в минутах)'),
              keyboardType: TextInputType.number,
            ),
          ]
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final imageFile = _questionImages[questionIndex];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вопрос №${questionIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (imageFile != null)
              Center(
                child: kIsWeb
                    ? Image.network(imageFile.path, height: 150)
                    : Image.file(File(imageFile.path), height: 150),
              ),
            TextButton.icon(
              onPressed: () => _pickImage(questionIndex),
              icon: const Icon(Icons.image_outlined, size: 18),
              label: Text(imageFile == null ? 'Добавить картинку' : 'Изменить картинку'),
            ),
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
                  Radio<int>(
                    value: optionIndex,
                    groupValue: question.options.indexWhere((opt) => opt.isCorrect),
                    onChanged: (value) => _setCorrectAnswer(questionIndex, optionIndex),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: option.text,
                      decoration: InputDecoration(labelText: 'Вариант ${optionIndex + 1}'),
                      onChanged: (text) => option.text = text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _removeOptionFromQuestion(questionIndex, optionIndex),
                  )
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