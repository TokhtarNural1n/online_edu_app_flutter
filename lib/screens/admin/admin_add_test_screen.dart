import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final _timeLimitController = TextEditingController();
  final _passingPercentageController = TextEditingController();
  final List<Question> _questions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addNewQuestion();
  }

  void _addNewQuestion() {
    setState(() {
      _questions.add(Question(
        questionText: '',
        options: [Option(text: ''), Option(text: '')],
      ));
    });
  }

  // Метод для выбора изображения
  Future<void> _pickImage(int questionIndex) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Загрузка изображения...')));

      // Вызываем метод для загрузки файла в облако
      final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
      final imageUrl = await adminViewModel.uploadQuestionImage(pickedFile);
      
      messenger.hideCurrentSnackBar();

      if (imageUrl != null) {
        // Если ссылка получена, сохраняем ее в состояние
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

    String? error = await adminViewModel.addTest(
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      title: _testTitleController.text,
      timeLimitMinutes: int.tryParse(_timeLimitController.text) ?? 60,
      passingPercentage: int.tryParse(_passingPercentageController.text) ?? 50,
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
          IconButton(onPressed: _isLoading ? null : _handleSaveTest, icon: const Icon(Icons.save))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _questions.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildTestSettings();
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

  Widget _buildTestSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _testTitleController,
              decoration: const InputDecoration(labelText: 'Название теста'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeLimitController,
              decoration: const InputDecoration(labelText: 'Лимит времени (в минутах)'),
              keyboardType: TextInputType.number,
            ),
             const SizedBox(height: 16),
            TextField(
              controller: _passingPercentageController,
              decoration: const InputDecoration(labelText: 'Проходной балл (%)'),
              keyboardType: TextInputType.number,
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
              initialValue: question.questionText,
              decoration: const InputDecoration(labelText: 'Текст вопроса'),
              onChanged: (text) => question.questionText = text,
            ),
            const SizedBox(height: 16),

            // Отображение и кнопка для изображения
            if (question.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Теперь всегда используем Image.network, т.к. у нас будет URL
                child: Image.network(question.imageUrl!, height: 150),
              ),
            TextButton.icon(
              onPressed: () => _pickImage(questionIndex), 
              icon: const Icon(Icons.image), 
              label: Text(question.imageUrl == null ? 'Добавить картинку' : 'Изменить картинку')
            ),

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